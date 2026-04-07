-- =============================================================
-- Oracle SEQUENCE 示範
-- SQL Server 使用 IDENTITY，Oracle 使用 SEQUENCE（更彈性）
-- SEQUENCE 可跨表格共用，可控制 CACHE 量加速並發
-- =============================================================

-- 部門 ID 序列（從 100 開始，每次 +1，快取 20 個）
CREATE SEQUENCE seq_department_id
    START WITH 100
    INCREMENT BY 1
    NOCYCLE
    CACHE 20;

-- 員工 ID 序列（從 1000 開始）
CREATE SEQUENCE seq_employee_id
    START WITH 1000
    INCREMENT BY 1
    NOCYCLE
    CACHE 50;

-- 薪資記錄 ID 序列
CREATE SEQUENCE seq_salary_id
    START WITH 1
    INCREMENT BY 1
    NOCYCLE
    CACHE 100;

-- 績效考核 ID 序列
CREATE SEQUENCE seq_review_id
    START WITH 1
    INCREMENT BY 1
    NOCYCLE
    CACHE 20;

-- 稽核 Log ID 序列
CREATE SEQUENCE seq_audit_id
    START WITH 1
    INCREMENT BY 1
    NOCYCLE
    CACHE 200;

-- ──────────────────────────────────────────────
-- 如何取得下一個值（用 DUAL 虛擬表）
-- SELECT seq_employee_id.NEXTVAL FROM DUAL;
-- SELECT seq_employee_id.CURRVAL FROM DUAL;  -- 取當前值（同 session 內）
-- ──────────────────────────────────────────────
