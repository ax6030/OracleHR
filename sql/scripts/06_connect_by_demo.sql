-- =============================================================
-- Oracle CONNECT BY 階層查詢示範
-- 這是 Oracle 獨有語法，SQL Server 需用 Recursive CTE
-- 用於：組織架構、BOM 清單、分類樹等
-- =============================================================

-- ── 查詢完整部門組織樹 ────────────────────────────────────
SELECT
    LEVEL                                          AS depth,       -- 深度（根=1）
    LPAD(' ', (LEVEL-1)*4) || dept_name            AS dept_tree,   -- 縮排顯示
    department_id,
    parent_dept_id,
    SYS_CONNECT_BY_PATH(dept_name, ' > ')          AS full_path,   -- 完整路徑
    CONNECT_BY_ISLEAF                              AS is_leaf,     -- 是否葉節點
    CONNECT_BY_ROOT dept_name                      AS root_dept    -- 根部門名稱
FROM departments
START WITH parent_dept_id IS NULL        -- 從根節點開始（無父部門）
CONNECT BY PRIOR department_id = parent_dept_id  -- 父→子關聯
ORDER SIBLINGS BY dept_name;             -- 同層依名稱排序

-- ── 查詢特定部門及其所有子部門 ───────────────────────────
-- 假設要查 department_id = 100 及其下屬：
SELECT department_id, dept_name, LEVEL AS depth
FROM departments
START WITH department_id = 100
CONNECT BY PRIOR department_id = parent_dept_id;

-- ── 查詢員工匯報鏈（向上追溯）───────────────────────────
SELECT
    LEVEL                                          AS level_up,
    employee_id,
    first_name || ' ' || last_name                 AS emp_name,
    job_title,
    manager_id
FROM employees
START WITH employee_id = 1001             -- 從特定員工開始
CONNECT BY PRIOR manager_id = employee_id -- 往上找（子→父）
ORDER BY LEVEL;

-- ── 對照：SQL Server Recursive CTE 寫法 ────────────────
/*
WITH DeptCTE AS (
    -- Anchor（根節點）
    SELECT department_id, dept_name, parent_dept_id, 0 AS depth
    FROM departments
    WHERE parent_dept_id IS NULL

    UNION ALL

    -- Recursive（子節點）
    SELECT d.department_id, d.dept_name, d.parent_dept_id, c.depth + 1
    FROM departments d
    JOIN DeptCTE c ON d.parent_dept_id = c.department_id
)
SELECT * FROM DeptCTE ORDER BY depth;
*/
-- Oracle CONNECT BY 比 Recursive CTE 更簡潔，且有 LEVEL、SYS_CONNECT_BY_PATH 等專屬函式
