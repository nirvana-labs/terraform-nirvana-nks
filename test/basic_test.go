// Package test contains Terratest integration tests for the
// terraform-nirvana-nks module. Each test provisions a real NKS cluster,
// runs assertions against the live K8s API, and tears it down. Tests are
// gated on the same env vars as a normal terraform apply — see .env.example
// at the repo root (NIRVANA_LABS_API_KEY, TF_VAR_project_id).
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
	corev1 "k8s.io/api/core/v1"
)

const (
	// Single source of truth for the K8s version under test. Passed to
	// examples/basic via opts.Vars and used to derive the expected kubelet
	// prefix in the version assertion below — so the test and example
	// can't drift.
	testK8sVersion = "v1.34.4"

	// NKS control planes typically reach the kubeconfig-fetchable state
	// in ~10 min. Sleep for a head start, then retry the second apply
	// until the data source succeeds.
	controlPlaneHeadStart = 5 * time.Minute
	fetchKubeconfigTries  = 20
	fetchKubeconfigDelay  = 30 * time.Second

	expectedMinNodeCount = 2
	nodeReadyTries       = 30
	nodeReadyDelay       = 10 * time.Second

	smokePodName    = "smoketest"
	smokePodImage   = "busybox"
	smokePodTries   = 24
	smokePodDelay   = 5 * time.Second
	smokePodTimeout = "60"
)

// TestBasicCluster provisions examples/basic, fetches the kubeconfig,
// and asserts the cluster is reachable, nodes are Ready at the expected
// Kubernetes version, and a smoke pod schedules and runs.
func TestBasicCluster(t *testing.T) {
	// Env vars are the same as a manual `terraform apply` — see .env.example.
	// TF_VAR_project_id is inherited by the terraform subprocess; we only
	// check it here so the test fails fast with a helpful message if unset.
	require.NotEmpty(t, os.Getenv("NIRVANA_LABS_API_KEY"), "NIRVANA_LABS_API_KEY must be set (see .env.example)")
	require.NotEmpty(t, os.Getenv("TF_VAR_project_id"), "TF_VAR_project_id must be set (see .env.example)")

	opts := &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"kubernetes_version": testK8sVersion,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, opts)

	t.Log("Phase 1: provisioning cluster")
	terraform.InitAndApply(t, opts)

	t.Logf("Sleeping %s while control plane initializes", controlPlaneHeadStart)
	time.Sleep(controlPlaneHeadStart)

	t.Log("Phase 2: fetching kubeconfig (retry until the data source succeeds)")
	opts.Vars["fetch_kubeconfig"] = true
	phaseStart := time.Now()
	attempt := 0
	retry.DoWithRetry(t, "fetch kubeconfig", fetchKubeconfigTries, fetchKubeconfigDelay, func() (string, error) {
		attempt++
		t.Logf("  attempt %d/%d (elapsed %s)", attempt, fetchKubeconfigTries, time.Since(phaseStart).Round(time.Second))
		if _, err := terraform.ApplyE(t, opts); err != nil {
			return "", fmt.Errorf("apply failed (control plane likely not ready): %s", firstLine(err.Error()))
		}
		return "kubeconfig fetched", nil
	})

	kubeconfigPath := terraform.Output(t, opts, "kubeconfig_path")
	require.NotEmpty(t, kubeconfigPath, "kubeconfig_path output should be set after phase 2")

	k8sOpts := k8s.NewKubectlOptions("", kubeconfigPath, "default")

	t.Log("Waiting for nodes to be Ready")
	retry.DoWithRetry(t, "nodes Ready", nodeReadyTries, nodeReadyDelay, func() (string, error) {
		nodes, err := k8s.GetNodesE(t, k8sOpts)
		if err != nil {
			return "", err
		}
		if len(nodes) < expectedMinNodeCount {
			return "", fmt.Errorf("expected >=%d nodes, got %d", expectedMinNodeCount, len(nodes))
		}
		for _, n := range nodes {
			if !isNodeReady(n) {
				return "", fmt.Errorf("node %s not Ready", n.Name)
			}
		}
		return fmt.Sprintf("%d nodes Ready", len(nodes)), nil
	})

	t.Log("Asserting kubelet version matches the configured kubernetes_version")
	expectedPrefix := minorVersionPrefix(testK8sVersion)
	for _, n := range k8s.GetNodes(t, k8sOpts) {
		kubelet := n.Status.NodeInfo.KubeletVersion
		require.True(t,
			strings.HasPrefix(kubelet, expectedPrefix),
			"node %s reports kubelet %s; expected prefix %s", n.Name, kubelet, expectedPrefix)
	}

	t.Log("Smoke test: scheduling a pod")
	k8s.RunKubectl(t, k8sOpts, "run", smokePodName,
		"--image="+smokePodImage,
		"--restart=Never",
		"--", "sleep", smokePodTimeout)
	defer k8s.RunKubectl(t, k8sOpts, "delete", "pod", smokePodName, "--ignore-not-found")

	retry.DoWithRetry(t, "smoke pod Running", smokePodTries, smokePodDelay, func() (string, error) {
		phase, err := k8s.RunKubectlAndGetOutputE(t, k8sOpts,
			"get", "pod", smokePodName, "-o", "jsonpath={.status.phase}")
		if err != nil {
			return "", err
		}
		if phase != "Running" && phase != "Succeeded" {
			return "", fmt.Errorf("pod phase=%s", phase)
		}
		return phase, nil
	})

	t.Log("PASS")
}

func isNodeReady(n corev1.Node) bool {
	for _, c := range n.Status.Conditions {
		if c.Type == corev1.NodeReady {
			return c.Status == corev1.ConditionTrue
		}
	}
	return false
}

// minorVersionPrefix returns "vMAJOR.MINOR." for an input like "v1.34.4",
// suitable for matching against a kubelet version string with HasPrefix.
// The trailing dot prevents a false match between e.g. "v1.34" and a
// hypothetical future "v1.340.x".
func minorVersionPrefix(v string) string {
	parts := strings.SplitN(v, ".", 3)
	if len(parts) < 2 {
		return v
	}
	return strings.Join(parts[:2], ".") + "."
}

// firstLine returns the first non-empty line of s, truncated to 200 chars.
// Used to keep multi-line terraform errors readable in the retry log.
func firstLine(s string) string {
	for _, line := range strings.Split(s, "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		if len(trimmed) > 200 {
			return trimmed[:200] + "..."
		}
		return trimmed
	}
	return ""
}
