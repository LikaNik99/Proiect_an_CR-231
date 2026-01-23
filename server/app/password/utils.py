from passlib.context import CryptContext
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
from fastapi import HTTPException
import os
import logging

try:
    from dotenv import load_dotenv

    load_dotenv()
except Exception as e:
    logging.warning(f"Could not load .env: {e}")

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


def hash_password(pwd: str):
    return pwd_context.hash(pwd)


SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
FROM_EMAIL = os.getenv("FROM_EMAIL", SMTP_USER)


async def send_email(to: str, subject: str, message: str, html_template: str = None):
    if not SMTP_USER or not SMTP_PASSWORD:
        raise HTTPException(status_code=500, detail="SMTP credentials are missing")

    to = to.strip().lower()

    try:
        email = MIMEMultipart("alternative")
        email["From"] = FROM_EMAIL or SMTP_USER
        email["To"] = to
        email["Subject"] = Header(subject, "utf-8")

        txt_part = MIMEText(message, "plain", "utf-8")
        email.attach(txt_part)
        if html_template:
            html_part = MIMEText(html_template, "html", "utf-8")
        else:
            html_part = MIMEText(f"""
            <html>
            <body>
                <p>{message}</p>
            </body>
            </html>
            """, "html", "utf-8")
        email.attach(html_part)

        await aiosmtplib.send(
            email,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            start_tls=True,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            timeout=5
        )

        logging.info(f"Email sent to {to}")

    except Exception as e:
        logging.error(f"Email error: {e}")
        raise HTTPException(status_code=500, detail="Could not send email")
