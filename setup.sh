#!/bin/sh


#set +e
# Installing packets
echo 'Installing necessary packages'
sudo apt update && sudo apt upgrade -y
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'G
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
sudo apt update -y
sudo apt install -y postgresql-17 nginx python3 python3-pip python3-venv
pip install -r ./mywebapp/requirements.txt

echo 'Creating users'
# User student creation
sudo useradd -m -s /bin/bash student
sudo usermod -aG sudo student

# User teacher creation
sudo useradd -m -s /bin/bash teacher
sudo usermod -aG sudo teacher
sudo echo "teacher:12345678" | chpasswd
sudo chage -d 0 teacher

# User app creation
sudo useradd -m -s /bin/false app
sudo usermod -aG postgres app

# User operator creation
sudo useradd -m -s /bin/bash operator
sudo usermod -aG sudo operator
sudo echo "operator:12345678" | chpasswd
sudo chage -d 0 operator

# Operator restrictions
echo 'operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.service, \
  /usr/bin/systemctl stop mywebapp.service, /usr/bin/systemctl restart mywebapp.service, \
  /usr/bin/systemctl status mywebapp.service, /usr/bin/systemctl reload nginx.service' \
  | sudo tee /etc/sudoers.d/operator-rules > /dev/null
chmod 0440 /etc/sudoers.d/operator-rules

# Lock default vagrant user
sudo passwd -l vagrant
sudo chage -E 0 vagrant

# Vagrant Ubuntu boxes usually disable password SSH logins by default.
echo 'Allowing for ssh into virtual machine'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*.conf 
sudo systemctl restart ssh

# Install and enable postgresql
echo 'Configuring postgresql'
sudo cp ./postgresql.conf /var/lib/psql/17/postgresql.conf
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -i -u postgres
createuser app
createdb mywebapp_db 
psql
alter user app with encrypted password '12345678'; # make it get out of config
grant all privileges on database mywebapp_db to app;
\q

# Configuring and starting web app
echo 'Starting up webapp'
sudo cp -r ./mywebapp /etc/mywebapp
sudo cp ./mywebapp.service /etc/systemd/system/mywebapp.service
systemctl start mywebapp
systemctl enable mywebapp

# Start nginx
echo 'Configuring nginx'
cp ./mywebapp.conf /etc/nginx/sites-available/vaultwarden.conf
sudo ln -s /etc/nginx/sites-available/vaultwarden.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl start nginx


# Gradebook
echo "29" > /home/student/gradebook
