#!/bin/sh

# створити користувачів - x
# створити базу даних - x
# скопіювати або згенерувати конфігураційні файли - x
# встановити systemd-сервіс для веб-застосунку - x
# запустити сервіс - x
# налаштувати nginx - x

# Installing packets
sudo apt install -y postgresql nginx python 
pip install flask ..,

# Config file creation


# Systemd file for web app
 
#Adding all needed users(app, operator, student)

# Adding user for testing by teacher
useradd -m -s /bin/bash teacher
echo "teacher:12345678" | chpasswd
usermod -aG sudo teacher
chage -d 0 teacher
# Vagrant Ubuntu boxes usually disable password SSH logins by default.
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*.conf /e>
systemctl restart ssh

# Gradebook
echo "29" > /home/student/gradebook
