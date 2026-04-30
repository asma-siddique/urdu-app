# Dockerfile — Urdu Learning App backend
# Base: Python 3.11 slim + system libs for audio processing

FROM python:3.11-slim

# System audio libraries (required by librosa / soundfile)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    libgomp1 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for layer caching
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY backend/ .

# Pre-download models at build time (optional — set env vars to skip)
# If ASR_MODEL_ID / PRON_MODEL_ID are set the API will load them at runtime
# ARG ASR_MODEL_ID=your-username/urdu-asr-whisper
# RUN python -c "from transformers import pipeline; pipeline('automatic-speech-recognition', model='${ASR_MODEL_ID}')"

# Create model cache dir
RUN mkdir -p /app/model_cache
ENV TRANSFORMERS_CACHE=/app/model_cache
ENV HF_HOME=/app/model_cache

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run FastAPI with Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]