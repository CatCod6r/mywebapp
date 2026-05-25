FROM python:3.10-slim

WORKDIR /opt/mywebapp

# 1. Копіюємо requirements.txt саме з підпапки з кодом
COPY mywebapp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Копіюємо весь вміст папки з кодом (app.py, migrate.py тощо) в контейнер
COPY . .
RUN ls -la && pwd
RUN mkdir -p /etc/mywebapp && cp ./config.toml /etc/mywebapp/config.toml

# Змінюємо хост БД з localhost на db (назва сервісу в docker-compose)
# та bind_address на 0.0.0.0, щоб Flask був доступний ззовні контейнера
RUN sed -i 's/host = "localhost"/host = "db"/' /etc/mywebapp/config.toml && \
    sed -i 's/bind_address = "127.0.0.1"/bind_address = "0.0.0.0"/' /etc/mywebapp/config.toml

EXPOSE 5000

# Запускаємо міграції перед стартом застосунку
CMD ["/bin/sh", "-c", "python migrate.py && python app.py"]
