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

wget ftp://ftp.icm.edu.pl/vol/rzm5/linux-centos-vault/7.4.1708/extras/x86_64/Packages/sshpass-1.06-2.el7.x86_64.rpm
sudo yum -y install sshpass-1.06-2.el7.x86_64.rpm

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

# Disable firewalld to allow overlay networking (VXLAN/BGP)
sudo systemctl disable --now firewalld || true

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
echo "jenkins ALL=(azureuser) NOPASSWD: /bin/cp"  |  sudo tee /etc/sudoers.d/90-cloud-init-users-azureuser

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

[local]
localhost ansible_connection=local

[all:vars]
ansible_user=azureuser

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

# Use Calico default pod CIDR
sudo kubeadm init   --pod-network-cidr=192.168.0.0/16   --apiserver-advertise-address=10.0.1.11   --control-plane-endpoint=node1.kube.com 2>&1 | tee -a kubeadm_output.log
# # sleep 15

#sudo kubeadm init   --pod-network-cidr=192.168.0.0/16   --apiserver-advertise-address=10.0.1.11   --control-plane-endpoint=node1.kube.com 2>&1 | tee -a kubeadm_output.log

# # # Run post-init commands as the regular user (e.g., azureuser or ubuntu)
sudo -u azureuser bash << 'EOF_SCRIPT'
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
EOF_SCRIPT

# Apply Calico CNI (using admin kubeconfig)
curl -sSL https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml -o calico.yaml
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f calico.yaml

# Ensure Calico uses VXLAN on Azure (disable IPIP), and set a safe MTU.
# Wait for the Calico IPPool CRD and the default pool to exist, then patch.
until kubectl --kubeconfig=/etc/kubernetes/admin.conf get crd ippools.crd.projectcalico.org &>/dev/null; do
  echo "⏳ Waiting for Calico IPPool CRD..."; sleep 5; done
until kubectl --kubeconfig=/etc/kubernetes/admin.conf get ippools.crd.projectcalico.org default-ipv4-ippool &>/dev/null; do
  echo "⏳ Waiting for default-ipv4-ippool..."; sleep 5; done
kubectl --kubeconfig=/etc/kubernetes/admin.conf patch ippools.crd.projectcalico.org default-ipv4-ippool \
  --type=merge -p '{"spec":{"ipipMode":"Never","vxlanMode":"Always","mtu":1440}}' || true
# Restart calico-node to pick up changes immediately
kubectl --kubeconfig=/etc/kubernetes/admin.conf -n kube-system rollout restart ds/calico-node || true
kubectl --kubeconfig=/etc/kubernetes/admin.conf -n kube-system rollout status ds/calico-node --timeout=180s || true

# JOIN_CMD=$(grep -A3 'Then you can join any number of worker nodes' kubeadm_output.log | tail -n 2 | tr -d '\\\n')

# for ip in "10.0.1.12"; do
# ssh azureuser@ip "sudo $JOIN_CMD"
# sleep 5
# done

# for ip in "10.0.1.13"; do
# ssh azureuser@ip "sudo $JOIN_CMD"
# sleep 5
# done

#wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# # Wait for API server to respond
# until kubectl get --raw=/healthz &>/dev/null; do
#   echo "⏳ Waiting for Kubernetes API server to be ready..."
#   sleep 5
# done


# echo "✅ Kubernetes API server is up!"

# kubectl apply -f calico.yaml

# sleep 15

# hosts=("10.0.1.12" "10.0.1.13")

# for ip in "${hosts[@]}"; do
#   echo "Joining node at $ip"
#   ssh azureuser@$ip "sudo $JOIN_CMD"
#   sleep 5
# done




