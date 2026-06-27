#!/usr/bin/env python3
"""
Bank Switch Deal Scanner
Scans spacemonkeyopenclaw@gmail.com inbox for bank switching confirmation emails.
Extracts bank name, switch date, and deal details.
Outputs a sorted table.
"""

import imaplib
import email
from email.header import decode_header
from datetime import datetime, timedelta
import re
import sys
import os

# Gmail IMAP settings
IMAP_SERVER = "imap.gmail.com"
IMAP_PORT = 993
USERNAME = "spacemonkeyopenclaw@gmail.com"

# Bank switching keywords to search for
BANK_KEYWORDS = [
    "hsbc", "barclays", "lloyds", "natwest", "santander", "nationwide",
    "tsb", "halifax", "first direct", "monzo", "starling", "chase",
    "m&s bank", "metro bank", "tesco bank", "virgin money", "co-operative bank",
    "bank of scotland", "ulster bank", "royal bank of scotland"
]

SWITCH_KEYWORDS = [
    "switch", "switching", "switched", "account switch",
    "current account switch", "bank switch", "moved to",
    "welcome to", "new account", "account opened",
    "switching incentive", "switch bonus", "switch reward",
    "£200", "£175", "£150", "£100", "cash incentive",
    "switch service", "current account guarantee"
]

def get_password():
    """Get password from environment variable."""
    pw = os.environ.get("GMAIL_APP_PASSWORD")
    if not pw:
        print("ERROR: Set GMAIL_APP_PASSWORD environment variable")
        sys.exit(1)
    return pw

def decode_mime_header(header_value):
    """Decode MIME encoded header."""
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

def get_email_body(msg):
    """Extract plain text body from email message."""
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            if content_type == "text/plain":
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
    return body

def extract_bank_name(text):
    """Extract bank name from email text."""
    text_lower = text.lower()
    found_banks = []
    for bank in BANK_KEYWORDS:
        if bank in text_lower:
            found_banks.append(bank.title() if bank != "m&s bank" else "M&S Bank")
    return found_banks

def extract_deal_amount(text):
    """Extract deal/cash incentive amount from email text."""
    amounts = re.findall(r'£(\d{2,4})', text)
    if amounts:
        return f"£{max(int(a) for a in amounts)}"
    # Also check for written amounts
    written = re.findall(r'(\d{2,4})\s*(?:pounds?|quid)', text.lower())
    if written:
        return f"£{max(int(a) for a in written)}"
    return None

def is_switch_email(subject, body, sender):
    """Determine if an email is related to bank switching."""
    combined = f"{subject} {body} {sender}".lower()
    
    has_bank = any(bank.lower() in combined for bank in BANK_KEYWORDS)
    has_switch = any(kw in combined for kw in SWITCH_KEYWORDS)
    
    return has_bank and has_switch

def scan_inbox():
    """Connect to Gmail and scan for bank switching emails."""
    password = get_password()
    
    print("🔌 Connecting to Gmail IMAP...")
    mail = imaplib.IMAP4_SSL(IMAP_SERVER, IMAP_PORT)
    mail.login(USERNAME, password)
    
    # Select inbox
    mail.select("INBOX")
    
    # Search for emails from the last 5 years
    since_date = (datetime.now() - timedelta(days=365*5)).strftime("%d-%b-%Y")
    status, messages = mail.search(None, f'SINCE {since_date}')
    
    if status != "OK":
        print("❌ Failed to search inbox")
        return []
    
    email_ids = messages[0].split()
    print(f"📧 Found {len(email_ids)} emails since {since_date}")
    print("🔍 Scanning for bank switching deals...\n")
    
    switch_deals = []
    
    for i, email_id in enumerate(email_ids):
        if i % 100 == 0 and i > 0:
            print(f"  ...processed {i}/{len(email_ids)} emails")
        
        status, msg_data = mail.fetch(email_id, "(RFC822)")
        if status != "OK":
            continue
        
        raw_email = msg_data[0][1]
        msg = email.message_from_bytes(raw_email)
        
        subject = decode_mime_header(msg["Subject"])
        sender = decode_mime_header(msg["From"])
        date_str = msg["Date"]
        
        # Parse date
        try:
            email_date = email.utils.parsedate_to_datetime(date_str)
        except:
            continue
        
        body = get_email_body(msg)
        
        if is_switch_email(subject, body, sender):
            banks = extract_bank_name(f"{subject} {body}")
            deal_amount = extract_deal_amount(f"{subject} {body}")
            
            for bank in banks:
                switch_deals.append({
                    "bank": bank,
                    "date": email_date,
                    "subject": subject[:80],
                    "sender": sender[:50],
                    "deal": deal_amount or "Unknown"
                })
    
    mail.logout()
    return switch_deals

def display_table(deals):
    """Display results as a formatted table."""
    if not deals:
        print("❌ No bank switching deals found in inbox.")
        return
    
    # Sort by date, most recent first
    deals.sort(key=lambda x: x["date"], reverse=True)
    
    # Deduplicate - keep most recent per bank
    seen_banks = {}
    unique_deals = []
    for deal in deals:
        bank = deal["bank"]
        if bank not in seen_banks:
            seen_banks[bank] = deal["date"]
            unique_deals.append(deal)
    
    print("=" * 90)
    print("🏦 BANK SWITCHING DEALS TRACKER")
    print("=" * 90)
    print(f"{'Bank':<20} {'Switch Date':<14} {'Deal':<10} {'Days Ago':<10} {'Eligible?':<10}")
    print("-" * 90)
    
    now = datetime.now()
    for deal in unique_deals:
        days_ago = (now - deal["date"]).days
        years_ago = days_ago / 365.25
        
        # Most bank switching offers have a 1-2 year exclusion period
        if years_ago >= 2:
            eligible = "✅ Yes"
        elif years_ago >= 1:
            eligible = "⚠️ Maybe"
        else:
            eligible = "❌ No"
        
        date_str = deal["date"].strftime("%d %b %Y")
        print(f"{deal['bank']:<20} {date_str:<14} {deal['deal']:<10} {days_ago:<10} {eligible:<10}")
    
    print("-" * 90)
    print(f"\n📊 Total unique bank switches found: {len(unique_deals)}")
    print("\n💡 Note: Most banks exclude you from switching offers for 1-2 years.")
    print("   '⚠️ Maybe' means it's been 1-2 years — check the specific bank's terms.")
    
    # Show all matches (including duplicates) count
    print(f"\n📧 Total matching emails: {len(deals)}")
    
    if len(deals) > len(unique_deals):
        print("\n📋 All matching emails (including follow-ups):")
        for deal in deals:
            date_str = deal["date"].strftime("%d %b %Y")
            print(f"  {date_str} | {deal['bank']:<18} | {deal['subject']}")

if __name__ == "__main__":
    deals = scan_inbox()
    display_table(deals)
