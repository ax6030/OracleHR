-- =============================================================
-- Oracle MATERIALIZED VIEW 示範
-- 預先計算並快取查詢結果，報表查詢效能大幅提升
-- 可設定自動刷新（定時 or 資料變動時）
-- =============================================================

-- ── MV 1：月薪資彙總報表 ──────────────────────────────────
-- BUILD IMMEDIATE：立即建立；REFRESH COMPLETE：完整刷新（vs FAST 增量刷新）
-- NEXT SYSDATE + 1：每天自動刷新（注意：行末不能有 -- 注釋，Oracle 會把它存入 NEXT 表達式字串）
CREATE MATERIALIZED VIEW mv_monthly_salary_summary
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH SYSDATE
NEXT SYSDATE + 1
AS
SELECT
    e.department_id,
    d.dept_name,
    TO_CHAR(sr.effective_date, 'YYYY-MM')  AS salary_month,
    COUNT(sr.employee_id)                  AS employee_count,
    SUM(sr.base_salary)                    AS total_base,
    SUM(sr.bonus)                          AS total_bonus,
    SUM(sr.total_salary)                   AS total_payroll,
    ROUND(AVG(sr.total_salary), 2)         AS avg_salary,
    MAX(sr.total_salary)                   AS max_salary,
    MIN(sr.total_salary)                   AS min_salary
FROM salary_records sr
JOIN employees    e ON sr.employee_id   = e.employee_id
JOIN departments  d ON e.department_id  = d.department_id
GROUP BY
    e.department_id,
    d.dept_name,
    TO_CHAR(sr.effective_date, 'YYYY-MM');

-- ── MV 2：員工績效年度彙總 ───────────────────────────────
CREATE MATERIALIZED VIEW mv_yearly_performance
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH SYSDATE
-- NEXT SYSDATE + 7：每週刷新
NEXT SYSDATE + 7
AS
SELECT
    pr.employee_id,
    fn_employee_fullname(pr.employee_id)   AS emp_name,
    e.department_id,
    d.dept_name,
    pr.review_year,
    ROUND(AVG(pr.score), 2)                AS avg_score,
    -- DECODE：Oracle 特有的 CASE 簡寫
    DECODE(
        MAX(DECODE(pr.grade, 'S',5,'A',4,'B',3,'C',2,'D',1)),
        5,'S', 4,'A', 3,'B', 2,'C', 1,'D'
    )                                      AS best_grade,
    COUNT(pr.review_quarter)               AS review_count
FROM performance_reviews pr
JOIN employees   e ON pr.employee_id  = e.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY
    pr.employee_id,
    e.department_id,
    d.dept_name,
    pr.review_year;

-- ── 建立索引加速 MV 查詢 ─────────────────────────────────
CREATE INDEX idx_mv_salary_dept_month
    ON mv_monthly_salary_summary (department_id, salary_month);

-- ──────────────────────────────────────────────────────────────
-- 手動刷新：
-- EXEC DBMS_MVIEW.REFRESH('mv_monthly_salary_summary', 'C');
--
-- 查詢 MV（與一般 TABLE 完全相同語法）：
-- SELECT * FROM mv_monthly_salary_summary WHERE salary_month = '2025-03';
-- ──────────────────────────────────────────────────────────────
