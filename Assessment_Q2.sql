/*---------------------------------------------------------------

1. For every customer, compute the average number of deposits
   per month** (based on `savings_savingsaccount.transaction_date`).
2. Bucket customers by that average:
     • High Frequency   ≥ 10 txns / month
     • Medium Frequency 3-9 txns / month
     • Low Frequency    ≤ 2 txns / month
3. Return, for each bucket:
     frequency_category , customer_count, avg_transactions_per_month
--------------------------------------------------------------------*/

WITH monthly_counts AS (                 -- deposits per owner per YYYY-MM
    SELECT
        owner_id,
        DATE_FORMAT(transaction_date,'%Y-%m')  AS yr_mo,
        COUNT(*)                               AS txns_this_month
    FROM savings_savingsaccount
    GROUP BY owner_id, yr_mo
),
avg_per_customer AS (                     -- average deposits per month
    SELECT
        owner_id,
        AVG(txns_this_month) AS avg_txn_per_month
    FROM monthly_counts
    GROUP BY owner_id
)

SELECT
    CASE
        WHEN avg_txn_per_month >= 10            THEN 'High Frequency'
        WHEN avg_txn_per_month BETWEEN 3 AND 9  THEN 'Medium Frequency'
        ELSE                                         'Low Frequency'
    END                                   AS frequency_category,
    COUNT(*)                              AS customer_count,
    ROUND(AVG(avg_txn_per_month),1)       AS avg_transactions_per_month
FROM avg_per_customer
GROUP BY frequency_category
ORDER BY FIELD(frequency_category,
               'High Frequency','Medium Frequency','Low Frequency');

