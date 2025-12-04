DROP TABLE IF EXISTS feature_mart_attrition_90d;

CREATE TABLE feature_mart_attrition_90d AS
WITH base_features AS (
    SELECT
        em."Employee_ID",
        em."Job_Role",
        em."Job_Level",
        em."Monthly_Base_Salary",
        -- 4. Calculate Tenure (Years at Company)
        EXTRACT(DAY FROM ('2025-07-01'::DATE - em."Hire_Date")) / 365.25 AS tenure_years,
        -- Create the Target Variable (1 if terminated in the 90 days following 2025-07-01)
        CASE
            WHEN em."Termination_Date" BETWEEN '2025-07-01'::DATE AND '2025-09-29'::DATE
            THEN 1
            ELSE 0
        END AS target_attrition
    FROM
        employee_master em
)
-- Create the initial mart table structure
SELECT * FROM base_features;

-- Add a primary key for efficient joins later
ALTER TABLE feature_mart_attrition_90d ADD PRIMARY KEY ("Employee_ID");

ALTER TABLE feature_mart_attrITION_90d ADD COLUMN salary_gap_vs_peer NUMERIC;

-- Use a CTE (Common Table Expression) to calculate the peer average FIRST.
WITH peer_averages AS (
    SELECT
        "Job_Role",
        "Job_Level",
        -- Calculate the average salary for each unique peer group
        AVG("Monthly_Base_Salary") AS peer_avg_salary 
    FROM
        employee_master
    GROUP BY 1, 2 -- Group by Role and Level
)
-- Now, update the feature mart by joining the individual salary to the group average.
UPDATE feature_mart_attrition_90d fm
SET salary_gap_vs_peer = em."Monthly_Base_Salary" - pa.peer_avg_salary
FROM employee_master em
JOIN peer_averages pa
    -- FIX: Join the employee to their calculated peer average group
    ON em."Job_Role" = pa."Job_Role" 
    AND em."Job_Level" = pa."Job_Level"
WHERE fm."Employee_ID" = em."Employee_ID";

ALTER TABLE feature_mart_attrition_90d ADD COLUMN avg_ot_hours_day NUMERIC;

-- Join the timesheet data and calculate the daily average
UPDATE feature_mart_attrition_90d fm
SET avg_ot_hours_day = td."Total_OT_Hours_90_Days" / 90.0
FROM timesheet_data td
WHERE fm."Employee_ID" = td."Employee_ID";

-- Add the new column (Assuming 'years_since_last_promo' was correctly created in lowercase)
ALTER TABLE feature_mart_attrition_90d ADD COLUMN years_since_last_promo NUMERIC;

WITH ranked_promotions AS (
    SELECT
        -- FIX: Quote capitalized column names from the source table
        "Employee_ID",
        "Promotion_Date",
        -- Rank promotions for each employee, most recent is rank 1
        ROW_NUMBER() OVER (PARTITION BY "Employee_ID" ORDER BY "Promotion_Date" DESC) as rn
    FROM
        promotion_history -- Table name is usually lowercase by default unless explicitly quoted
    WHERE
        "Promotion_Date" < '2025-07-01'::DATE -- FIX: Quote column name
),
latest_promo AS (
    SELECT
        "Employee_ID" AS employee_id_fix, -- Use an alias for clarity in the join
        "Promotion_Date" AS last_promo_date -- Use an alias for clarity in the calculation
    FROM
        ranked_promotions
    WHERE
        rn = 1
)
-- Update the mart with the calculated YSLP
UPDATE feature_mart_attrition_90d fm
SET years_since_last_promo = EXTRACT(DAY FROM ('2025-07-01'::DATE - lp.last_promo_date)) / 365.25
FROM latest_promo lp
-- FIX: Match the corrected source column ('employee_id_fix') to the lowercase target column ('employee_id')
WHERE fm."Employee_ID" = lp.employee_id_fix;

-- IMPUTATION: For employees with NO promotion history (NULL YSLP), set YSLP = Tenure
UPDATE feature_mart_attrition_90d
SET years_since_last_promo = tenure_years
-- FIX: Ensure 'tenure_years' is referenced in the case it was created (likely lowercase)
WHERE years_since_last_promo IS NULL;

ALTER TABLE feature_mart_attrition_90d ADD COLUMN last_perf_rating NUMERIC;

WITH ranked_ratings AS (
    SELECT
        "Employee_ID",
        "Rating_Score",
        -- Rank ratings for each employee, most recent is rank 1
        ROW_NUMBER() OVER (PARTITION BY "Employee_ID" ORDER BY "Review_Date" DESC) as rn
    FROM
        performance_data
    WHERE
        "Review_Date" < '2025-07-01'::DATE -- Only look at past reviews
)
-- Update the mart with the rating score
UPDATE feature_mart_attrition_90d fm
SET last_perf_rating = rr."Rating_Score"
FROM ranked_ratings rr
WHERE fm."Employee_ID" = rr."Employee_ID" AND rr.rn = 1;

-- Final Result Check:
SELECT * FROM feature_mart_attrition_90d;


