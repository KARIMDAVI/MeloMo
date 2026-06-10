# main.py — FastAPI entry point for MeloMo backend.
# CORS is wide open now — tighten to iOS bundle ID before App Store submission.
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import mood, export

app = FastAPI(title="MeloMo Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://melomo.app", "http://localhost:3000", "http://127.0.0.1:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(mood.router, prefix="/mood", tags=["mood"])
app.include_router(export.router, prefix="/playlist", tags=["export"])


@app.get("/health")
async def health():
    return {"status": "ok"}
