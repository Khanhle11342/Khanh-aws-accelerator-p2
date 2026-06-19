# Evidence - Lab 1 + Lab 2

Ngay kiem: 2026-06-19

Repo: `Khanhle11342/Khanh-aws-accelerator-p2`

## Lab 1 - RBAC

Lenh kiem:

```bash
kubectl auth can-i create deploy -n demo --as alice
kubectl auth can-i create deploy -n kube-system --as alice
kubectl auth can-i get pods -A --as bob
kubectl auth can-i delete nodes --as carol
```

Ket qua:

```text
yes
no
yes
no
```

Dat yeu cau:

- `alice` chi duoc CRUD workload trong namespace `demo`.
- `alice` khong duoc tao deploy trong `kube-system`.
- `bob` doc/thao tac pod toan cum theo role SRE.
- `carol` viewer khong duoc delete node.

File lien quan:

```text
rbac/roles.yaml
rbac/rolebindings.yaml
argocd/apps/rbac.yaml
```

## Lab 1 - Gatekeeper

Lenh kiem app:

```bash
kubectl get applications.argoproj.io -n argocd gatekeeper gatekeeper-constraints
kubectl get constrainttemplates
kubectl get constraints
```

Trang thai ArgoCD da kiem:

```text
gatekeeper               Synced   Healthy
gatekeeper-constraints   Synced   Healthy
```

Policy enforce:

- Reject image tag `:latest`.
- Reject workload thieu `resources.limits`.
- Reject pod chay root `runAsUser: 0`.
- Reject pod co `hostNetwork: true`.
- Manifest hop le voi pinned image, limits, non-root thi pass.

File lien quan:

```text
gatekeeper/constraints/constrainttemplates.yaml
gatekeeper/constraints/constraints.yaml
argocd/apps/gatekeeper.yaml
argocd/apps/gatekeeper-constraints.yaml
```

## Lab 2.1 - ESO

Lenh kiem:

```bash
kubectl get applications.argoproj.io -n argocd eso eso-config
kubectl get externalsecret -n demo api-db-credentials
kubectl get secret -n demo api-db-credentials -o jsonpath='{.data.db_pass}' | base64 -d
kubectl get pod -n demo -l app=api -o wide
```

Ket qua da kiem:

```text
eso          Synced   Healthy
eso-config   Synced   Healthy

api-db-credentials   SecretStore   eso-k8s-store   15s   SecretSynced   True
```

Evidence rotate:

- Source secret `eso-source-db` doi tu `lab2-rotated-002` sang `lab2-rotated-003`.
- Target secret `api-db-credentials` cap nhat theo trong khoang refresh interval.
- Pod `api` khong restart, UID/AGE khong doi.
- Secret duoc mount qua volume, khong doc bang env nen app nhan file moi ma khong can restart pod.

File lien quan:

```text
eso/secret-store.yaml
eso/external-secret.yaml
argocd/apps/eso.yaml
argocd/apps/eso-config.yaml
```

## Lab 2.2 - Trivy + Cosign + Admission

CI/CD:

- Trivy scan image voi `severity: HIGH,CRITICAL`.
- Pipeline fail neu Trivy thay CVE muc `HIGH/CRITICAL`.
- Cosign keyless sign image sau khi push.
- Cosign verify image voi GitHub Actions OIDC identity.

Commit evidence:

```text
481cc9d Add Trivy scan and Cosign signing to CI
4f7b357 Fix Trivy action version
b587217 Update web image packages for Trivy
81c9cf9 ci: update web image to b587217
```

Admission policy:

```bash
kubectl get ns demo --show-labels
kubectl get clusterimagepolicy require-signed-web-image
```

Ket qua da kiem:

```text
demo   Active   kubernetes.io/metadata.name=demo,policy.sigstore.dev/include=true
ClusterImagePolicy require-signed-web-image Ready=True
```

Unsigned image reject:

```text
Error from server (BadRequest): admission webhook "policy.sigstore.dev" denied the request:
validation failed: invalid value: docker.io/khanh15/web:unsigned-test must be an image digest
```

Signed image pass:

```text
pod/signed-web-test created (server dry run)
```

Ghi chu ArgoCD:

- Policy-controller mutate live image tu tag sang digest, vi du `index.docker.io/khanh15/web:1fd0c5d@sha256:...`.
- `argocd/apps/web.yaml` ignore field image cua Deployment `web` de tranh drift gia do admission mutation.

File lien quan:

```text
.github/workflows/ci-cd.yaml
policies/cluster-image-policy.yaml
policies/demo-namespace.yaml
argocd/apps/policy-controller.yaml
argocd/apps/policies.yaml
signing/README.md
```

## Platform status

Lenh kiem:

```bash
kubectl get applications.argoproj.io -n argocd
```

Trang thai da kiem truoc khi tao evidence:

```text
api                      Synced      Healthy
argo-rollouts            Synced      Healthy
eso                      Synced      Healthy
eso-config               Synced      Healthy
gatekeeper               Synced      Healthy
gatekeeper-constraints   Synced      Healthy
kube-prometheus-stack    Synced      Healthy
policies                 Synced      Healthy
policy-controller        Synced      Healthy
rbac                     Synced      Healthy
root                     Synced      Healthy
web                      Healthy
```

## Secret hygiene

Lenh kiem:

```bash
git log -p | grep -i password
git grep -n -E 'ghp_|github_pat_|AWS_SECRET_ACCESS_KEY|aws_secret_access_key'
```

Ket qua:

- Khong commit GitHub PAT.
- Khong commit AWS credential that.
- Secret runtime duoc tao bang `kubectl create secret`, khong dua vao git.

