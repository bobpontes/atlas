from flask import Flask
import psycopg2

app = Flask(__name__)

# função para chamar o banco de dados:
def get_db():
    conn = psycopg2.connect(
        dbname="atlas_db",
        user="brunopontes",
        host="localhost"
    )
    return conn

conn = get_db()
print("Conexão com o banco de dados estabelecida com sucesso!")
conn.close()

@app.route("/")
def hello():
    return "Hello, World!"  

if __name__ == '__main__':
    app.run(debug=False)