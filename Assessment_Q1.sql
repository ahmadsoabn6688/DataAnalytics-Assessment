/*--------------------------------------------------------------------
High-Value Customers = customers that own
  • ≥ 1 funded “Savings” plan        →  plans_plan.is_regular_savings = 1
  • ≥ 1 funded “Investment” plan     →  plans_plan.is_a_fund         = 1
“Funded” means the plan has at least one deposit
  recorded in savings_savingsaccount with confirmed_amount > 0.

Amounts are stored in kobo, so we divide by 100 to show base currency.
--------------------------------------------------------------------*/
WITH deposits_per_plan AS (                       -- each plan’s funded deposits
    SELECT
        p.id                   AS plan_id,
        p.owner_id,
        p.is_regular_savings,
        p.is_a_fund,
        SUM(s.confirmed_amount) AS deposit_kobo
    FROM plans_plan              AS p
    JOIN savings_savingsaccount  AS s
          ON s.plan_id = p.id
    WHERE s.confirmed_amount > 0                   -- funded only
    GROUP BY p.id, p.owner_id,
             p.is_regular_savings, p.is_a_fund
),
customer_rollup AS (                              -- counts & totals per customer
    SELECT
        owner_id,
        COUNT(CASE WHEN is_regular_savings = 1 THEN plan_id END) AS savings_count,
        COUNT(CASE WHEN is_a_fund          = 1 THEN plan_id END) AS investment_count,
        SUM(deposit_kobo)                                        AS total_kobo
    FROM deposits_per_plan
    GROUP BY owner_id
)
SELECT                                             -- final required columns
    u.id                                                                  AS owner_id,
    COALESCE(u.name, CONCAT_WS(' ', u.first_name, u.last_name), '(n/a)')  AS name,
    cr.savings_count,
    cr.investment_count,
    ROUND(cr.total_kobo / 100, 2)                                         AS total_deposits
FROM customer_rollup  cr
JOIN users_customuser u
      ON u.id = cr.owner_id
WHERE cr.savings_count    >= 1                 -- must have both products
  AND cr.investment_count >= 1
ORDER BY total_deposits DESC;

