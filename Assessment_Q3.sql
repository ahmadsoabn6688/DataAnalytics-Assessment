/*--------------------------------------------------------------------
-----------
• “Savings”      → plans_plan.is_regular_savings = 1
• “Investment”   → plans_plan.is_a_fund          = 1
• “Active plan”  → NOT archived / deleted
                  (is_archived = 0  AND  is_deleted = 0)
• “Inflow txn”   → savings_savingsaccount rows
                  with confirmed_amount > 0         deposit
--------------------------------------------------------------------*/

WITH plan_base AS (              -- All active Savings / Investment plans
    SELECT
        id           AS plan_id,
        owner_id,
        CASE
            WHEN is_regular_savings = 1 THEN 'Savings'
            WHEN is_a_fund          = 1 THEN 'Investment'
        END        AS type
    FROM plans_plan
    WHERE (is_regular_savings = 1 OR is_a_fund = 1)
      AND is_archived = 0
      AND is_deleted  = 0
),
last_inflow AS (                    -- Most-recent deposit per plan
    SELECT
        plan_id,
        MAX(transaction_date) AS last_txn
    FROM savings_savingsaccount
    WHERE confirmed_amount > 0
    GROUP BY plan_id
)

SELECT
    pb.plan_id,
    pb.owner_id,
    pb.type,
    li.last_txn                       AS last_transaction_date,
    DATEDIFF(CURDATE(), li.last_txn)  AS inactivity_days
FROM plan_base  pb
LEFT JOIN last_inflow li
       ON li.plan_id = pb.plan_id
WHERE  li.last_txn IS NULL                            -- never funded
    OR li.last_txn < DATE_SUB(CURDATE(), INTERVAL 365 DAY)
ORDER BY inactivity_days DESC, pb.plan_id;

