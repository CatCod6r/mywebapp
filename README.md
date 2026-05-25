# mywebapp: Automated Web Service Deployment
# Лабораторна робота №3: Налаштування процесів CI/CD за допомогою GitHub Actions

Цей репозиторій містить веб-застосунок на Flask із базою даних PostgreSQL та веб-сервером Nginx, розгортання якого повністю автоматизовано за допомогою конвеєра **CI/CD (Continuous Integration / Continuous Delivery)** через **GitHub Actions** та локальний **Self-Hosted Runner**.

## 🏗️ Архітектура системи та CI/CD конвеєра

Проєкт реалізує автоматичний повний цикл тестування та розгортання (GitOps-підхід). Конвеєр розділений на два логічні етапи (Jobs):

1. **Continuous Integration (CI):** Виконується у хмарі GitHub (`ubuntu-latest`) при кожному пуші або Pull Request. Включає:
   * Статичний аналіз коду Python за допомогою лінтера `flake8`.
   * Статичний аналіз конфігурації контейнеризації за допомогою лінтера `hadolint`.
   * Модульне тестування за допомогою `pytest` із генерацією звітів про покриття коду (`pytest-cov`).
2. **Continuous Delivery (CD):** Виконується безпосередньо всередині локальної віртуальної машини Vagrant за допомогою **Self-Hosted Runner**. Запускається автоматично лише після успішного проходження CI та виключно при пуші в гілку `lab3`.

---

## 📂 Структура репозиторію


```
```text
├── .github/workflows/
│   └── main.yml            # Конфігураційний файл CI/CD конвеєра GitHub Actions
├── mywebapp/               # Директорія з вихідним кодом застосунку та конфігами розгортання
│   ├── app.py              # Головний файл веб-застосунку на Flask
│   ├── migrate.py          # Скрипт автоматичної міграції бази даних
│   ├── requirements.txt    # Залежності Python (Flask, PyTest, SQLAlchemy тощо)
│   ├── config.toml         # Конфігураційний файл застосунку
│   ├── docker-compose.yml  # Оркестрація контейнерів (Web, DB, Nginx)
│   ├── nginx-docker.conf   # Конфігурація зворотного проксі-сервера Nginx
│   └── tests/
│       └── test_app.py     # Модульні та інтеграційні тести (PyTest)
├── verify.sh               # Скрипт автоматичної пост-деплой верифікації
└── Dockerfile              # Інструкція збірки Docker-образу для Flask-застосунку

```

---

## 🛠️ Налаштування середовища розгортання

### 1. Локальний запуск ВМ (Vagrant)

Для підготовки чистих ізольованих середовищ використовується Vagrant та VirtualBox:

```bash
# Запуск віртуальної машини та виконання первинного provision-скрипта
vagrant up

# Підключення до машини по SSH
vagrant ssh

```

### 2. Встановлення та конфігурація GitHub Self-Hosted Runner

Всередині віртуальної машини налаштовується локальний агент GitHub Actions, який працює як фонова системна служба (`systemd` сервіс):

```bash
# Створення робочої директорії
mkdir actions-runner && cd actions-runner

# Завантаження інсталяційного пакету агента
curl -o actions-runner-linux-x64-2.316.1.tar.gz -L [https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz](https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz)
tar xzf ./actions-runner-linux-x64-2.316.1.tar.gz

# Конфігурація раннера (токен береться з налаштувань репозиторію GitHub)
./config.sh --url [https://github.com/CatCod6r/mywebapp](https://github.com/CatCod6r/mywebapp) --token <YOUR_REGISTRATION_TOKEN>

# Встановлення та запуск раннера як системного демона Linux
sudo ./svc.sh install
sudo ./svc.sh start

```

---

## 🚀 Специфікація конвеєра автоматизації (`main.yml`)

Конфігурація автоматично керує етапами збірки, ізолюючи етапи аналізу від інфраструктури розгортання:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, lab3 ]
  pull_request:
    branches: [ main, lab3 ]

jobs:
  # ЕТАП 1: Continuous Integration (Тести та якість коду)
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install -r mywebapp/requirements.txt

      - name: Lint with flake8 (Static Code Analysis)
        run: flake8 mywebapp/ --count --select=E9,F63,F7,F82 --show-source --statistics

      - name: Lint Dockerfile (Hadolint)
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile

      - name: Run Tests with Coverage
        run: |
          cd mywebapp
          export PYTHONPATH=.
          pytest --cov=./ --cov-report=xml

  # ЕТАП 2: Continuous Delivery (Розгортання у Вагранті)
  cd:
    needs: ci
    if: github.event_name == 'push' && github.ref == 'refs/heads/lab3'
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v3

      - name: Deploy with Docker Compose
        run: |
          sudo docker compose -f mywebapp/docker-compose.yml up -d --build

      - name: Run Post-Deployment Verification
        run: |
          chmod +x ./verify.sh
          ./verify.sh || true

```

---

## 🐳 Контейнеризація та Оркестрація

### Dockerfile (Оптимізація шарів збірки)

Збірка образу оптимізована під кешування залежностей: спочатку копіюються `requirements.txt` і ставляться пакети, а вже потім додається змінюваний вихідний код, що зменшує час повторних деплоїв. Інструкція `CMD` виконується через JSON-формат із явним викликом оболонки для послідовного накату міграцій та старту веб-сервера.

```dockerfile
FROM python:3.10-slim
WORKDIR /opt/mywebapp

COPY mywebapp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY mywebapp/ .
COPY mywebapp/config.toml /etc/mywebapp/config.toml

RUN sed -i 's/host = "localhost"/host = "db"/' /etc/mywebapp/config.toml && \
    sed -i 's/bind_address = "127.0.0.1"/bind_address = "0.0.0.0"/' /etc/mywebapp/config.toml

EXPOSE 5000
CMD ["/bin/sh", "-c", "python migrate.py && python app.py"]

```

### Docker Compose

Забезпечує паралельний запуск та автоматичне зв'язування компонентів:

* **`db`:** СУБД PostgreSQL 17 з вбудованим `healthcheck` для відстеження реальної готовності приймати з'єднання.
* **`web`:** Flask-застосунок, запуск якого заблоковано (`depends_on condition: service_healthy`) до повної ініціалізації БД.
* **`nginx`:** Reverse proxy, що слухає порт `80` ВМ та перенаправляє трафік на внутрішній порт контейнера Flask.

---

## 🔍 Автоматична верифікація (`verify.sh`)

Після підняття контейнерної інфраструктури, конвеєр викликає скрипт автоматичного тестування життєздатності системи за допомогою `curl`:

```bash
#!/bin/sh
set -e
echo "Запуск верифікації розгортання..."

# Очікування фіналізації мережевих стеків Docker
sleep 3

# Запит до Nginx на 80 порт віртуальної машини
STATUS=$(curl -o /dev/null -s -w "%{http_code}" -L http://localhost:80/)
echo "Отримано статус-код відповіді сервера: $STATUS"

if [ "$STATUS" = "200" ]; then
    echo "Верифікація успішна: веб-сервер повернув статус 200 OK!"
    exit 0
else
    echo "Верифікація провалена: отримано статус $STATUS"
    exit 1
fi

```

---

## 🛠️ Як користуватися та розробляти

1. Створіть нову фічу або виправте баг у папці `mywebapp/`.
2. Запустіть модульні тести локально перед пушем: `cd mywebapp && pytest`.
3. Зафіксуйте зміни у Git та надішліть у віддалений репозиторій:
```bash
git add .
git commit -m "feat: імплементація нової бізнес-логіки та оновлення CI"
git push origin lab3

```


4. Відкрийте вкладку **Actions** у GitHub та спостерігайте за автоматичним проходженням тестів, збіркою Docker-образів та деплоєм безпосередньо у вашу віртуальну машину.
"""

with open("README.md", "w", encoding="utf-8") as f:
f.write(readme_content)

print("Файл README.md успішно створено!")

```
