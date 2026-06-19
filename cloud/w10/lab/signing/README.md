# Signing

Lab nay dung Cosign keyless signing voi GitHub Actions OIDC.

Khong co `cosign.key` va khong can `cosign.pub`.
Admission policy verify bang identity cua workflow:

```text
issuer: https://token.actions.githubusercontent.com
subject: https://github.com/Khanhle11342/Khanh-aws-accelerator-p2/.github/workflows/ci-cd.yaml@refs/heads/main
```

Neu chuyen sang key-pair signing thi chi commit `cosign.pub`; private key phai dat trong GitHub Secret.

