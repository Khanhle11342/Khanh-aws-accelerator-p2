# Runbook: Rotate Secret bang ESO

Muc tieu: doi secret nguon, Kubernetes Secret cap nhat trong `<60s`, pod khong restart.

## Kiem tra truoc

```bash
kubectl get externalsecret -n demo api-db-credentials
kubectl get secret -n demo api-db-credentials -o jsonpath='{.data.db_pass}' | base64 -d; echo
kubectl get pod -n demo -l app=api -o wide
```

## Rotate secret nguon

Secret nguon cua lab dang la `eso-source-db` trong namespace `demo`.

```bash
kubectl create secret generic eso-source-db \
  -n demo \
  --from-literal=db_pass='new-value-here' \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Xac minh

```bash
kubectl get secret -n demo api-db-credentials -o jsonpath='{.data.db_pass}' | base64 -d; echo
kubectl get pod -n demo -l app=api -o wide
```

Dat khi:

- Gia tri secret dich doi theo trong khoang `refreshInterval`.
- Pod UID/AGE khong doi.
- Khong commit credential that vao git.

