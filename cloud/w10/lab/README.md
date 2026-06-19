# Week 10 Lab - GitOps Security

Deliverable cho Lab 1 + Lab 2:

```text
rbac/                   # 3 role/clusterrole + 3 binding
gatekeeper/constraints/ # 4 constraint + custom template
eso/                    # SecretStore + ExternalSecret
signing/                # ghi chu Cosign keyless, khong commit private key
.github/workflows/      # CI: Trivy + Cosign
argocd/apps/*.yaml      # App rbac, gatekeeper, eso, policy-controller, policies
policies/               # ClusterImagePolicy + label namespace demo
runbooks/               # self-check runbooks + exception ADR
```

## Tu kiem

### Lab 1 - RBAC

```bash
kubectl auth can-i create deploy -n demo --as alice
kubectl auth can-i create deploy -n kube-system --as alice
kubectl auth can-i get pods -A --as bob
kubectl auth can-i delete nodes --as carol
```

Ky vong:

- `alice` create deploy trong `demo`: `yes`
- `alice` create deploy trong `kube-system`: `no`
- `bob` get pods toan cum: `yes`
- `carol` delete nodes: `no`

### Lab 1 - Gatekeeper

```bash
kubectl get applications.argoproj.io -n argocd gatekeeper gatekeeper-constraints
kubectl get constrainttemplates
kubectl get constraints
```

Ky vong:

- 4 manifest vi pham bi reject.
- Pod hop le pass.
- Platform W9 van `Synced/Healthy` sau khi bat enforce.

### Lab 2 - ESO + Trivy + Cosign

```bash
kubectl get applications.argoproj.io -n argocd
kubectl get ns demo --show-labels
kubectl get externalsecret -n demo
kubectl get clusterimagepolicy require-signed-web-image
```

Ky vong:

- ESO sync secret trong duoi 60s, pod app khong restart.
- CI fail neu image co CVE `HIGH`/`CRITICAL`.
- Image chua ky bi admission reject tren namespace `demo`.
- Image da ky tu workflow CI pass admission.
- Repo khong co secret that:

```bash
git log -p | grep -i password
git grep -n -E 'ghp_|github_pat_|AWS_SECRET_ACCESS_KEY|aws_secret_access_key'
```

## Luu y ve signing

Repo nay dung Cosign keyless voi GitHub Actions OIDC:

- Khong tao private key.
- Khong commit private key.
- `ClusterImagePolicy` verify identity cua workflow thay vi verify bang `cosign.pub`.
