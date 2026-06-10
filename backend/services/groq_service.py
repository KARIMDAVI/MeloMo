# groq_service.py — Classify free-text mood input into a structured mood.
# Groq free tier: 30 req/min, Llama 3 70B — fast enough for real-time use.
# AsyncGroq is required: sync client.chat.completions.create() would block the event loop.
import os
import json
from groq import AsyncGroq

client = AsyncGroq(api_key=os.environ["GROQ_API_KEY"])

SYSTEM_PROMPT = """You are a mood classifier for a music app. Given user input and optional biometric data (HRV, sleep, activity), return JSON with:
- mood: the closest mood name (e.g. "Focused", "Happy", "Calm", "Energetic", "Sad", "Romantic")
- category: one of [energetic, chill, focused, emotional, romantic, social, magical, melancholy]
- energy: float 0.0-1.0 (0=very calm, 1=maximum energy)
- explanation: one sentence explaining the music you'll find for this mood, referencing the user's state if biometrics are provided.
- top_moods: array of 3 {mood, category, confidence} alternatives

Return ONLY valid JSON. No markdown, no extra text."""


async def classify_mood(user_input: str, biometrics: dict = None) -> dict:
    """Send user text and optional biometrics to Groq LLM and get structured mood classification."""
    
    prompt = f"User Input: {user_input}"
    if biometrics:
        prompt += f"\nBiometric State: {biometrics}"

    response = await client.chat.completions.create(
        model="llama3-70b-8192",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ],
        temperature=0.3,    # Low temp = consistent, predictable mood mapping
        max_tokens=300,
    )
    raw = response.choices[0].message.content.strip()
    return json.loads(raw)
