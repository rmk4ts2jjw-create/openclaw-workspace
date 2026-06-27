#!/usr/bin/env python3
"""Quick peek at inbox - show subject + sender + date + preview for all emails."""

import imaplib
import email
from email.header import decode_header
import os

IMAP_SERVER = "imap.gmail.com"
IMAP_PORT = 993
USERNAME = "spacemonkeyopenclaw@gmail.com"

def get_password():
    pw = os.environ.get("GMAIL_APP_PASSWORD")
    if not pw:
        print("ERROR: Set GMAIL_APP_PASSWORD")
        exit(1)
    return pw

def decode_mime_header(header_value):
    if not header_value:
        return ""
    decoded_parts = decode_header(header_value)
    result = []
    for part, charset in decoded_parts:
        if isinstance(part, bytes):
            result.append(part.decode(charset or 'utf-8', errors='replace'))
        else:
            result.append(part)
    return " ".join(result)

def get_body_preview(msg):
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                try:
                    body = part.get_payload(decode=True).decode('utf-8', errors='replace')
                    break
                except:
                    pass
    else:
        try:
            body = msg.get_payload(decode=True).decode('utf-8', errors='replace')
        except:
            pass
    return body[:200].replace('\n', ' ').strip()

password = get_password()
mail = imaplib.IMAP4_SSL(IMAP_SERVER, IMAP_PORT)
mail.login(USERNAME, password)
mail.select("INBOX")

status, messages = mail.search(None, "ALL")
if status != "OK":
    print("Failed")
    exit()

email_ids = messages[0].split()
print(f"Total emails in inbox: {len(email_ids)}\n")

for email_id in reversed(email_ids):
    status, msg_data = mail.fetch(email_id, "(RFC822)")
    if status != "OK":
        continue
    msg = email.message_from_bytes(msg_data[0][1])
    subject = decode_mime_header(msg["Subject"]) or "(no subject)"
    sender = decode_mime_header(msg["From"]) or "(unknown)"
    date = msg["Date"] or "(no date)"
    body = get_body_preview(msg)
    print(f"{'='*70}")
    print(f"Date:   {date}")
    print(f"From:   {sender}")
    print(f"Subject: {subject}")
    print(f"Preview: {body}")
    print()

mail.logout()
