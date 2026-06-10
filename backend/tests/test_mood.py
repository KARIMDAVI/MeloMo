# backend/tests/test_mood.py
import pytest
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_generate_playlist():
    response = client.post("/mood/generate", json={"input": "happy"})
    assert response.status_code == 200
    data = response.json()
    assert "mood" in data
    assert "tracks" in data
