/* 
средняя сумма чека в месяц;
среднее количество операций в месяц;
среднее количество клиентов, которые совершали операции;
долю от общего количества операций за год и долю в месяц от общей суммы операций;
вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
*/ 

WITH monthly_raw AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month_id,
        c.Gender,
        COUNT(t.Id_check) AS count_ops,
        SUM(t.Sum_payment) AS sum_payment,
        COUNT(DISTINCT t.ID_client) AS count_users
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.Id_client
    WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
    GROUP BY month_id, c.Gender 
), 

calendar_info AS (
    SELECT COUNT(DISTINCT month_id) AS total_months FROM monthly_raw -- Считаю количество уникальных месяцев отдельно
),

monthly_totals AS (
    SELECT 
        r.*,
        SUM(count_ops) OVER() AS year_total_ops, -- Общие показатели за весь год
        SUM(sum_payment) OVER() AS year_total_amount,
        SUM(count_ops) OVER(PARTITION BY month_id) AS month_total_ops, -- Общие показатели за конкретный месяц (для долей M/F)
        SUM(sum_payment) OVER(PARTITION BY month_id) AS month_total_amount,
        (SELECT total_months FROM calendar_info) AS months_cnt -- Добавляем количество месяцев из CTE
    FROM monthly_raw r
)

SELECT 
    month_id,
    Gender,
    TRUNCATE(sum_payment / count_ops, 2) AS avg_check_monthly, -- 1. Средняя сумма чека в месяце (по конкретному полу)
    TRUNCATE(year_total_ops / months_cnt, 2) AS avg_ops_per_month_total, -- 2. Среднее кол-во операций в месяц (всего операций за год / кол-во месяцев)
    TRUNCATE(SUM(count_users) OVER() / months_cnt, 2) AS avg_clients_per_month, -- 3. Среднее кол-во клиентов в месяц (сумма всех уникальных клиентов помесячно / кол-во месяцев)
    TRUNCATE(count_ops / year_total_ops * 100, 2) AS share_of_year_ops_pct, -- 4. Доли
    TRUNCATE(sum_payment / month_total_amount * 100, 2) AS share_of_month_amount_pct,
    TRUNCATE(count_users / SUM(count_users) OVER(PARTITION BY month_id) * 100, 2) AS gender_ratio_pct -- 5. Соотношение по полу (количество клиентов этого пола / всего клиентов в этом месяце)
FROM monthly_totals
ORDER BY month_id, Gender;