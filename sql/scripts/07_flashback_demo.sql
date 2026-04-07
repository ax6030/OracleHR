-- =============================================================
-- Oracle FLASHBACK QUERY 示範
-- 查詢任意時間點的資料（SQL Server 無此功能）
-- 依賴 UNDO tablespace，預設保留 15 分鐘～數小時
-- =============================================================

-- ── 情境：誤刪員工後還原 ─────────────────────────────────

-- Step 1：記錄目前時間點
-- SELECT SYSTIMESTAMP FROM DUAL;
-- 假設：2025-03-20 14:30:00

-- Step 2：不小心刪除員工（模擬）
-- DELETE FROM employees WHERE employee_id = 1001;
-- COMMIT;

-- Step 3：用 AS OF TIMESTAMP 查回刪除前的資料
SELECT *
FROM employees AS OF TIMESTAMP
    TO_TIMESTAMP('2025-03-20 14:30:00', 'YYYY-MM-DD HH24:MI:SS')
WHERE employee_id = 1001;

-- Step 4：用查回的資料重新插入
INSERT INTO employees (
    employee_id, emp_code, first_name, last_name, email,
    hire_date, job_title, department_id, base_salary, status
)
SELECT
    employee_id, emp_code, first_name, last_name, email,
    hire_date, job_title, department_id, base_salary, status
FROM employees AS OF TIMESTAMP
    TO_TIMESTAMP('2025-03-20 14:30:00', 'YYYY-MM-DD HH24:MI:SS')
WHERE employee_id = 1001;

COMMIT;

-- ── 其他用法 ─────────────────────────────────────────────

-- 查 2 小時前的資料（使用 INTERVAL）
SELECT * FROM employees
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '2' HOUR)
WHERE department_id = 100;

-- 查昨天某時刻的薪資記錄
SELECT * FROM salary_records
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' DAY)
WHERE employee_id = 1001;

-- ──────────────────────────────────────────────────────────────
-- 注意事項：
-- 1. 若 UNDO 資料已過期（超過 undo_retention 設定），查詢會報錯 ORA-01555
-- 2. 若表格已有 DDL 操作（ALTER TABLE），Flashback 可能失效
-- 3. 生產環境建議設定 UNDO_RETENTION >= 3600（1 小時）
-- 4. 查看目前設定：SELECT value FROM v$parameter WHERE name = 'undo_retention';
-- ──────────────────────────────────────────────────────────────
