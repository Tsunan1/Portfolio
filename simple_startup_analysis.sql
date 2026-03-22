-- SQL PORTFOLIO: Advanced Database Analysis
-- Comprehensive startup ecosystem analysis demonstrating complex SQL concepts

-- 1. COMPLEX SUBQUERIES & FILTERING
-- Find companies with above-average funding amounts
SELECT name, funding_total, status
FROM company 
WHERE funding_total > (
    SELECT AVG(funding_total) 
    FROM company 
    WHERE funding_total IS NOT NULL
)
ORDER BY funding_total DESC;

-- 2. NESTED SUBQUERIES WITH AGGREGATION
-- Calculate average employee count per industry for successful companies
SELECT AVG(Sub.employee_count) AS avg_employees_per_industry
FROM (
    SELECT category_code, COUNT(DISTINCT people.id) as employee_count
    FROM company 
    INNER JOIN people ON company.id = people.company_id
    WHERE company.status IN ('operating', 'acquired')
    GROUP BY category_code
) AS Sub;

-- 3. COMPLEX MULTI-TABLE JOINS WITH ADVANCED FILTERING
-- Analyze education levels of employees at failed vs successful startups
SELECT 
    c.status,
    COUNT(DISTINCT p.id) AS total_employees,
    COUNT(e.degree_type) AS total_degrees,
    ROUND(COUNT(e.degree_type) * 1.0 / COUNT(DISTINCT p.id), 2) AS avg_degrees_per_employee
FROM company c
INNER JOIN people p ON c.id = p.company_id
LEFT JOIN education e ON p.id = e.person_id
WHERE c.status IN ('closed', 'operating', 'acquired')
    AND c.id IN (
        SELECT company_id 
        FROM funding_round 
        WHERE is_first_round = 1 AND is_last_round = 1
    )
GROUP BY c.status
HAVING COUNT(DISTINCT p.id) > 5
ORDER BY avg_degrees_per_employee DESC;

-- 4. ADVANCED WINDOW FUNCTIONS & RANKING
-- Rank companies by funding within each category
SELECT 
    name,
    category_code,
    funding_total,
    RANK() OVER (PARTITION BY category_code ORDER BY funding_total DESC) as funding_rank,
    COUNT(*) OVER (PARTITION BY category_code) as companies_in_category
FROM company 
WHERE funding_total IS NOT NULL 
    AND category_code IS NOT NULL
ORDER BY category_code, funding_rank;

-- 5. COMPLEX DATE ANALYSIS & CONDITIONAL LOGIC
-- Analyze funding patterns by year with success indicators
SELECT 
    EXTRACT(YEAR FROM founded_at) as founding_year,
    COUNT(*) as total_companies,
    SUM(CASE WHEN status = 'operating' THEN 1 ELSE 0 END) as still_operating,
    SUM(CASE WHEN status = 'acquired' THEN 1 ELSE 0 END) as acquired,
    SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) as failed,
    ROUND(
        (SUM(CASE WHEN status IN ('operating', 'acquired') THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        1
    ) as success_rate_percent
FROM company 
WHERE founded_at IS NOT NULL
GROUP BY EXTRACT(YEAR FROM founded_at)
HAVING COUNT(*) >= 10
ORDER BY founding_year DESC;