from fastapi import FastAPI

app = FastAPI(
    title="MLOps Sample ML API",
    description="Sample ML API for Helm-based MLOps deployment",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "Hello from MLOps ML API",
        "version": "1.0.0"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }


@app.get("/predict")
def predict():
    return {
        "prediction": "sample-prediction",
        "model_version": "1.0.0"
    }