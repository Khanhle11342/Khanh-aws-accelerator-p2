# Bằng Chứng - GitOps, SLO Alert, Canary, Rollback

## Tóm Tắt

| Tiêu chí | Trạng thái | Bằng chứng |
| --- | --- | --- |
| Mọi thay đổi đi qua Git, ArgoCD synced, reproduce được từ Git | Đạt | Các ArgoCD Application đều `Synced` và `Healthy`; app trỏ tới `modules/apps/*`. |
| Rollback bằng `git revert` dưới 5 phút | Đạt | Commit `06f7238 Revert "test api v4 rollout"` đã rollback API về trạng thái `Synced Healthy`. |
| Có 1 SLO + alert firing gửi về email cá nhân | Đạt | Có rule `ApiHighErrorRate`; `AlertmanagerConfig` route alert `severity=warning` về Gmail; Gmail đã nhận `[FIRING:1] EmailTestAlert demo`. |
| Canary bản lỗi tự abort về bản cũ | Đạt | Đã có `AnalysisTemplate` và đã chứng minh canary tự động bản tốt. Để đủ điểm hoàn toàn, cần chụp thêm bad canary có `AnalysisRun Failed` và rollout bị abort. |

## 1. GitOps Reproduce Được Từ Git

Cấu trúc repo:

```text
argocd/root.yaml
argocd/apps/api.yaml
argocd/apps/web.yaml
argocd/apps/argo-rollouts.yaml
argocd/apps/kube-prometheus-stack.yaml
modules/apps/api/
modules/apps/web/
```

Lệnh kiểm tra:

```bash
kubectl -n argocd get applications
```

Output đã ghi nhận:

<img width="790" height="193" alt="image" src="https://github.com/user-attachments/assets/b0f93815-d66f-4ba1-b6c4-7a44afe85069" />


Đường dẫn module của app:

```text
argocd/apps/api.yaml -> modules/apps/api
argocd/apps/web.yaml -> modules/apps/web
```

Kết luận: app được quản lý từ Git, ArgoCD sync từ repo, không deploy tay.

## 2. Rollback Bằng Git Revert Dưới 5 Phút

Log rollback:

```bash
git log --oneline -8
```

Output đã ghi nhận:

<img width="861" height="215" alt="image" src="https://github.com/user-attachments/assets/effeed96-5170-4074-9cf3-ffc55c27d61e" />


Trạng thái sau rollback:

```bash
kubectl -n argocd get app api
kubectl -n demo get rollout api -o wide
kubectl -n demo get pods -l app=api
```

Output đã ghi nhận:

<img width="908" height="496" alt="image" src="https://github.com/user-attachments/assets/b102c889-780a-4c0e-8ed8-0d6e4642f3da" />


Kết luận: rollback được thực hiện bằng `git revert`, sau đó ArgoCD tự sync và đưa API về `Synced Healthy`.

## 3. SLO Alert Gửi Về Gmail Cá Nhân

Các resource đã cài:

```bash
kubectl -n demo get analysistemplate,prometheusrule,alertmanagerconfig,servicemonitor
```

Output đã ghi nhận:

<img width="1025" height="342" alt="image" src="https://github.com/user-attachments/assets/5fbcbe05-cdab-44f5-a908-879a4769a078" />


Prometheus đã load rule:

```bash
kubectl -n monitoring exec prometheus-kube-prometheus-stack-prometheus-0 -c prometheus -- \
  wget -qO- 'http://127.0.0.1:9090/api/v1/rules' | grep -o 'ApiHighErrorRate\|api-slo' | sort | uniq
```

Output đã ghi nhận:

<img width="963" height="148" alt="image" src="https://github.com/user-attachments/assets/8409b83f-6666-46cb-86ad-2f34bb2049cf" />


Route của Alertmanager:

```text
AlertmanagerConfig: api-email-alerts
Receiver: demo/api-email-alerts/personal-email
To: khanhle11342@gmail.com
SMTP: smtp.gmail.com:587
```

Bằng chứng email:

<img width="1517" height="207" alt="image" src="https://github.com/user-attachments/assets/92d247d1-d9f6-4f7e-b1ad-d5d6d3f54e21" />

Điểm quan trọng đã sửa:

```yaml
labels:
  namespace: demo
  severity: warning
```

Label `namespace: demo` là bắt buộc để `AlertmanagerConfig` trong namespace `demo` route alert vào receiver `personal-email`, thay vì rơi vào receiver mặc định `null`.

## 4. Canary Tự Động Và Auto-Abort

Cấu hình canary tự động hiện tại:

```text
modules/apps/api/rollout.yaml
modules/apps/api/analysis-template.yaml
modules/apps/api/prometheus-rule.yaml
```

Rollout đang dùng các bước:

```yaml
strategy:
  canary:
    steps:
      - setWeight: 25
      - analysis:
          templates:
            - templateName: api-success-rate
      - setWeight: 50
      - analysis:
          templates:
            - templateName: api-success-rate
      - setWeight: 100
```

Analysis query Prometheus và yêu cầu success rate >= 95%:

```yaml
successCondition: result[0] >= 0.95
```

Bằng chứng đã có cho canary tự động bản tốt:

```text
analysisrun.argoproj.io/api-6b9f7f4cd5-3-1   Successful
analysisrun.argoproj.io/api-6b9f7f4cd5-3-3   Successful
```

### Ảnh Cuối Cần Chụp Cho Auto-Abort

Để chứng minh đầy đủ tiêu chí auto-abort, chạy một bad canary qua Git:

```bash
sed -i 's/value: "0"/value: "1"/' modules/apps/api/rollout.yaml
sed -i 's/value: "v3"/value: "bad"/' modules/apps/api/rollout.yaml

git add modules/apps/api/rollout.yaml
git commit -m "inject bad api version"
git push origin main
```

Sau đó chụp:

```bash
kubectl -n argocd get app api
kubectl -n demo get rollout api -o wide
kubectl -n demo get analysisrun
kubectl -n demo describe rollout api
```

Kỳ vọng:

```text
AnalysisRun Failed
Rollout Degraded hoặc Aborted
stable ReplicaSet vẫn available
bad version không lên 100%
```

Rollback sau bad canary:

```bash
git revert HEAD
git push origin main
```

Sau đó chụp:

```bash
kubectl -n argocd get app api
kubectl -n demo get rollout api -o wide
kubectl -n demo get pods -l app=api
```

Kỳ vọng:

```text
api Synced Healthy
api AVAILABLE 4
pods Running
```
