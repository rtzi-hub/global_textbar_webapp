# ☁️ AWS Infrastructure Deployment with Terraform

This project uses **Terraform** to automate the deployment of a **Flask web application** on AWS. It provisions an **EC2 instance**, **S3 bucket**, **IAM roles**, **security groups**, and configures **Nginx, Gunicorn, and Flask** automatically.

---

## **📂 Terraform File Structure**
```bash
📂 Project Root
├── 📂 Terraform
│   ├── 📄 provider.tf          # AWS Provider configuration
│   ├── 📄 vpc.tf               # Defines AWS VPC and networking
│   ├── 📄 security_group.tf    # Security group rules (firewall settings)
│   ├── 📄 ec2.tf               # Defines the EC2 instance
│   ├── 📄 s3.tf                # AWS S3 bucket for storage
│   ├── 📄 iam.tf               # IAM Roles and Policies
│   ├── 📄 outputs.tf           # Terraform Outputs
│   ├── 📄 README.md            # Project documentation
│
├── 📂 Application
│   ├── 📄 app.py               # Flask application logic
│   ├── 📄 index.html           # Frontend UI
│   ├── 📄 flask-app.conf       # Nginx configuration file
│   ├── 📄 flask-app.service    # Systemd service to manage the Flask app
│
└── 📄 README.md                # Project documentation
```

## 🌍 Infrastructure Overview
When you run Terraform, it will create the following architecture:

## 1️⃣ EC2 Instance (Amazon Linux 2)
- Hosts the Flask application.
- Auto-configures Python, Flask, Gunicorn, and Nginx.
- Uses systemd to keep the app running.
## 2️⃣ S3 Bucket (for storing submitted words)
- Stores word submissions as .txt files.
- Configured with proper IAM permissions.
## 3️⃣ IAM Role (attached to EC2)
- Grants the EC2 instance access to the S3 bucket.
## 4️⃣ Security Groups
- Allows HTTP (80) & SSH (22) access.
- Restricts port 5000 to internal use only.

## 🛠 Prerequisites
Before running Terraform, ensure you have:
- ✅ AWS CLI installed and configured (aws configure)
- ✅ Terraform installed (terraform -v)
- ✅ SSH key pair (for EC2 access)
## 🚀 How to Deploy
# 1️⃣ Clone the Repository
```bash
git clone https://github.com/rtzi-hub/flask-WebTextBar.git
cd Flask-WebTextBar
```
## 2️⃣ Initialize Terraform
```bash
terraform init
```

## 3️⃣ Plan the Infrastructure
```bash
terraform plan
```

## 4️⃣ Apply Changes (Deploy AWS Infrastructure)
```bash
terraform apply -auto-approve
```

# ✅ What Happens After Running Terraform?
- ✅ Terraform creates all AWS resources automatically.
- ✅ The Flask app starts running on the EC2 instance.
- ✅ Nginx is configured as a reverse proxy.
- ✅ The application is accessible via http://<EC2-PUBLIC-IP>/.

# 🌐 How to Access the Flask App
After deployment, Terraform will output the EC2 public IP:

```bash
terraform output ec2_public_ip
```
Copy the IP and open:
```bash
http://<EC2-PUBLIC-IP>
```
To SSH into your instance:
```bash
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>
```

# 🛑 Destroying the Infrastructure
⚠️ **Before destroying, ensure your S3 bucket is empty!**
To remove all resources, run:
```bash
terraform destroy -auto-approve
```
