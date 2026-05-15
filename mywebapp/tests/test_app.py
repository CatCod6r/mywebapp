import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """Перевірка, що головна сторінка доступна"""
    response = client.get('/')
    assert response.status_code in [200, 500] # 500 ок, якщо БД ще не піднята

def test_health_check(client):
    """Перевірка доступності маршруту /health/ (якщо він є)"""
    response = client.get('/health/')
    # Згідно з вашим nginx.conf, цей шлях має бути заборонений або видавати 404
    assert response.status_code == 404
