#!/bin/bash -e
export DEBIAN_FRONTEND=noninteractive

# Install the JDK
sudo apt-get install -yqq -o Dpkg::Use-Pty="0" openjdk-17-jdk > /dev/null
java --version

# Install Helm
sudo snap install helm --classic

# Install Terraform
sudo snap install terraform --classic
terraform -version

#Install aws cli
curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli > /dev/null
aws --version

# Install Chrome
mkdir ~/Downloads
cd ~/Downloads
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb > /dev/null

# Install IntelliJ & Code
mkdir ~/bin
mkdir ~/opt
mkdir ~/src
sudo snap install intellij-idea-ultimate --classic
intellij-idea-ultimate --version
sudo snap install --classic code
code --v

# Install and configure microk8s 
sudo snap install microk8s --classic
sudo usermod -a -G microk8s ubuntu
sudo microk8s.status --wait-ready
sudo microk8s.enable hostpath-storage
sudo microk8s.enable registry
sudo microk8s.enable dns
sudo microk8s.enable rbac
sudo microk8s.enable helm
sudo microk8s.status --wait-ready
mkdir ~/.kube
sudo microk8s.config > ~/.kube/config
chmod 400 ~/.kube/config
sudo microk8s.kubectl completion bash | sudo tee -a /etc/bash_completion.d/kubectl > /dev/null

# Install podman
sudo apt-get install -yqq -o Dpkg::Use-Pty="0" podman > /dev/null
podman --version

# Install maven
sudo apt-get install -yqq -o Dpkg::Use-Pty="0" maven > /dev/null
mvn --version

# Configure bashrc file
cat << EOF >> ~/.bashrc

alias h="history | grep "

alias kubectl='microk8s kubectl'
alias k='microk8s kubectl'
complete -F __start_kubectl k

complete -C /snap/bin/terraform terraform

# Git Prompt
export GIT_PS1_SHOWDIRTYSTATE=1
export PROMPT_COMMAND='__git_ps1 "\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]" "$ "'

complete -C aws_completer aws
EOF

source ~/.bashrc 
git config --global user.name "${developer_name}"
git config --global user.email "${developer_email}"