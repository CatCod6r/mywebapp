#!/bin/sh
set +e

echo 'Оновлення системи...'
sudo apt update && sudo apt upgrade -y

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
# Оскільки Vagrantfile клонує репозиторій і переходить у папку mywebapp перед запуском setup.sh,
# ми знаходимося в директорії, де лежить ваш docker-compose.yml
sudo docker compose up -d --build

echo 'Контейнери успішно запущені!'

echo 'даєм права веріфаю'
chmod +x ./verify.sh 

echo 'Запускаєм ранер'
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.334.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz
echo "048024cd2c848eb6f14d5646d56c13a4def2ae7ee3ad12122bee960c56f3d271  actions-runner-linux-x64-2.334.0.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz
./config.sh --url https://github.com/CatCod6r/mywebapp --token TOKEN
./run.sh
