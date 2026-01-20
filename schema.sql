CREATE TABLE issuers (
  issuer_id INTEGER PRIMARY KEY AUTOINCREMENT,
  institution_name TEXT NOT NULL,
  country_code TEXT NOT NULL,
  base_currency TEXT NOT NULL
);

CREATE TABLE acquirers (
  acquirer_id INTEGER PRIMARY KEY AUTOINCREMENT,
  institution_name TEXT NOT NULL,
  country_code TEXT NOT NULL,
  base_currency TEXT NOT NULL
);

CREATE TABLE transactions (
  transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
  txn_date TEXT NOT NULL,
  amount_local REAL NOT NULL,
  currency_local TEXT NOT NULL,
  issuer_id INTEGER,
  acquirer_id INTEGER,
  status TEXT CHECK(status IN ('CLEARED', 'SETTLED', 'DECLINED', 'DISPUTED')),
  FOREIGN KEY(issuer_id) REFERENCES issuers(issuer_id),
  FOREIGN KEY(acquirer_id) REFERENCES acquirers(acquirer_id)
);

CREATE TABLE interchange_fees (
  fee_id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER,
  fee_amount REAL NOT NULL,
  payer_entity TEXT CHECK(payer_entity IN ('ISSUER', 'ACQUIRER')),
  FOREIGN KEY(transaction_id) REFERENCES transactions(transaction_id)
);
