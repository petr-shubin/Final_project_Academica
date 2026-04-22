CREATE TABLE user_ad_metrics (
    event_date DATE,
    user_id VARCHAR(50) NOT NULL,         
    view_adverts INT
);

CREATE TABLE ab_test (
	experiment_num INT,
    experiment_group VARCHAR(10),
    user_id INT,
    revenue INT
);

CREATE TABLE listers (
	user_id INT,
	date DATE,
    cnt_adverts INT,
    age INT,
    cnt_contacts INT,
    revenue INT
);



-- 1.MAU продукта
SELECT 
    COUNT(DISTINCT user_id) AS mau
FROM user_ad_metrics
WHERE MONTH(event_date) = 11;

-- 2.DAU продукта
SELECT 
	AVG(dau) AS average_daily_active_users
FROM(
	SELECT 
		COUNT(DISTINCT user_id) AS dau
	FROM user_ad_metrics
	GROUP BY event_date
	ORDER BY event_date) AS daily_counts
;

-- 3.Retention первого дня
WITH user_first_day AS (
    SELECT 
        user_id, 
        MIN(event_date) as first_date
    FROM user_ad_metrics
    GROUP BY user_id
),
cohort_nov_1 AS (
    SELECT user_id
    FROM user_first_day
    WHERE first_date = '2023-11-01'
)
SELECT 
    COUNT(DISTINCT m.user_id) AS returned_users,
    (SELECT COUNT(*) FROM cohort_nov_1) AS total_users,
    COUNT(DISTINCT m.user_id) / (SELECT COUNT(*) FROM cohort_nov_1) * 100 AS retention_d1_percent
FROM user_ad_metrics m
JOIN cohort_nov_1 c ON m.user_id = c.user_id
WHERE m.event_date = '2023-11-02';

-- 5.Пользовательская конверсия
SELECT 
    COUNT(DISTINCT CASE WHEN view_adverts > 0 THEN user_id END) AS users_with_views,
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN view_adverts > 0 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id) AS conversion_rate
FROM user_
ad_metrics
WHERE event_date BETWEEN '2023-11-01' AND '2023-11-30';

-- 6.Средние колическо показов на пользователя
SELECT
    SUM(view_adverts) / COUNT(DISTINCT user_id) AS avg_views_per_user
FROM user_ad_metrics;

-- 9. Cредний доход на пользователя
SELECT 
     SUM(revenue) / COUNT(DISTINCT user_id) AS ARPU
FROM listers; 

-- 10. Медианный возраст
SELECT AVG(age) AS median
FROM (
    SELECT age,
           ROW_NUMBER() OVER (ORDER BY age) as row_id,
           COUNT(*) OVER () as total_count
    FROM listers
) AS subquery
WHERE row_id IN (FLOOR((total_count + 1) / 2), CEIL((total_count + 1) / 2));