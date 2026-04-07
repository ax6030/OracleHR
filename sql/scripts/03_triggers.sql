-- =============================================================
-- Oracle TRIGGER 示範
-- Trigger 在資料異動時自動執行，常用於：
--   1. 稽核 Log（記錄誰在何時改了什麼）
--   2. 自動更新欄位（updated_at）
--   3. 商業規則驗證
-- =============================================================

-- ── Trigger 1：員工資料異動稽核 Log ──────────────────────────
CREATE OR REPLACE TRIGGER trg_employee_audit
    AFTER INSERT OR UPDATE OR DELETE ON employees
    FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_record_id NUMBER;
    v_old_val   CLOB;
    v_new_val   CLOB;
BEGIN
    -- 判斷操作類型
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_record_id := :NEW.employee_id;
        v_new_val   := 'emp_code=' || :NEW.emp_code || ', name=' || :NEW.first_name || ' ' || :NEW.last_name
                       || ', salary=' || :NEW.base_salary || ', status=' || :NEW.status;
        v_old_val   := NULL;

    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_record_id := :NEW.employee_id;
        v_old_val   := 'salary=' || :OLD.base_salary || ', status=' || :OLD.status;
        v_new_val   := 'salary=' || :NEW.base_salary || ', status=' || :NEW.status;

    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_record_id := :OLD.employee_id;
        v_old_val   := 'emp_code=' || :OLD.emp_code || ', name=' || :OLD.first_name || ' ' || :OLD.last_name;
        v_new_val   := NULL;
    END IF;

    INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
    VALUES ('EMPLOYEES', v_operation, v_record_id, v_old_val, v_new_val);
END;
/

-- ── Trigger 2：自動更新 updated_at ──────────────────────────
CREATE OR REPLACE TRIGGER trg_employee_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSDATE;
END;
/

-- ── Trigger 3：員工編號自動產生（EMP-xxxx 格式）─────────────
CREATE OR REPLACE TRIGGER trg_employee_code
    BEFORE INSERT ON employees
    FOR EACH ROW
BEGIN
    IF :NEW.emp_code IS NULL THEN
        :NEW.emp_code := 'EMP-' || TO_CHAR(:NEW.employee_id, 'FM0000');
    END IF;
END;
/

-- ──────────────────────────────────────────────────────────────
-- :NEW  → 新值（INSERT / UPDATE 時可用）
-- :OLD  → 舊值（UPDATE / DELETE 時可用）
-- FOR EACH ROW → 列層級 trigger（每筆資料各觸發一次）
-- AFTER / BEFORE → 決定在 DML 之前或之後執行
-- ──────────────────────────────────────────────────────────────
