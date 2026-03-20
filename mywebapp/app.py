from flask import Flask, request, jsonify, make_response
import psycopg2
import toml
import os

app = Flask(__name__)
CONFIG_PATH = "/etc/mywebapp/config.toml"

def get_db_conn():
    config = toml.load(CONFIG_PATH)
    return psycopg2.connect(**config['database'])

def negotiate_response(data, html_body):
    """Returns HTML table or JSON based on Accept header [cite: 50]"""
    if 'text/html' in request.headers.get('Accept', ''):
        response = make_response(html_body)
        response.headers['Content-Type'] = 'text/html'
        return response
    return jsonify(data)

@app.route('/')
def root():
    """Root endpoint: lists all business logic endpoints (HTML only) [cite: 50]"""
    html = """
    <h1>mywebapp API Endpoints</h1>
    <ul>
        <li>GET /items - List all inventory items</li>
        <li>POST /items - Add new inventory item</li>
        <li>GET /items/&lt;id&gt; - View item details</li>
    </ul>
    """
    return html, 200, {'Content-Type': 'text/html'}

@app.route('/health/alive')
def health_alive():
    return "OK", 200 # [cite: 47]

@app.route('/health/ready')
def health_ready():
    try:
        conn = get_db_conn()
        conn.close()
        return "OK", 200 # [cite: 48]
    except Exception as e:
        return f"Database Unreachable: {str(e)}", 500 # [cite: 48]

@app.route('/items', methods=['GET', 'POST'])
def handle_items():
    conn = get_db_conn()
    cur = conn.cursor()

    if request.method == 'POST':
        # Create item: POST /items (name, quantity) 
        data = request.get_json()
        cur.execute("INSERT INTO inventory (name, quantity) VALUES (%s, %s) RETURNING id", 
                    (data['name'], data['quantity']))
        new_id = cur.fetchone()[0]
        conn.commit()
        return jsonify({"id": new_id, "status": "created"}), 201

    # List items: GET /items (id, name) 
    cur.execute("SELECT id, name FROM inventory")
    rows = cur.fetchall()
    items = [{"id": r[0], "name": r[1]} for r in rows]

    # HTML requirement: Use tables for lists [cite: 50]
    html = "<table border='1'><tr><th>ID</th><th>Name</th></tr>" + \
           "".join([f"<tr><td>{i['id']}</td><td>{i['name']}</td></tr>" for i in items]) + \
           "</table>"
    
    cur.close()
    conn.close()
    return negotiate_response(items, html)

@app.route('/items/<int:item_id>')
def item_detail(item_id):
    # Detail: GET /items/<id> (id, name, quantity, created_at) 
    conn = get_db_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, name, quantity, created_at FROM inventory WHERE id = %s", (item_id,))
    row = cur.fetchone()
    
    if not row:
        return "Not Found", 404

    data = {"id": row[0], "name": row[1], "quantity": row[2], "created_at": str(row[3])}
    html = f"<div><p>ID: {row[0]}</p><p>Name: {row[1]}</p><p>Qty: {row[2]}</p><p>Date: {row[3]}</p></div>"
    
    cur.close()
    conn.close()
    return negotiate_response(data, html)

if __name__ == '__main__':
    config = toml.load(CONFIG_PATH)
    # Listens on 127.0.0.1:5000 [cite: 18, 39]
    app.run(host=config['server']['bind_address'], port=config['server']['port'])
