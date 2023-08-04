#!/bin/bash -e
export DEBIAN_FRONTEND=noninteractive

# Upgrade Ubuntu
sudo apt-get update -qq && sudo apt-get upgrade -yqq -o Dpkg::Use-Pty="0" > /dev/null

# Change the hostname
echo "Changing Hostname"
sudo hostname "${instance_name}"
echo "${instance_name}" | sudo tee /etc/hostname

# Set timezone (GMT not great for a developer machine)
echo "Changing Timezone to ${developer_timezone}"
sudo timedatectl set-timezone ${developer_timezone}

# Set up unattended upgrades - these settings should be changed as appropriate 
sudo apt-get install -yqq -o Dpkg::Use-Pty="0" unattended-upgrades  > /dev/null

echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "3";
APT::Periodic::Unattended-Upgrade "1";
'  | sudo tee /etc/apt/apt.conf.d/10periodic  > /dev/null

sudo sed -i 's#//\t"$${distro_id}:$${distro_codename}-updates"#\t"$${distro_id}:$${distro_codename}-updates"#' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Remove-Unused-Dependencies "false"#Unattended-Upgrade::Remove-Unused-Dependencies "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Automatic-Reboot "false"#Unattended-Upgrade::Automatic-Reboot "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Automatic-Reboot-Time "02:00"#Unattended-Upgrade::Automatic-Reboot-Time "04:00"#' /etc/apt/apt.conf.d/50unattended-upgrades

sudo systemctl enable unattended-upgrades > /dev/null
sudo systemctl start unattended-upgrades > /dev/null
# Set up endless history
sed -i 's#HISTSIZE=1000#HISTSIZE=#' ~/.bashrc
sed -i 's#HISTFILESIZE=2000#HISTFILESIZE=#' ~/.bashrc
