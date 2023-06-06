#!/usr/bin/env bash

# stop when error occurs
set -o errexit  
# if not, expressions like `error here | true` will always succeed
set -o pipefail 
# detects uninitialised variables
set -o nounset  

# update and upgrade
apt update && apt upgrade -y
apt install -y --no-install-recommends --no-install-suggests vim httpie nmap jq unzip mc tree figlet btop bat
apt clean 

# set the hostname based on public ip address
hostnamectl hostname  $( curl -s ifconfig.me | tr . - )
echo '@reboot root hostnamectl hostname $(curl -s ifconfig.me | tr . -)' >> /etc/crontab

# set timezone
rm /etc/timezone /etc/localtime
echo "Europe/Bratislava" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# install starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

# download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" --output-dir /usr/local/bin/
chmod +x /usr/local/bin/kubectl
kubectl completion bash > /etc/bash_completion.d/kubectl

# download and install helm3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm completion bash > /etc/bash_completion.d/helm

# download and install k3d
# curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
# su - ubuntu -c 'k3d cluster create training'
# k3d completion bash > /etc/bash_completion.d/k3d

# download and install k3s
curl -sfL https://get.k3s.io | sh -
mkdir -p /home/ubuntu/.kube/
k3s kubectl config view --raw > /home/ubuntu/.kube/config
chmod g-r,o-r /home/ubuntu/.kube/config
k3s completion bash > /etc/bash_completion.d/k3s

# disable default storage class
# sed -i '/server/a\    --disable local-storage \\' /etc/systemd/system/k3s.service

# modify .bashrc
cat <<- 'EOF' >> /home/ubuntu/.bashrc
# set HOSTIP and update PATH
export HOSTIP=$(hostname | tr - .)
export PATH="/home/ubuntu/.local/bin:$PATH"
# init starship for bash
eval "$(starship init bash)"

# syntax highlighting for less and cat
alias cat='batcat --plain --paging=never'
alias less='batcat --plain --paging=always'
EOF

# setup tmux
mkdir -p /home/ubuntu/.tmux/themes/
curl http://mirek.s.cnl.sk/configs/basic.tmuxtheme --output /home/ubuntu/.tmux/themes/basic.tmuxtheme
curl http://mirek.s.cnl.sk/configs/tmux.conf --output /home/ubuntu/.tmux.conf

# setup vim
curl http://mirek.s.cnl.sk/configs/vimrc --output /home/ubuntu/.vimrc

# download editorconfig
curl http://mirek.s.cnl.sk/configs/editorconfig --output /home/ubuntu/.editorconfig

# install k9s
export PATH="/home/ubuntu/.local/bin:$PATH"
sudo su - ubuntu -c "curl -sS https://webi.sh/k9s | sh"
k9s completion bash > /etc/bash_completion.d/k9s
rm -rf /home/ubuntu/Downloads

# download k8s templates
mkdir /home/ubuntu/templates/ 
curl http://mirek.s.cnl.sk/configs/templates/k8s.tgz  | tar xvz -C /home/ubuntu/templates/

# change ownership of home directory
chown -R ubuntu.ubuntu /home/ubuntu/

# reboot at the end
reboot

