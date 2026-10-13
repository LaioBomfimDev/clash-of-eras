FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Baixa o Godot 4.7.2 Headless para Linux
RUN curl -sSL -o /tmp/godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip \
    && unzip /tmp/godot.zip -d /usr/local/bin/ \
    && mv /usr/local/bin/Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

WORKDIR /app
COPY RelicArena /app/RelicArena

ENV PORT=8910
EXPOSE 8910

CMD ["/usr/local/bin/godot", "--headless", "--path", "/app/RelicArena", "-s", "res://server/dedicated_server.gd"]
