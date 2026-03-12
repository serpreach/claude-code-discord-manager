FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# Install discord.py
RUN pip install --no-cache-dir discord.py

# Install Node.js + Claude Code CLI
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @anthropic-ai/claude-code && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY bridge.py /app/bridge.py

CMD ["python3", "-u", "bridge.py"]
