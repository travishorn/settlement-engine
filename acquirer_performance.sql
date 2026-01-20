WITH DailyVolumes AS (
  -- Aggregate transaction data by acquirer and date
  SELECT 
    t.acquirer_id,
    a.institution_name,
    t.txn_date,
    SUM(t.amount_local) AS total_daily_volume,
    COUNT(t.transaction_id) AS txn_count
  FROM transactions t
  JOIN acquirers a ON t.acquirer_id = a.acquirer_id
  WHERE 
    t.status = 'SETTLED'
  GROUP BY 
    t.acquirer_id,
    t.txn_date
),
GrowthAnalysis AS (
  -- Compare against previous day and Rank
  SELECT 
    acquirer_id,
    institution_name,
    txn_date,
    total_daily_volume,
    -- Lag. Get the volume from the previous record for this specific acquirer
    LAG(total_daily_volume, 1, 0) OVER (
      PARTITION BY acquirer_id 
      ORDER BY txn_date
    ) AS previous_day_volume,
    -- Rank acquirers by volume for each specific day
    RANK() OVER (
      PARTITION BY txn_date 
      ORDER BY total_daily_volume DESC
    ) AS daily_rank
  FROM DailyVolumes
)
SELECT 
  institution_name,
  txn_date,
  total_daily_volume,
  previous_day_volume,
  daily_rank,
  -- Day-over-day growth
  CASE 
    WHEN previous_day_volume = 0 THEN 0 
    ELSE ROUND(((total_daily_volume - previous_day_volume) / previous_day_volume) * 100, 2) 
  END AS growth_percentage
FROM GrowthAnalysis
ORDER BY 
  txn_date DESC,
  daily_rank ASC;

/*

Sample output:

| institution_name                  | txn_date   | total_daily_volume | previous_day_volume | daily_rank | growth_percentage |
|-----------------------------------|------------|--------------------|---------------------|------------|-------------------|
| Robinson-Walker Merchant Services | 2026-01-20 |            7907.93 |             3642.64 |          1 |            117.09 |
| Beck-Aguilar Merchant Services    | 2026-01-20 |            6535.32 |             3479.21 |          2 |             87.84 |
| Ramirez-Sanchez Merchant Services | 2026-01-20 |            6156.76 |             1890.98 |          3 |            225.59 |
| Perez Group Merchant Services     | 2026-01-20 |            5169.90 |             3268.53 |          4 |             58.17 |
| Torres Ltd Merchant Services      | 2026-01-20 |            4520.12 |             5237.88 |          5 |             -13.7 |

*/