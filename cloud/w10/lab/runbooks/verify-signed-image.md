# Runbook: Verify signed image admission

Muc tieu: image chua ky bi reject, image da ky tu CI duoc pass.

## Xac minh policy

```bash
kubectl get ns demo --show-labels
kubectl get clusterimagepolicy require-signed-web-image
```

Namespace `demo` can co label:

```text
policy.sigstore.dev/include=true
```

## Test image chua ky

Dung image tag khong duoc ky. Manifest van can resources va non-root de khong bi Gatekeeper chan truoc.

```bash
kubectl run unsigned-web-test \
  -n demo \
  --image=docker.io/khanh15/web:unsigned-test \
  --dry-run=server -o yaml
```

Ky vong: admission webhook `policy.sigstore.dev` reject.

## Test image da ky

```bash
kubectl run signed-web-test \
  -n demo \
  --image=docker.io/khanh15/web:b587217 \
  --dry-run=server -o yaml
```

Ky vong: server dry-run pass.

