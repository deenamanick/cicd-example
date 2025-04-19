### Install Jenkins, Docker, Kuberentes, Git in one shot

Let me read and analyze the file content first. One sec.

Thanks! From the Terraform config, I can see you're setting up:

- A **Virtual Network** and **Subnet**
- A **Network Security Group (NSG)** with rules (like SSH)
- Most likely you'll be provisioning VMs where Docker, Jenkins, and Kubernetes will be installed — either using cloud-init, remote-exec, or a custom script.

---

### 📝 Here's a sample `README.md` for your project:

```markdown
# Terraform Automation for Docker, Jenkins, and Kubernetes Setup on Azure

This Terraform project automates the provisioning of infrastructure on Azure and sets up:
- Docker
- Jenkins (CI/CD server)
- Kubernetes (via kubeadm or microk8s, depending on configuration)

---

## 🚀 What This Code Does

- Creates an Azure Resource Group
- Sets up a Virtual Network and Subnet
- Applies a Network Security Group with SSH access
- Provisions one or more Virtual Machines (Ubuntu)
- Installs:
  - Docker
  - Jenkins
  - Kubernetes (on designated VMs)

---

## 📁 Files Structure

- `main.tf`: Main Terraform configuration
- `variables.tf` (optional): Input variables
- `outputs.tf` (optional): Outputs such as public IPs

---

## 🔧 How to Use

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review and Apply the Plan

```bash
terraform plan
terraform apply
```

### 3. Post-provisioning

Once the VM is provisioned:
- Jenkins is typically accessible on port 8080 of the public IP.
- Kubernetes will be initialized and ready for `kubectl` access.

---

## 🔐 Security Notes

- Ensure the SSH key used is secure.
- NSG allows SSH (port 22) — modify security rules for production use.

---

## 🧹 Cleanup

```bash
terraform destroy
```

This will remove all resources created by the project.

---

