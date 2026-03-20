#!/bin/sh


#set +e
# Installing packets
echo 'Installing necessary packages'
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install -y postgresql-17 nginx python3 python3-pip python3-venv

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

# User operator creation
sudo groupadd -f operator
sudo useradd -m -s /bin/bash -g operator operator || true
echo "operator:12345678" | sudo chpasswd
sudo chage -d 0 operator

# Operator restrictions
echo 'operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.service, \
  /usr/bin/systemctl stop mywebapp.service, /usr/bin/systemctl restart mywebapp.service, \
  /usr/bin/systemctl status mywebapp.service, /usr/bin/systemctl reload nginx.service' \
  | sudo tee /etc/sudoers.d/operator-rules > /dev/null
chmod 0440 /etc/sudoers.d/operator-rules


# Vagrant Ubuntu boxes usually disable password SSH logins by default.
echo 'Allowing for ssh into virtual machine'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*.conf 
sudo systemctl restart ssh

# Install and enable postgresql
echo 'Configuring postgresql'
sudo systemctl status postgresql
sudo cp ./postgresql.conf /var/lib/psql/17/main/postgresql.conf
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE USER app WITH ENCRYPTED PASSWORD '12345678';" || true
sudo -u postgres psql -c "CREATE DATABASE mywebapp_db OWNER app;" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mywebapp_db TO app;"

# Nginx
echo 'Configuring nginx'
sudo cp ./mywebapp.conf /etc/nginx/sites-available/mywebapp.conf
sudo ln -sf /etc/nginx/sites-available/mywebapp.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# Systemd
echo 'Starting up webapp'
# Install pip packages
sudo mkdir -p /etc/mywebapp
sudo cp ./config.toml /etc/mywebapp/config.toml
sudo chown -R root:app /etc/mywebapp
sudo chmod 640 /etc/mywebapp/config.toml
sudo mkdir -p /opt/mywebapp
sudo cp ./mywebapp/app.py ./mywebapp/migrate.py ./mywebapp/requirements.txt /opt/mywebapp/
sudo chown -R app:app /opt/mywebapp
sudo -u app python3 -m venv /opt/mywebapp/venv
sudo -u app /opt/mywebapp/venv/bin/pip install -r /opt/mywebapp/requirements.txt

sudo cp ./mywebapp.service /etc/systemd/system/mywebapp.service
sudo systemctl daemon-reload
sudo systemctl enable mywebapp
sudo systemctl start mywebapp

# Gradebook
echo "29" | sudo tee /home/student/gradebook

# Lock default vagrant user
sudo passwd -l vagrant
sudo chage -E 0 vagrant
