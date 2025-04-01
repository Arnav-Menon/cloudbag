import json
import requests
from datetime import datetime
import smtplib
from email.mime.text import MIMEText
from files.emailConfig import login

# Databag server configuration
DATABAG_BASE_URL = "http://10.10.0.146:7000"  # Replace with your actual Databag server IP/hostname and port

# If authentication is required, set your access token here
with open('/home/ubuntu/code/files/adminToken.txt') as f:
    ACCESS_TOKEN = f.read().strip()

# Email configuration (for sending the report)
SMTP_SERVER = "smtp.gmail.com"       # Replace with your SMTP server
SMTP_PORT = 587                        # Typically 587 (TLS) or 465 (SSL)
EMAIL_USERNAME = login["username"]  # Replace with your email username
EMAIL_PASSWORD = login["password"]       # Replace with your email password
ADMIN_EMAIL = ["arnavmen@andrew.cmu.edu", "ssridha3@andrew.cmu.edu"]      # Replace with the recipient's email address

def get_analytics(time_range="24h"):
    print("TOKEN:", ACCESS_TOKEN)
    if not ACCESS_TOKEN:
        print("Failed to get admin token")
        return
    
    try:
        url = f"{DATABAG_BASE_URL}/admin/analytics?token={ACCESS_TOKEN}"
        response = requests.get(url)

        with open("files/data.jsonl", "w") as f:
            f.write(response.text)

    except Exception as e:
        print(f"Error getting analytics: {e}")
        return None

def send_email(report):
    """
    Sends the generated report via email to the admin.
    """
    if isinstance(report, dict):
        report = json.dumps(report, indent=4)
    elif isinstance(report, list):
        report = "\n".join(str(item) for item in report)  # Convert list to string

    msg = MIMEText(report)
    msg["Subject"] = "Daily Hadoop Report"
    msg["From"] = EMAIL_USERNAME
    msg["To"] = ', '.join(ADMIN_EMAIL)

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_USERNAME, EMAIL_PASSWORD)
            server.send_message(msg)
            print("Email sent successfully!")
    except Exception as e:
        raise Exception(f"Failed to send email: {e}")


def main():
    try:
        get_analytics()
    except Exception as e:
        print("An error occurred:", e)


if __name__ == "__main__":
    main()