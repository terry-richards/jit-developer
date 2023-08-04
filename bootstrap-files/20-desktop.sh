#!/bin/bash -e
DEBIAN_FRONTEND=noninteractive

# Install a minimal desktop
sudo apt-get install -yqq -o Dpkg::Use-Pty="0" ubuntu-desktop-minimal > /dev/null
# No need for a dektop manager
sudo systemctl disable gdm > /dev/null

# Configure VNC
sudo apt-get install -yqq -o Dpkg::Use-Pty="0" tigervnc-standalone-server tigervnc-xorg-extension > /dev/null
mkdir /home/ubuntu/.vnc
echo `date +%s | sha256sum | base64 | head -c 8 ; echo` | vncpasswd -f > /home/ubuntu/.vnc/passwd
chmod 0600 /home/ubuntu/.vnc/passwd

cat <<EOF > /home/ubuntu/.vnc/config
session=ubuntu
localhost
EOF

cat <<EOF > /home/ubuntu/.vnc/xstartup
#!/bin/bash
gnome-session
EOF

chmod +x /home/ubuntu/.vnc/xstartup