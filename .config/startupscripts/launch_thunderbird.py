import imaplib  # Added for a more robust IMAP server check
import socket
import subprocess
import sys
import time

import psutil  # You may need to install this library: pip install psutil

# --- Configuration ---
# The host and port for the local IMAP server provided by Proton Bridge.
IMAP_HOST = "127.0.0.1"
IMAP_PORT = 1143

# The name of the Proton Bridge process.
# On Windows, this might be 'protonmail-bridge.exe'.
# On macOS/Linux, it's typically 'protonmail-bridge'.
BRIDGE_PROCESS_NAME = "protonmail-bridge"

# The command to launch Thunderbird.
# You might need to change this to the full path of the Thunderbird executable
# depending on your operating system and installation.
# --- Examples ---
# Windows:
# THUNDERBIRD_COMMAND = r'C:\Program Files\Mozilla Thunderbird\thunderbird.exe'
# macOS:
# THUNDERBIRD_COMMAND = '/Applications/Thunderbird.app/Contents/MacOS/thunderbird'
# Linux (often in PATH):
THUNDERBIRD_COMMAND = "/usr/sbin/thunderbird"

# How many seconds to wait between checks.
CHECK_INTERVAL_SECONDS = 2

# How long to wait after a successful check before launching, to let the service settle.
FINAL_SETTLE_SECONDS = 6

# --- Script Logic ---


def is_process_running(process_name):
    """
    Checks if a process with the given name is currently running.
    This is case-insensitive.
    """
    for proc in psutil.process_iter(["name"]):
        if process_name.lower() in proc.info["name"].lower():
            return True
    return False


def is_imap_server_ready(host, port):
    """
    Checks if the IMAP server is fully ready by connecting and fetching
    server capabilities. This is a very reliable check and avoids using credentials.
    """
    mail = None  # Initialize to None
    try:
        # Set a short timeout for the connection attempt.
        imaplib.IMAP4.default_timeout = 5
        # 1. Connect to the server.
        mail = imaplib.IMAP4(host, port)
        # 2. Ask for capabilities. A fully ready server will respond.
        # This is a more robust check than just connecting.
        mail.capability()
        return True
    except (imaplib.IMAP4.error, ConnectionRefusedError, socket.timeout, OSError):
        # These errors are expected if the server isn't fully initialized.
        return False
    finally:
        # Ensure the connection is closed if it was successfully opened.
        if mail:
            try:
                # We use close() to terminate the connection. We don't use logout()
                # because we never authenticated.
                mail.close()
            except Exception:
                # Ignore errors on close, as the connection might already be dead.
                pass


def main():
    """
    Main function to check for Proton Bridge and launch Thunderbird.
    """
    print("--- Thunderbird Launcher for Proton Bridge ---")

    while True:
        print("Checking status...")

        # 1. Check if the Proton Bridge process is running.
        bridge_running = is_process_running(BRIDGE_PROCESS_NAME)

        if not bridge_running:
            print(f"-> Proton Bridge process ('{BRIDGE_PROCESS_NAME}') is not running.")
            print(f"   Waiting for {CHECK_INTERVAL_SECONDS} seconds to re-check...")
            time.sleep(CHECK_INTERVAL_SECONDS)
            continue  # Go to the next loop iteration

        print("-> Proton Bridge process is running.")

        # 2. Check if the IMAP server is fully initialized and ready.
        server_ready = is_imap_server_ready(IMAP_HOST, IMAP_PORT)

        if not server_ready:
            print(f"-> IMAP server at {IMAP_HOST}:{IMAP_PORT} is not fully ready yet.")
            print(f"   Waiting for {CHECK_INTERVAL_SECONDS} seconds to re-check...")
            time.sleep(CHECK_INTERVAL_SECONDS)
            continue  # Go to the next loop iteration

        # If both checks pass, we can break the loop.
        print(f"-> IMAP server at {IMAP_HOST}:{IMAP_PORT} is ready for connections.")
        print("\nProton Bridge is ready!")
        break

    # Add a final, short delay to allow the service to settle completely.
    if FINAL_SETTLE_SECONDS > 0:
        print(
            f"Waiting a final {FINAL_SETTLE_SECONDS} second(s) for the bridge to settle..."
        )
        time.sleep(FINAL_SETTLE_SECONDS)

    print("Launching Thunderbird...")
    try:
        # Use Popen to launch Thunderbird as a separate, non-blocking process.
        # This allows the Python script to exit while Thunderbird remains open.
        subprocess.Popen(THUNDERBIRD_COMMAND)
        print("Thunderbird has been launched successfully.")
    except FileNotFoundError:
        print("\n--- ERROR ---")
        print(f"Could not find the Thunderbird executable at: '{THUNDERBIRD_COMMAND}'")
        print("Please update the 'THUNDERBIRD_COMMAND' variable in this script")
        print("with the full path to your Thunderbird application and try again.")
        # Wait for user to see the message before exiting
        input("Press Enter to exit.")
    except Exception as e:
        print(f"\nAn unexpected error occurred while trying to launch Thunderbird: {e}")
        input("Press Enter to exit.")


if __name__ == "__main__":
    main()
