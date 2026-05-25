#!/bin/sh
set +e

echo 'Оновлення системи...'
sudo apt update && sudo apt upgrade -y > /dev/null

echo 'Встановлення необхідних пакетів для Docker...'
sudo apt install -y ca-certificates curl gnupg lsb-release

echo 'Додавання офіційного GPG-ключа Docker...'
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo 'Налаштування репозиторію Docker...'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo 'Встановлення Docker Engine та Docker Compose...'
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo 'Запуск сервісу Docker...'
sudo systemctl enable docker
sudo systemctl start docker

echo 'Запуск контейнерів через Docker Compose...'
sudo docker compose up -d --build

echo 'Контейнери успішно запущені!'

echo 'даєм права веріфаю'
chmod +x ./verify.sh 
