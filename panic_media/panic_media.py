import subprocess
from pathlib import Path
from datetime import datetime
import os
import socket

LOG = Path.home() / "panic_media.log"
def log(message):
    with LOG.open("a") as f:
        f.write(f"{datetime.now()} - {message}\n")

def close_vlc():
    subprocess.run(
        ["/usr/bin/pkill", "-x", "vlc"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

def trigger_firefox_panic():
    socket_path = os.path.join(
        os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
        "panic_media.sock",
    )
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.connect(socket_path)
            sock.sendall(b"panic")
    except (FileNotFoundError, ConnectionRefusedError):
        # Firefox/native host isn't running.
        pass

def main():
    close_vlc()
    trigger_firefox_panic()

if __name__ == "__main__":
    main()
