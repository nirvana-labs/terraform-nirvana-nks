# Integration tests

Terratest-based integration tests that provision a real NKS cluster against your Nirvana Labs project, run assertions against the live Kubernetes API, and tear the cluster down. These tests cost real money and time (~20 min per scenario) — they're meant to be run on-demand or as a pre-release gate, not on every PR.

## Prerequisites

- Go 1.25+
- `terraform` ≥ 1.5 on `PATH`
- `kubectl` on `PATH`
- A Nirvana Labs API key and a sandbox project ID

## Running

The test uses the same env vars as a manual `terraform apply` — populate them from `.env.example` at the repo root, then:

```bash
set -a; source ../.env; set +a   # NIRVANA_LABS_API_KEY, TF_VAR_project_id
cd test
go test -v -timeout 30m
```

A full run: provisions the cluster (~3–5 min), waits ~10 min for the control plane, fetches the kubeconfig, asserts node readiness + kubelet version + smoke-pod scheduling, then destroys the cluster. Allow ~20 min wall-clock per scenario.

## Scenarios

- `basic_test.go` — provisions [`examples/basic`](../examples/basic), asserts ≥ 2 nodes Ready, kubelet at the configured Kubernetes minor version, and a busybox pod scheduling and reaching `Running`.

Additional scenarios (multi-pool, labeled-pools, existing-vpc) will follow the same pattern: one `Test*` function per example, with `defer terraform.Destroy` guaranteeing teardown even if assertions fail.

## Cost and cleanup

Destroy is deferred at the top of each test, so a panic still tears infrastructure down. If a run is killed forcibly (Ctrl-C, OOM), the cluster may be stranded — verify with `terraform state list` in the example directory and run `terraform destroy` manually.

Parallel test runs against the same Nirvana project will fight over the one-cluster-per-VPC constraint; run scenarios sequentially.
