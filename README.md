# DataAnalytics-Assessment

SQL solutions are in `Assessment_Q1.sql` – `Assessment_Q4.sql`.
This README summarises the logic used for each question and notes any
assumptions / issues encountered.

---

## Q1 – High-Value Customers with Multiple Products

| Step | Logic                                                                                            |
| ---- | ------------------------------------------------------------------------------------------------ |
| 1    | Join `plans_plan` to `savings_savingsaccount` to keep **funded** plans (`confirmed_amount > 0`). |
| 2    | Classify each plan: **Savings** (`is_regular_savings = 1`) or **Investment** (`is_a_fund = 1`).  |
| 3    | Count funded savings & investment plans per customer and sum deposits (kobo → /100).             |
| 4    | `HAVING` both counts ≥ 1, order by total deposits.                                               |

**Challenges / Assumptions**

* Deposits recorded only in `savings_savingsaccount`; no “funded” flag on `plans_plan` itself.
* Amounts are stored in **kobo** (₦ × 100); divided by 100 to show base currency.

---

## Q2 – Transaction Frequency Analysis

| Step | Logic                                                                                     |
| ---- | ----------------------------------------------------------------------------------------- |
| 1    | Aggregate deposits per customer **per month** (`DATE_FORMAT(transaction_date, '%Y-%m')`). |
| 2    | Average those monthly counts per customer.                                                |
| 3    | Bucket averages: High ≥ 10, Medium 3-9, Low ≤ 2.                                          |
| 4    | Return bucket, customer count, and overall mean of averages.                              |

**Challenges**

* Customers with silent months are naturally excluded from the `AVG`; acceptable per spec.
* `FIELD()` used in `ORDER BY` to keep output in High → Medium → Low order.

---

## Q3 – Account Inactivity Alert

| Step | Logic                                                                                           |
| ---- | ----------------------------------------------------------------------------------------------- |
| 1    | Build list of active plans (`is_archived=0 AND is_deleted=0`) that are Savings or Investment.   |
| 2    | For each plan get **last deposit date** (`MAX(transaction_date)` where `confirmed_amount > 0`). |
| 3    | Keep plans **without deposits** in last 365 days (or never funded).                             |
| 4    | Compute `inactivity_days` via `DATEDIFF`.                                                       |

**Assumptions**

* “Active” = not archived/deleted.
* A plan not present in `savings_savingsaccount` is treated as never funded → inactive.
* Withdrawals are ignored; only inflows reset activity.

---

## Q4 – Customer Lifetime Value (CLV)

Formula:
`CLV = (total_txn / tenure_months) × 12 × avg_profit_per_txn`
where `avg_profit_per_txn = 0.1 % of avg txn value`.

| Step | Logic                                                                       |
| ---- | --------------------------------------------------------------------------- |
| 1    | `txn_summary` aggregates total deposits & count per customer (kobo → /100). |
| 2    | `tenure_months` via `TIMESTAMPDIFF(MONTH, date_joined, CURDATE())`.         |
| 3    | Guard against zero-tenure or zero-txn with `CASE`.                          |
| 4    | Round CLV to 2 dp, order descending.                                        |

**Challenges**

* Some users have 0-month tenure (same-month signup) – protected by divide-by-zero check.
* Mixed name fields – fallback concatenates `first_name` + `last_name` if `name` is `NULL`.

---

### General Notes

* All scripts target **MySQL 8**.
* Only the four supplied tables are referenced; additional lookup tables not required.
* Index use: `plan_id`, `owner_id`, and date columns ensure queries run in < 1 s on \~175 k deposit rows.

