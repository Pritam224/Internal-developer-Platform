"""hello-universe microservice — tiny FastAPI app with health endpoints."""
import os
from fastapi import FastAPI

app = FastAPI(title="hello-universe", version=os.environ.get("APP_VERSION", "dev"))


@app.get("/healthz")
def healthz():
    """Liveness probe — process is up."""
    return {"status": "ok"}


@app.get("/ready")
def ready():
    """Readiness probe — ready to serve traffic."""
    return {"status": "ready"}


@app.get("/")
def root():
    return {"message": "hello, universe", "service": app.title}
