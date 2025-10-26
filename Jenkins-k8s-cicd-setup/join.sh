JOIN_CMD=$(kubeadm token create --print-join-command)
echo $JOIN_CMD > /home/azureuser/join.sh
chmod +x /home/azureuser/join.sh