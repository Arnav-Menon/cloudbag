import os
import json
import requests
from datetime import datetime
import smtplib
from email.mime.text import MIMEText
from files.emailConfig import login

# Email configuration (for sending the report)
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587                        # Typically 587 (TLS) or 465 (SSL)
EMAIL_USERNAME = login["username"]
EMAIL_PASSWORD = login["password"]
ADMIN_EMAIL = ["arnavmen@andrew.cmu.edu", "ssridha3@andrew.cmu.edu"]

def get_report():
    today_date = datetime.today().strftime('%Y%m%d')
    output_dir = f"/home/ubuntu/code/files/output_local_{today_date}"
    file_path = os.path.join(output_dir, "part-00000")

    parsed_data = []
    with open(file_path, "r") as f:
      for line in f:
        parts = line.strip().split("\t")
        if len(parts) == 2:
          key, value = parts
          parsed_data.append((key, value))
        elif len(parts) == 3:
          key, name, value = parts
          parsed_data.append((key, name, value))

    return parsed_data

def send_mail(report):
    """
    Sends the generated report via email to the admin.
    """
    if not report:
        formatted_report = "No data available."
    else:
        formatted_report = "Daily Hadoop Report\n\n"
        for item in report:
            if len(item) == 2:
                key, value = item
                formatted_report += f"**{key.replace('_', ' ').title()}**: {value}\n"
            elif len(item) == 3:
                key, name, value = item
                photo_list = "\n - ".join(value.split(", "))  # Format the list of UUIDs
                formatted_report += f"**{key.replace('_', ' ').title()} ({name})**:\n - {photo_list}\n\n"

    msg = MIMEText(formatted_report, "plain")  # Use plain text format
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
        raise Exception(f" Failed to send email: {e}")


def main():
    try:
      report = get_report()
      send_mail(report)
    except Exception as e:
      print("An error occurred:", e)


if __name__ == "__main__":
    main()