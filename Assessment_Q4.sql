/*──────────────────────────────────────────────────────────────────────────

profit_per_txn = 0.1 % of transaction value
avg_profit_per_txn  = (total_value / total_txn) * 0.001          -- 0.1 %
tenure_months       = months between signup (date_joined) & today
CLV                 = (total_txn / tenure_months) * 12 * avg_profit_per_txn

Amounts in savings_savingsaccount.confirmed_amount are kobo;
divide by 100 to convert to base currency before profit calc.
──────────────────────────────────────────────────────────────────────────*/

WITH txn_summary AS (              -- total txns & value per customer
    SELECT
        owner_id,
        COUNT(*)                                    AS total_txn,
        SUM(confirmed_amount) / 100                 AS total_value_base   -- kobo → base
    FROM savings_savingsaccount
    GROUP BY owner_id
)

SELECT
    u.id  AS customer_id,
    COALESCE(u.name,
             CONCAT_WS(' ', u.first_name, u.last_name),
             '(n/a)')                               AS name,

    TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())  AS tenure_months,

    COALESCE(t.total_txn, 0)                        AS total_transactions,

    ROUND(
        CASE
            WHEN t.total_txn IS NULL
              OR t.total_txn = 0
              OR TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) = 0
            THEN 0
            ELSE
                -- (txns / tenure) × 12 × avg profit per txn
                (t.total_txn
                  / TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())
                ) * 12
                * ((t.total_value_base / t.total_txn) * 0.001)
        END,
        2
    )                                              AS estimated_clv
FROM users_customuser        AS u
LEFT JOIN txn_summary        AS t  ON t.owner_id = u.id
ORDER BY estimated_clv DESC;

