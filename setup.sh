#!/bin/sh

# Installing packets
echo 'Installing necessary packages'
sudo apt install -y postgresql-17 nginx python 
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

# Lock default vagrant user

# Vagrant Ubuntu boxes usually disable password SSH logins by default.
echo 'Allowing for ssh into virtual machine'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*.conf /e>
sudo systemctl restart ssh

# Install and enable postgresql
echo 'Configuring postgresql'
sudo cp ./postgresql.conf /var/lib/pgsql/17/postgresql.conf
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

systemctl start nginx


# Gradebook
echo "29" > /home/student/gradebook
