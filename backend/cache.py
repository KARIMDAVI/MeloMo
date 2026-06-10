# cache.py — Simple in-memory TTL cache.
# No Redis needed at this scale — resets on cold start, which is fine.
# Same mood hit twice in 1 hour returns the same playlist (saves Groq + music API quota).
import time


class TTLCache:
    def __init__(self, ttl_seconds: int = 3600):
        self._store: dict = {}
        self._ttl = ttl_seconds

    def get(self, key: str):
        entry = self._store.get(key)
        if entry and time.time() - entry["ts"] < self._ttl:
            return entry["value"]
        return None

    def set(self, key: str, value):
        self._store[key] = {"value": value, "ts": time.time()}

    def clear(self):
        self._store.clear()


# Module-level singleton — shared across all requests in one process
playlist_cache = TTLCache(ttl_seconds=3600)
