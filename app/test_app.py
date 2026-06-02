import pytest
import fakeredis
from app import app, redis_client

@pytest.fixture
def client():
    # 1. Swap the real Redis client with an in-memory fake Redis
    fake_redis = fakeredis.FakeRedis(decode_responses=True)
    
    # Monkeypatch replaces the app's redis_client with our fake one
    original_redis = app.redis_client if hasattr(app, 'redis_client') else None
    import app as app_module
    app_module.redis_client = fake_redis

    # 2. Configure Flask for testing
    app.config.update({
        "TESTING": True,
    })

    # 3. Yield the Flask test client to the test functions
    with app.test_client() as client:
        yield client

    # Clean up fake redis data after the test finishes
    fake_redis.flushall()

# --- THE TESTS ---

def test_hello_world(client):
    """Test the base route returns HTML"""
    response = client.get('/')
    assert response.status_code == 200
    assert b"<h1>Hello, World!</h1>" in response.data

def test_health_check_healthy(client):
    """Test health check when Redis is connected"""
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json == { "status": "healthy", "redis": "connected" }

def test_post_item_success(client):
    """Test successfully pushing an item to the list"""
    payload = {"item": "Buy Milk"}
    response = client.post('/items', json=payload)
    
    assert response.status_code == 201
    assert response.json["message"] == "Item added"
    assert response.json["item"] == "Buy Milk"

def test_post_item_missing_payload(client):
    """Test error handling when no item is provided"""
    response = client.post('/items', json={})
    assert response.status_code == 400
    assert "error" in response.json

def test_get_items(client):
    """Test retrieving items from the list"""
    # Pre-populate our fake redis via a POST request
    client.post('/items', json={"item": "Apples"})
    client.post('/items', json={"item": "Bananas"})

    # Fetch them via GET
    response = client.get('/items')
    assert response.status_code == 200
    assert response.json == { "items": ["Apples", "Bananas"] }
