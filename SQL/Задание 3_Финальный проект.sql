WITH age_segments AS (
    SELECT 
        Id_client,
        CASE 
            WHEN Age IS NULL THEN 'Unknown'
            ELSE CONCAT(FLOOR(Age / 10) * 10, '-', FLOOR(Age / 10) * 10 + 9)
        END AS age_group
    FROM customers
),

base_data AS (
    SELECT 
        t.Id_check,
        t.Sum_payment,
        s.age_group,
        QUARTER(t.date_new) AS qr,
        YEAR(t.date_new) AS yr
    FROM transactions t
    LEFT JOIN age_segments s ON t.ID_client = s.Id_client
    WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
),

quarterly_stats AS (
    SELECT 
        age_group,
        yr,
        qr,
        COUNT(Id_check) AS q_ops,
        SUM(Sum_payment) AS q_sum,
        SUM(COUNT(Id_check)) OVER(PARTITION BY age_group) AS total_ops_period, -- Общие показатели за весь период по группе (через окно)
        SUM(SUM(Sum_payment)) OVER(PARTITION BY age_group) AS total_sum_period
    FROM base_data
    GROUP BY age_group, yr, qr
)

SELECT 
    age_group,
    CONCAT(yr, '-Q', qr) AS quarter,
    -- Показатели за весь период
    total_ops_period AS full_period_ops,
    total_sum_period AS full_period_sum,
    -- Поквартальные показатели
    q_ops AS q_ops_count,
    q_sum AS q_sum_amount,
    -- Средние показатели (на одну операцию внутри квартала)
    q_sum / q_ops AS q_avg_check,
    -- % доли квартала от всего периода для этой группы
    (q_ops / total_ops_period) * 100 AS q_ops_share_pct,
    (q_sum / total_sum_period) * 100 AS q_sum_share_pct
FROM quarterly_stats
ORDER BY age_group, yr, qr;