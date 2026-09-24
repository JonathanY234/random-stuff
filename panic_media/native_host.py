#!/usr/bin/env python3

import json
import os
import socket
import struct
import sys
import threading

SOCKET_PATH = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
    "panic_media.sock",
)

# Configure what the panic command does.
#
# Use:
#     "close_audible"  - close all audible Firefox tabs
#     "close_urls"     - close tabs whose URLs contain one of the strings below
MODE = "close_urls"

URL_MATCHES = [
    "youtube.com",
    "chatgpt.com",
    "reddit.com",
]

def send_message(message):
    encoded = json.dumps(message, separators=(",", ":")).encode("utf-8")
    length = struct.pack("@I", len(encoded))

    sys.stdout.buffer.write(length)
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()

def panic_listener():
    # Remove an old socket file if one exists.
    try:
        os.unlink(SOCKET_PATH)
    except FileNotFoundError:
        pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen(1)

    while True:
        connection, _ = server.accept()

        with connection:
            message = connection.recv(1024).decode("utf-8")

            if message == "panic":
                send_message({
                    "command": MODE,
                    "urls": URL_MATCHES,
                })

# Start the Unix socket listener in the background.
threading.Thread(
    target=panic_listener,
    daemon=True,
).start()

# Keep the native messaging host alive.
while True:
    data = sys.stdin.buffer.read(1)

    if not data:
        break
