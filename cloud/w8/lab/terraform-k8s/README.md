# Terraform Minikube trên AWS

Repository này dùng **Terraform** để tự động tạo một môi trường Kubernetes nhỏ trên AWS. Terraform sẽ tạo một máy chủ EC2 Ubuntu, cài Docker, Minikube và kubectl trên máy đó, sau đó deploy một ứng dụng HTTP nhẹ vào bên trong cụm Kubernetes. Bên ngoài, AWS Application Load Balancer sẽ nhận traffic từ browser và chuyển tiếp vào ứng dụng đang chạy trong Minikube.

Mục tiêu của bài này là chứng minh được toàn bộ luồng hạ tầng và ứng dụng có thể được dựng lại từ đầu bằng Terraform:

- Có hạ tầng AWS thật.
- Có Kubernetes thật chạy bằng Minikube trên EC2.
- Ứng dụng chạy trong Kubernetes, không phải chạy trực tiếp trên EC2.
- Có URL public từ ALB để mở app trên browser.
- Có thể dọn sạch tài nguyên bằng `terraform destroy`.

## 1. Cách chạy từ repo sạch

Trước khi chạy, máy local cần có:

- Terraform đã được cài đặt.
- AWS credentials đã được cấu hình sẵn. Có thể cấu hình bằng `aws configure` hoặc dùng biến môi trường như `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
- AWS account có **default VPC** trong region `ap-southeast-2`, hoặc region khác nếu truyền biến `aws_region`.

Chạy lệnh sau tại thư mục root của repo:

```bash
terraform init && terraform apply -auto-approve
```

Lệnh `terraform init` tải các provider cần thiết. Lệnh `terraform apply -auto-approve` tạo hạ tầng AWS, cài Minikube, deploy app và tạo ALB.

Sau khi chạy xong, Terraform sẽ in ra output dạng:

```text
app_url = "http://<alb-dns-name>"
```

Mở URL đó trên browser. Nếu mọi thứ chạy đúng, nội dung trả về sẽ là:

```text
Welcome to Khanh DevOps Lab
```

Có thể kiểm tra nhanh bằng terminal:

```bash
curl "$(terraform output -raw app_url)"
```

Kết quả mong đợi:

```text
Welcome to Khanh DevOps Lab
```

Sau khi chấm bài hoặc kiểm tra xong, cần dọn tài nguyên để tránh phát sinh chi phí AWS:

```bash
terraform destroy -auto-approve
```

## 2. Kiến trúc tổng thể

Luồng traffic từ người dùng đến ứng dụng:

```text
User / Browser
  |
  | HTTP :80
  v
AWS Application Load Balancer
  |
  | Forward đến target group port :30080
  v
EC2 Ubuntu instance
  |
  | Máy EC2 chạy Minikube bằng Docker driver
  v
Kubernetes NodePort Service :30080
  |
  | Chuyển tiếp vào targetPort :5678
  v
hello Deployment
  |
  | Container app
  v
hashicorp/http-echo:1.0.0
```

Giải thích ngắn gọn:

- Browser gọi vào DNS của ALB qua HTTP port `80`.
- ALB forward request đến EC2 qua port `30080`.
- Port `30080` là NodePort của Kubernetes service.
- Kubernetes service chuyển request vào pod của deployment `hello`.
- Pod chạy container `hashicorp/http-echo:1.0.0` và trả về dòng text `Welcome to Khanh DevOps Lab`.

## 3. Terraform flow

Terraform tạo và wire các phần theo thứ tự logic sau:

```text
AWS provider
  -> Lấy default VPC và default subnets
  -> Tạo security group
  -> Tạo AWS key pair
  -> Tạo EC2 instance
  -> Tạo ALB, listener và target group

TLS provider
  -> Tạo SSH private/public key
  -> Public key được đăng ký thành AWS key pair

Null provider
  -> SSH vào EC2
  -> Copy script cài đặt
  -> Cài Docker, Minikube, kubectl
  -> Copy Kubernetes manifests
  -> Chạy kubectl apply để deploy app
```

## 4. Provider sử dụng

Repo này dùng 3 Terraform provider:

- `hashicorp/aws`: provider chính, dùng để tạo và đọc tài nguyên AWS như EC2, Security Group, VPC, Subnet, ALB, Target Group và Listener.
- `hashicorp/tls`: dùng để tạo SSH key pair ngay trong Terraform. Public key được đưa lên AWS thành key pair cho EC2, còn private key được dùng để SSH provision.
- `hashicorp/null`: dùng `null_resource` và provisioner để chạy các bước imperative sau khi EC2 đã được tạo, ví dụ copy file và chạy lệnh qua SSH.

Cách các provider được wire với nhau:

```text
tls_private_key.ssh
  -> aws_key_pair.k8s
  -> aws_instance.k8s
  -> null_resource.install_minikube
  -> null_resource.deploy_app
```

Chi tiết:

- `tls_private_key.ssh` tạo cặp private/public key.
- `aws_key_pair.k8s` lấy public key đó và đăng ký lên AWS.
- `aws_instance.k8s` dùng key pair này khi tạo EC2.
- `null_resource.install_minikube` dùng private key để SSH vào EC2 và cài Minikube.
- `null_resource.deploy_app` tiếp tục dùng SSH để copy manifest và chạy `kubectl apply`.

Nhờ cách này, repo không cần phụ thuộc vào file `.pem` tạo thủ công từ trước. Khi chạy từ repo sạch, Terraform tự tạo key cần thiết.

## 5. Ứng dụng được deploy như thế nào

Ứng dụng nằm trong thư mục `manifests/`.

File `manifests/deployment.yaml` tạo deployment tên `hello`, chạy image:

```text
hashicorp/http-echo:1.0.0
```

Container được cấu hình để trả về:

```text
Welcome to Khanh DevOps Lab
```

File `manifests/service.yaml` tạo service kiểu `NodePort`, expose app ra port `30080` trên node:

```text
Service port: 80
Target port: 5678
NodePort: 30080
```

Terraform không cài app trực tiếp lên EC2. EC2 chỉ là máy host để chạy Minikube. App thật sự được chạy bên trong Kubernetes bằng `kubectl apply`.

## 6. Lý do chọn thiết kế này

App được chọn là `hashicorp/http-echo:1.0.0` vì rất nhẹ, dễ kiểm tra và không cần build Docker image riêng. Với bài tập hạ tầng, mục tiêu chính là chứng minh traffic đi đúng vào Kubernetes pod, nên một HTTP echo app là đủ rõ ràng.

Cluster dùng **Minikube** thay vì EKS để giữ bài làm nhỏ gọn. EKS phù hợp production hơn nhưng sẽ tạo nhiều tài nguyên hơn, chi phí cao hơn và cấu hình dài hơn. Với bài demo, một EC2 chạy Minikube là đủ để chứng minh có Kubernetes thật.

Minikube dùng **Docker driver** vì Docker cài đơn giản trên Ubuntu EC2. Script `scripts/install_minikube.sh` cài Docker, Minikube, kubectl rồi chạy `minikube start --driver=docker`.

Network dùng **default VPC** thay vì tự tạo VPC mới. Cách này giúp giảm số lượng resource Terraform và dễ chạy hơn trong bài tập. Nếu làm production, nên tách VPC riêng, subnet public/private riêng, security group cho ALB riêng và security group cho EC2 riêng.

## 7. Cấu trúc thư mục

```text
.
|-- provider.tf
|-- variables.tf
|-- network.tf
|-- sg.tf
|-- keypair.tf
|-- ec2.tf
|-- k8s.tf
|-- deploy_app.tf
|-- alb.tf
|-- outputs.tf
|-- scripts/
|   `-- install_minikube.sh
`-- manifests/
    |-- deployment.yaml
    `-- service.yaml
```

Ý nghĩa các file chính:

- `provider.tf`: khai báo provider AWS, TLS và Null.
- `variables.tf`: khai báo biến đầu vào, hiện tại có biến `key_name`.
- `network.tf`: lấy default VPC và subnets từ AWS.
- `sg.tf`: tạo security group mở các port cần thiết.
- `keypair.tf`: tạo SSH key pair bằng provider TLS và đăng ký public key lên AWS.
- `ec2.tf`: tạo EC2 Ubuntu để chạy Minikube.
- `k8s.tf`: SSH vào EC2, copy script và cài Minikube.
- `deploy_app.tf`: copy Kubernetes manifests và chạy `kubectl apply`.
- `alb.tf`: tạo Application Load Balancer, target group và listener.
- `outputs.tf`: xuất DNS của ALB và URL app.
- `scripts/install_minikube.sh`: script cài Docker, Minikube và kubectl trên EC2.
- `manifests/deployment.yaml`: định nghĩa Kubernetes Deployment.
- `manifests/service.yaml`: định nghĩa Kubernetes Service kiểu NodePort.

## 8. Biến

File `variables.tf` hiện có:

```hcl
variable "aws_region" {
  default = "ap-southeast-2"
}

variable "key_name" {
  default = "terraform-k8s-generated"
}

variable "admin_cidr" {
  default = "0.0.0.0/0"
}
```

- `aws_region`: region AWS dùng để tạo tài nguyên. Mặc định là `ap-southeast-2`.
- `key_name`: tên AWS key pair mà Terraform tạo.
- `admin_cidr`: dải IP được phép SSH vào EC2 và truy cập Kubernetes API. Mặc định là `0.0.0.0/0` để dễ demo, nhưng khi làm thật nên đổi thành IP cá nhân.

Private key không cần truyền từ ngoài vào nữa vì provider `tls` tự tạo trong quá trình apply.

## 9. Module

Repo hiện tại dùng **root module duy nhất**, chưa tách module con.

<<<<<<< HEAD
Với quy mô bài tập nhỏ, cấu trúc flat giúp dễ đọc, dễ chấm và dễ hiểu luồng resource. Nếu mở rộng thêm, có thể tách thành các module như:

```text
modules/network
modules/compute
modules/k8s-bootstrap
modules/alb
```

Tuy nhiên, với yêu cầu hiện tại, root module là đủ.

## 10. Bằng chứng khi nộp bài

Sau khi chạy `terraform apply`, lấy output:

```bash
terraform output -raw app_url
```

Mở URL đó trên browser và chụp ảnh hoặc quay clip màn hình. Ảnh/clip cần thể hiện được:

http://hello-alb-1212541323.ap-southeast-2.elb.amazonaws.com/

<img width="839" height="155" alt="image" src="https://github.com/user-attachments/assets/3dd56aad-bb04-41db-a740-5d06422a988e" />

Sau khi có bằng chứng, chạy:
```bash
terraform destroy -auto-approve
```
Việc destroy sau khi chấm là cần thiết để tránh tốn chi phí EC2 và ALB trên AWS.
=======
