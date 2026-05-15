#!/bin/bash
echo "Запуск верифікації розгортання..."

# Очікуємо 10 секунд, поки база даних та flask ініціалізуються
sleep 10

# Перевіряємо HTTP статус головної сторінки
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

if [ "$STATUS" -eq 200 ]; then
  echo "Верифікація успішна: отримано статус 200"
  exit 0
else
  echo "Верифікація провалена: отримано статус $STATUS"
  exit 1
fi
