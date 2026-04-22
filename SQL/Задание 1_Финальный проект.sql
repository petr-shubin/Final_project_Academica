WITH base_stats AS (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS month_id, -- Меняю формат даты на Год - Месяц для удобства
        COUNT(Id_check) AS monthly_ops, -- Считаю количество чеков (если подразумевать, что 1 чек это 1 операция)
        SUM(Sum_payment) AS monthly_sum -- Считаю сумму продаж по кленту за месяц.
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01' -- Хоть в таблице временой период ровно такой же как и в условии, все равно фильрую по этому периоду, что бы не было ошибок
    GROUP BY ID_client, month_id
),
windowed_stats AS (
    SELECT 
        *,
        COUNT(*) OVER(PARTITION BY ID_client) AS active_months_count, -- Считаю количество активных месяцев по клиенту
        SUM(monthly_sum) OVER(PARTITION BY ID_client) AS total_year_sum, -- Считаю считаю сумму продаж за год по клиету
        SUM(monthly_ops) OVER(PARTITION BY ID_client) AS total_year_ops -- Счиатаю количество операций за год по клиету
    FROM base_stats
)
SELECT 
    ID_client,
    month_id,
    monthly_ops,
    TRUNCATE(monthly_sum, 2) AS monthly_sum,
    total_year_ops,
    TRUNCATE(total_year_sum / 12, 2) AS avg_monthly_payment, -- Считаю среднею сумму продаж за месяц
    TRUNCATE(total_year_sum / total_year_ops, 2) AS avg_check_year -- Считаю среднею чек клиента за год
FROM windowed_stats
WHERE active_months_count = 12 -- Отфильтровываю только клиентов с непрерывной историей операций за год 
ORDER BY ID_client, month_id;