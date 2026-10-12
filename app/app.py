import os
from flask import Flask

app = Flask(__name__)

# Güvenli yaklaşım: Hassas bilgiler kodda tutulmaz, ortam değişkeninden okunur
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "default_safe_value")

@app.route("/")
def home():
    return "Guvenli DevSecOps Uygulamasi Calisiyor!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
