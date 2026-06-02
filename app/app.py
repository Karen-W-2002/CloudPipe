from flask import Flask, request
import redis
import os

app = Flask(__name__)

redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    db=int(os.getenv('REDIS_DB', 0)),
    decode_responses=True
)

@app.route('/')
def hello_world():
    return "<h1>Hello, World!</h1>"

@app.route('/health')
def health_check():
    try:
        redis_client.ping()
        return { "status": "healthy", "redis": "connected" }
    except redis.ConnectionError:
        return { "status": "unhealthy", "redis": "disconnected" }, 503

@app.route('/items', methods=['GET', 'POST'])
def manage_items():
    if request.method == 'POST':
        item = request.json.get('item')
        if item:
            redis_client.rpush('items', item)
            return { "message": "Item added", "item": item }, 201
        else:
            return { "error": "No item provided" }, 400
    else:
        items = redis_client.lrange('items', 0, -1)
        return { "items": items}

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
