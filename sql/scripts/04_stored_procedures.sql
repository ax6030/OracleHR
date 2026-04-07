-- =============================================================
-- Oracle PL/SQL 儲存過程示範
-- PL/SQL = Procedural Language / SQL，Oracle 專屬
-- 可寫 IF/LOOP/EXCEPTION，邏輯留在 DB 端減少網路往返
-- =============================================================

-- ── Procedure 1：月薪資計算（含績效獎金）───────────────────
CREATE OR REPLACE PROCEDURE sp_calculate_monthly_salary(
    p_employee_id  IN  employees.employee_id%TYPE,  -- %TYPE：型別對應欄位
    p_year         IN  NUMBER,
    p_month        IN  NUMBER,
    p_total_salary OUT NUMBER,
    p_message      OUT VARCHAR2
)
AS
    v_base_salary   employees.base_salary%TYPE;
    v_grade         performance_reviews.grade%TYPE;
    v_bonus_rate    NUMBER := 0;
    v_bonus         NUMBER := 0;
    v_quarter       NUMBER;
BEGIN
    -- 查詢基本薪資
    SELECT base_salary
    INTO   v_base_salary
    FROM   employees
    WHERE  employee_id = p_employee_id
      AND  status = 'ACTIVE';

    -- 計算當月屬哪一季
    v_quarter := CEIL(p_month / 3);

    -- 查詢最近一次績效考核等級（NVL 類似 ISNULL）
    SELECT NVL(MAX(grade), 'B')
    INTO   v_grade
    FROM   performance_reviews
    WHERE  employee_id  = p_employee_id
      AND  review_year  = p_year
      AND  review_quarter <= v_quarter;

    -- 依等級計算獎金比率（CASE 表達式）
    v_bonus_rate := CASE v_grade
        WHEN 'S' THEN 0.30
        WHEN 'A' THEN 0.20
        WHEN 'B' THEN 0.10
        WHEN 'C' THEN 0.05
        ELSE 0
    END;

    v_bonus        := v_base_salary * v_bonus_rate;
    p_total_salary := v_base_salary + v_bonus;
    p_message      := '計算完成：底薪=' || v_base_salary
                      || '，獎金率=' || (v_bonus_rate * 100) || '%'
                      || '，總薪=' || p_total_salary;

    -- 寫入薪資記錄
    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (p_employee_id,
            TO_DATE(p_year || '-' || LPAD(p_month, 2, '0') || '-01', 'YYYY-MM-DD'),
            v_base_salary,
            v_bonus,
            '月薪計算：等級=' || v_grade);

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_total_salary := 0;
        p_message      := '找不到員工或員工非在職狀態';
        ROLLBACK;
    WHEN OTHERS THEN
        p_total_salary := 0;
        p_message      := '發生錯誤：' || SQLERRM;
        ROLLBACK;
END sp_calculate_monthly_salary;
/

-- ── Function 1：查詢員工全名 ──────────────────────────────
CREATE OR REPLACE FUNCTION fn_employee_fullname(
    p_employee_id IN employees.employee_id%TYPE
) RETURN VARCHAR2
AS
    v_fullname VARCHAR2(100);
BEGIN
    SELECT last_name || ' ' || first_name
    INTO   v_fullname
    FROM   employees
    WHERE  employee_id = p_employee_id;

    RETURN v_fullname;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '未知員工';
END fn_employee_fullname;
/

-- ──────────────────────────────────────────────────────────────
-- 呼叫 Procedure 範例：
-- DECLARE
--     v_total   NUMBER;
--     v_msg     VARCHAR2(500);
-- BEGIN
--     sp_calculate_monthly_salary(1001, 2025, 3, v_total, v_msg);
--     DBMS_OUTPUT.PUT_LINE(v_msg);
-- END;
-- /
--
-- 呼叫 Function 範例：
-- SELECT fn_employee_fullname(1001) FROM DUAL;
-- ──────────────────────────────────────────────────────────────
