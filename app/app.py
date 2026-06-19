import os
import random
from pathlib import Path

from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics


app = Flask(__name__)
PrometheusMetrics(app)

ERR = float(os.getenv("ERROR_RATE", "0"))
VER = os.getenv("VERSION", "v1")
DB_SECRET_FILE = Path(os.getenv("DB_SECRET_FILE", "/var/run/app-secrets/db_pass"))


@app.get("/")
def index():
    if random.random() < ERR:
        return jsonify(error="injected", version=VER), 500
    return jsonify(ok=True, version=VER)


@app.get("/healthz")
def healthz():
    return "ok", 200


@app.get("/db-secret")
def db_secret():
    value = DB_SECRET_FILE.read_text(encoding="utf-8").strip()
    return jsonify(length=len(value), suffix=value[-4:], version=VER)
