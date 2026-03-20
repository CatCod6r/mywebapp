import psycopg2
import toml
import os

CONFIG_PATH = "/etc/mywebapp/config.toml"

def migrate():
    if not os.path.exists(CONFIG_PATH):
        print(f"Error: {CONFIG_PATH} not found.")
        return

    config = toml.load(CONFIG_PATH)
    
    try:
        conn = psycopg2.connect(**config['database'])
        cur = conn.cursor()

        # Table for Simple Inventory (V3=3): id, name, quantity, created_at 
        cur.execute("""
            CREATE TABLE IF NOT EXISTS inventory (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                quantity INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # Mandatory index creation [cite: 54]
        cur.execute("CREATE INDEX IF NOT EXISTS idx_inventory_name ON inventory(name);")
        
        conn.commit()
        cur.close()
        conn.close()
        print("Migration successful: Database is ready.")
    except Exception as e:
        print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
