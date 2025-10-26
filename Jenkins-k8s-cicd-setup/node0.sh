#!/bin/bash
# Master Node Setup
sudo hostnamectl set-hostname node0
echo "10.0.1.10 node0.kube.com node0" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.11 node1.kube.com node1" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.12 node2.kube.com node2" | sudo tee -a /etc/hosts > /dev/null
echo "10.0.1.13 node3.kube.com node3" | sudo tee -a /etc/hosts > /dev/null
# Update system and install basic tools
sudo yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion sos psacct nfs-utils curl iproute tc

# wget ftp://ftp.icm.edu.pl/vol/rzm3/linux-centos-vault/7.9.2009/virt/x86_64/ovirt-common/Packages/s/sshpass-1.06-2.el7.x86_64.rpm
#wget https://rpm.pbone.net/info_idpl_111323056_distro_rockylinux8_com_sshpass-1.09-4.el8.x86_64.rpm.html

wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/x86_64/os/Packages/sshpass-1.09-4.el9.x86_64.rpm
sudo rpm -ivh sshpass-1.09-4.el9.x86_64.rpm

sudo yum install -y gpg

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf upgrade
# Add required dependencies for the jenkins package
sudo yum install -y java-17-openjdk-devel
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
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
#sudo groupadd docker
sudo usermod -aG docker azureuser
sudo usermod -aG docker jenkins
sudo chmod 777 /var/run/docker.sock

sudo -u azureuser bash -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q <<<y'
sudo -u azureuser ls -l /home/azureuser/.ssh/
echo "azureuser ALL=(ALL) NOPASSWD:ALL" |  sudo tee /etc/sudoers.d/90-cloud-init-users-azureuser
echo "jenkins ALL=(azureuser) NOPASSWD: /bin/cp"  |  sudo tee /etc/sudoers.d/90-cloud-init-users-azureuser


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
