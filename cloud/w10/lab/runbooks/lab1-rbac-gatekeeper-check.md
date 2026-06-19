# Runbook: Lab 1 RBAC + Gatekeeper self-check

## RBAC

```bash
kubectl auth can-i create deploy -n demo --as alice
kubectl auth can-i create deploy -n kube-system --as alice
kubectl auth can-i get pods -A --as bob
kubectl auth can-i delete nodes --as carol
```

Expected:

```text
yes
no
yes
no
```

## Gatekeeper

Kiem tra app va constraint:

```bash
kubectl get applications.argoproj.io -n argocd gatekeeper gatekeeper-constraints
kubectl get constrainttemplates
kubectl get constraints
```

Expected:

- `gatekeeper` va `gatekeeper-constraints` la `Synced/Healthy`.
- Constraint reject image `:latest`.
- Constraint reject workload thieu `resources.limits`.
- Constraint reject pod chay root `runAsUser: 0`.
- Constraint reject `hostNetwork: true`.
- Manifest hop le co pinned image, limits, non-root thi pass.

