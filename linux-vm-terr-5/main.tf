# Define the resource group
data "azurerm_resource_group" "my_rg" {
  name = ""
}

# Define the virtual network
resource "azurerm_virtual_network" "my_vnet" {
  name                = "myVnet"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Define the subnet
resource "azurerm_subnet" "my_subnet" {
  name                 = "mySubnet"
  resource_group_name  = data.azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define the Network Security Group
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-http-8080"
    priority                   = 110 # Must be unique and higher than 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }



}

# Create multiple network interfaces for 3 VMs
resource "azurerm_network_interface" "my_terraform_nic" {
  count               = 4
  name                = "myNIC-${count.index}"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name

  ip_configuration {
    name                          = "myIPConfig-${count.index}"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${10 + count.index}" # Assign specific static IPs
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip[count.index].id


  }
}

# Define the storage account
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "storagek8001" # Ensure this name is unique
  resource_group_name      = data.azurerm_resource_group.my_rg.name
  location                 = data.azurerm_resource_group.my_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create 3 Linux virtual machines and attach network interfaces
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  count                 = 4
  name                  = "k8s-node-${count.index}"
  location              = data.azurerm_resource_group.my_rg.location
  resource_group_name   = data.azurerm_resource_group.my_rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic[count.index].id]
  size                  = "Standard_B2ms"

  os_disk {
    name                 = "k8s-node-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    # publisher = "Canonical"
    # offer     = "0001-com-ubuntu-server-jammy"
    # sku       = "22_04-lts-gen2"
    # version   = "latest"

    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

  computer_name                   = "k8s-node-${count.index}"
  admin_username                  = "azureuser"
  admin_password                  = "Welc0me@123"
  disable_password_authentication = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }


  # custom_data = base64encode(lookup(var.init_scripts, count.index))
  custom_data = base64encode(trimspace(replace(lookup(var.init_scripts, count.index), "\r\n", "\n")))


}


# Associate the network security group with each NIC
resource "azurerm_network_interface_security_group_association" "example" {
  count                     = 4
  network_interface_id      = azurerm_network_interface.my_terraform_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  #name                = "myPublicIP"
  count               = 4
  name                = "myPublicIP-${count.index}"
  location            = data.azurerm_resource_group.my_rg.location
  resource_group_name = data.azurerm_resource_group.my_rg.name
  #allocation_method   = "Dynamic"
  sku               = "Standard" # You have this set already
  allocation_method = "Static"   # This is REQUIRED for Standard SKU
}


variable "init_scripts" {
  type = map(string)
  default = {
0 = <<-EOF
#!/bin/bash
# Master Node Setup
sudo hostnamectl set-hostname node0
echo "10.0.1.10 node0.kube.com node0" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.11 node1.kube.com node1" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.12 node2.kube.com node2" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.13 node3.kube.com node3" | sudo tee -a /etc/hosts > /dev/null
# Update system and install basic tools
sudo yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion sos psacct nfs-utils curl iproute tc

wget ftp://ftp.icm.edu.pl/vol/rzm7/linux-centos-vault/8.1.1911/cloud/x86_64/openstack-train/Packages/s/sshpass-1.06-8.el8.x86_64.rpm
sudo rpm -ivh sshpass-1.06-8.el8.x86_64.rpm

sudo yum install -y gpg

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf upgrade
# Add required dependencies for the jenkins package
sudo yum install -y java-17-openjdk-devel
sudo dnf install -y jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins

# Install Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins
sudo chmod 777 /var/run/docker.sock

sudo -u azureuser bash -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q <<<y'
sudo -u azureuser ls -l /home/azureuser/.ssh/

# SonarQube System Settings
cat <<SYSCTL | sudo tee -a /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
SYSCTL
sudo sysctl -p

# Install Maven
sudo yum install -y maven
sudo yum install -y git

# Verify installations
echo "Java version:"
java -version
echo "Docker version:"
docker --version
echo "Maven version:"
mvn --version
echo "Jenkins status:"
sudo systemctl status jenkins

# # Copy SSH key to worker nodes
for ip in "10.0.1.11"; do
  sudo -u azureuser sshpass -p "Welc0me@123" ssh-copy-id -o StrictHostKeyChecking=no -i /home/azureuser/.ssh/id_rsa.pub azureuser@$ip
done

EOF


1 = <<-EOF
#!/bin/bash
# Master Node Setup
sudo hostnamectl set-hostname node1
echo "10.0.1.10 node0.kube.com node0" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.11 node1.kube.com node1" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.12 node2.kube.com node2" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.13 node3.kube.com node3" | sudo tee -a /etc/hosts > /dev/null
      
# Update and install required packages
sudo yum clean all ; sudo yum repolist
sudo yum -y update
sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct nfs-utils curl iproute-tc sshpass chpasswd
sudo yum -y install python3-pip
sudo -u azureuser bash -c 'pip3 install --user ansible'
wget ftp://ftp.icm.edu.pl/vol/rzm7/linux-centos-vault/8.1.1911/cloud/x86_64/openstack-train/Packages/s/sshpass-1.06-8.el8.x86_64.rpm
sudo rpm -ivh sshpass-1.06-8.el8.x86_64.rpm

#Install Containerd
wget https://github.com/containerd/containerd/releases/download/v2.0.0/containerd-2.0.0-linux-amd64.tar.gz
tar Cxzvf /usr/local/ containerd-2.0.0-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system
wget -P /usr/local/lib/systemd/system/ https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

#install runc

wget https://github.com/opencontainers/runc/releases/download/v1.2.2/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
#cni plugin

wget https://github.com/containernetworking/plugins/releases/download/v1.6.0/cni-plugins-linux-amd64-v1.6.0.tgz

sudo mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin/ cni-plugins-linux-amd64-v1.6.0.tgz

#install crictl command
VERSION="v1.31.1"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

cat <<CRICTL | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
CRICTL

cat <<K8S | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
K8S

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<K8SSYS | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
K8SSYS

# Apply sysctl params without reboot
sudo sysctl --system

sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.conf

sudo lsmod | grep br_netfilter
sudo lsmod | grep overlay

mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key |  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


cat <<KUBER | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
KUBER

sudo rpm --import https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

echo 1 > /proc/sys/net/ipv4/ip_forward
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


sudo usermod -aG wheel azureuser
sudo echo "root:redhat" | sudo chpasswd
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
PASSWORD="Welc0me@123"

# Generate SSH key for azureuser user
sudo -u azureuser bash -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q <<<y'
sudo -u azureuser ls -l /home/azureuser/.ssh/
echo "azureuser ALL=(ALL) NOPASSWD:ALL" |  sudo tee /etc/sudoers.d/90-cloud-init-users-azureuser

# Create inventory file
sudo -u azureuser mkdir -p /home/azureuser/plays
cat <<HOSTFILE | sudo tee /home/azureuser/plays/inventory.ini
[workers]
node1.kube.com ansible_host=10.0.1.11 ansible_user=azureuser
node2.kube.com ansible_host=10.0.1.12 ansible_user=azureuser
node3.kube.com ansible_host=10.0.1.13 ansible_user=azureuser

[master]
node1

[workers]
node2
node3

HOSTFILE


cat <<ANSIBLECFG | sudo -u azureuser tee /home/azureuser/plays/ansible.cfg
[defaults]
inventory = ./inventory.ini
remote_user = azureuser
host_key_checking = False
deprecation_warnings = False
interpreter_python = auto_silent

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ack_pass = false
ANSIBLECFG



# # Copy SSH key to worker nodes
for ip in "10.0.1.12"; do
  sudo -u azureuser sshpass -p "Welc0me@123" ssh-copy-id -o StrictHostKeyChecking=no -i /home/azureuser/.ssh/id_rsa.pub azureuser@$ip
done

for ip in "10.0.1.13"; do
  sudo -u azureuser sshpass -p "Welc0me@123" ssh-copy-id -o StrictHostKeyChecking=no -i /home/azureuser/.ssh/id_rsa.pub azureuser@$ip
done

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sudo kubeadm config images pull

sudo kubeadm init   --pod-network-cidr=10.244.0.0/16   --apiserver-advertise-address=10.0.1.11   --control-plane-endpoint=node1.kube.com 2>&1 | tee -a kubeadm_output.log
sleep 15

# Run post-init commands as the regular user (e.g., azureuser or ubuntu)
sudo -u azureuser bash << 'EOF_SCRIPT'
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
EOF_SCRIPT

wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

kubect apply -f kube-flannel.yml

kubectl get nodes

EOF

2 = <<-EOF

#!/bin/bash
# Master Node Setup
sudo hostnamectl set-hostname node2
echo "10.0.1.10 node0.kube.com node0" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.11 node1.kube.com node1" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.12 node2.kube.com node2" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.13 node3.kube.com node3" | sudo tee -a /etc/hosts > /dev/null

# Update and install required packages
sudo yum clean all ; sudo yum repolist
sudo yum -y update
sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct nfs-utils curl iproute-tc sshpass chpasswd
sudo yum -y install python3-pip
pip3 install --user ansible

#Install Containerd
wget https://github.com/containerd/containerd/releases/download/v2.0.0/containerd-2.0.0-linux-amd64.tar.gz
tar Cxzvf /usr/local/ containerd-2.0.0-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system
wget -P /usr/local/lib/systemd/system/ https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

systemctl daemon-reload
systemctl enable --now containerd

#install runc

wget https://github.com/opencontainers/runc/releases/download/v1.2.2/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
#cni plugin

wget https://github.com/containernetworking/plugins/releases/download/v1.6.0/cni-plugins-linux-amd64-v1.6.0.tgz

mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin/ cni-plugins-linux-amd64-v1.6.0.tgz

#install crictl command
VERSION="v1.31.1"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

cat <<CRICTL | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
CRICTL

cat <<K8S | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
K8S

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<K8SSYS | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
K8SSYS

# Apply sysctl params without reboot
sysctl --system

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

modprobe br_netfilter
sysctl -p /etc/sysctl.conf

lsmod | grep br_netfilter
lsmod | grep overlay

mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key |  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


cat <<KUBER | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
KUBER

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

echo 1 > /proc/sys/net/ipv4/ip_forward
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


sudo usermod -aG wheel azureuser
sudo echo "root:redhat" | sudo chpasswd
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
PASSWORD="P@ssw0rd123"

# Generate SSH key for azureuser user
#sudo -u azureuser bash -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q <<<y'
sudo -u azureuser ls -l /home/azureuser/.ssh/
echo "azureuser ALL=(ALL) NOPASSWD:ALL" |  sudo tee /etc/sudoers.d/90-cloud-init-users-azureuser

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
     
EOF

3 = <<-EOF
#
#!/bin/bash
# Master Node Setup
sudo hostnamectl set-hostname node3
echo "10.0.1.10 node0.kube.com node0" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.11 node1.kube.com node1" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.12 node2.kube.com node2" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.13 node3.kube.com node3" | sudo tee -a /etc/hosts > /dev/null

# Update and install required packages
sudo yum clean all ; sudo yum repolist
sudo yum -y update
sudo yum -y install epel-release
sudo yum -y update
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct nfs-utils curl iproute-tc sshpass chpasswd
sudo yum -y install python3-pip
pip3 install --user ansible

#Install Containerd
wget https://github.com/containerd/containerd/releases/download/v2.0.0/containerd-2.0.0-linux-amd64.tar.gz
tar Cxzvf /usr/local/ containerd-2.0.0-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system
wget -P /usr/local/lib/systemd/system/ https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

systemctl daemon-reload
systemctl enable --now containerd

#install runc

wget https://github.com/opencontainers/runc/releases/download/v1.2.2/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
#cni plugin

wget https://github.com/containernetworking/plugins/releases/download/v1.6.0/cni-plugins-linux-amd64-v1.6.0.tgz

mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin/ cni-plugins-linux-amd64-v1.6.0.tgz

#install crictl command
VERSION="v1.31.1"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

cat <<CRICTL | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
CRICTL

cat <<K8S | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
K8S

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<K8SSYS | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
K8SSYS

# Apply sysctl params without reboot
sysctl --system

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

modprobe br_netfilter
sysctl -p /etc/sysctl.conf

lsmod | grep br_netfilter
lsmod | grep overlay

mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key |  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


cat <<KUBER | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
KUBER

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

echo 1 > /proc/sys/net/ipv4/ip_forward
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


sudo usermod -aG wheel azureuser
sudo echo "root:redhat" | sudo chpasswd
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
PASSWORD="P@ssw0rd123"

# Generate SSH key for azureuser user
#sudo -u azureuser bash -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q <<<y'
sudo -u azureuser ls -l /home/azureuser/.ssh/
echo "azureuser ALL=(ALL) NOPASSWD:ALL" |  sudo tee /etc/sudoers.d/90-cloud-init-users-azureuser

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    EOF
  }
}



