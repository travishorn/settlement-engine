import sqlite3
import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()

DB_NAME = "local.db"
NUM_ISSUERS = 8
NUM_ACQUIRERS = 6
DAYS_OF_HISTORY = 30
AVG_TXNS_PER_DAY = 150

CURRENCIES = ["USD", "GBP", "EUR", "CAD"]
COUNTRIES = {"USD": "USA", "GBP": "GBR", "EUR": "FRA", "CAD": "CAN"}

def generate_participants(cursor):
    issuer_ids = []
    acquirer_ids = []

    for _ in range(NUM_ISSUERS):
        currency = random.choice(CURRENCIES)
        country = COUNTRIES[currency]
        name = f"{fake.company()} Bank"
        
        cursor.execute(
            "INSERT INTO issuers (institution_name, country_code, base_currency) VALUES (?, ?, ?)",
            (name, country, currency)
        )
        issuer_ids.append(cursor.lastrowid)

    for _ in range(NUM_ACQUIRERS):
        currency = random.choice(CURRENCIES)
        country = COUNTRIES[currency]
        name = f"{fake.company()} Merchant Services"
        
        cursor.execute(
            "INSERT INTO acquirers (institution_name, country_code, base_currency) VALUES (?, ?, ?)",
            (name, country, currency)
        )
        acquirer_ids.append(cursor.lastrowid)
        
    return issuer_ids, acquirer_ids

def generate_traffic(cursor, issuer_ids, acquirer_ids):
    end_date = datetime.now()
    start_date = end_date - timedelta(days=DAYS_OF_HISTORY)
    
    total_txns = 0
    
    for day in range(DAYS_OF_HISTORY + 1):
        current_date = (start_date + timedelta(days=day)).strftime('%Y-%m-%d')
        
        # Randomize volume per day
        daily_vol = random.randint(int(AVG_TXNS_PER_DAY * 0.8), int(AVG_TXNS_PER_DAY * 1.2))
        
        for _ in range(daily_vol):
            issuer = random.choice(issuer_ids)
            acquirer = random.choice(acquirer_ids)
            
            # Give the statuses some weight. Most are settled.
            status = random.choices(
                ['SETTLED', 'CLEARED', 'DECLINED', 'DISPUTED'], 
                weights=[85, 10, 4, 1], k=1
            )[0]
            
            # Amounts between 5.00 and 500.00
            amount = round(random.uniform(5.00, 500.00), 2)
            currency = random.choice(CURRENCIES)
            
            cursor.execute('''
                INSERT INTO transactions 
                (txn_date, amount_local, currency_local, issuer_id, acquirer_id, status)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (current_date, amount, currency, issuer, acquirer, status))

            txn_id = cursor.lastrowid
            
            # Generate Fees for Settled transactions
            if status == 'SETTLED':
                # Fee = base fee + cross border fee if currencies don't match
                # Using 1.5% interchange fee
                fee_val = round(amount * 0.015, 2)
                if fee_val < 0.05: fee_val = 0.05 # Minimum fee
                
                cursor.execute('''
                    INSERT INTO interchange_fees (transaction_id, fee_amount, payer_entity)
                    VALUES (?, ?, ?)
                ''', (txn_id, fee_val, "ACQUIRER"))
            
            total_txns += 1

def main():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    try:
        issuers, acquirers = generate_participants(cursor)
        
        generate_traffic(cursor, issuers, acquirers)
        
        conn.commit()
        
    except Exception as e:
        print(f"An error occurred: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    main()
