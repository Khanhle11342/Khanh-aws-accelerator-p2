# Week 10 Lab - ESO + Trivy + Cosign

Deliverable cho Lab 2:

```text
eso/                    # SecretStore + ExternalSecret
signing/                # ghi chu Cosign keyless, khong commit private key
.github/workflows/      # CI: Trivy + Cosign
argocd/apps/*.yaml      # App ESO + policy-controller + policies
policies/               # ClusterImagePolicy + label namespace demo
runbooks/               # 2 runbook + 1 exception ADR
```

## Tu kiem

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

