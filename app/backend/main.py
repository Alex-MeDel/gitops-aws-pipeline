from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="GitOps Demo API")

# Allow requests from the frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": "backend-api"}

@app.get("/api/data")
def get_data():
    return {
        "message": "Hello World!",
        "metrics": {
            "uptime": "operational",
            "db_status": "connected",
            "build": "v1.0.0"
        }
    }