-- =============================================================
-- 基礎資料表建立
-- Oracle 型別差異：
--   VARCHAR2（非 VARCHAR）、NUMBER（非 INT/DECIMAL）
--   DATE（含時間成分）、TIMESTAMP（更精確）
-- =============================================================

-- 部門表（支援自我參照 → 組織階層）
CREATE TABLE departments (
    department_id   NUMBER          DEFAULT seq_department_id.NEXTVAL PRIMARY KEY,
    dept_name       VARCHAR2(100)   NOT NULL,
    parent_dept_id  NUMBER,                          -- 上層部門（NULL = 根節點）
    manager_id      NUMBER,                          -- 部門主管（後補外鍵）
    created_at      DATE            DEFAULT SYSDATE, -- Oracle DATE 含時間
    CONSTRAINT fk_dept_parent FOREIGN KEY (parent_dept_id) REFERENCES departments(department_id)
);

-- 員工表
CREATE TABLE employees (
    employee_id     NUMBER          DEFAULT seq_employee_id.NEXTVAL PRIMARY KEY,
    emp_code        VARCHAR2(20)    UNIQUE NOT NULL,  -- 員工編號，如 EMP-1001
    first_name      VARCHAR2(50)    NOT NULL,
    last_name       VARCHAR2(50)    NOT NULL,
    email           VARCHAR2(100)   UNIQUE NOT NULL,
    phone           VARCHAR2(20),
    hire_date       DATE            NOT NULL,
    job_title       VARCHAR2(100)   NOT NULL,
    department_id   NUMBER          NOT NULL,
    manager_id      NUMBER,                          -- 直屬主管
    base_salary     NUMBER(12,2)    NOT NULL,        -- NUMBER(精度, 小數位)
    status          VARCHAR2(20)    DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','RESIGNED')),
    created_at      DATE            DEFAULT SYSDATE,
    updated_at      DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_emp_dept    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id)   REFERENCES employees(employee_id)
);

-- 補上部門主管外鍵（因 employees 建立後才能設定）
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_manager FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- 薪資歷史表（依年份分區，Oracle Partitioning）
-- 注意：Oracle XE 21c 支援 Partitioning（企業版功能在 XE 免費提供）
CREATE TABLE salary_records (
    salary_id       NUMBER          DEFAULT seq_salary_id.NEXTVAL,
    employee_id     NUMBER          NOT NULL,
    effective_date  DATE            NOT NULL,        -- 生效日期（用於分區鍵）
    base_salary     NUMBER(12,2)    NOT NULL,
    bonus           NUMBER(12,2)    DEFAULT 0,
    total_salary    NUMBER(12,2)    GENERATED ALWAYS AS (base_salary + bonus) VIRTUAL,
    remark          VARCHAR2(500),
    created_at      DATE            DEFAULT SYSDATE,
    CONSTRAINT pk_salary PRIMARY KEY (salary_id, effective_date), -- 分區表 PK 需含分區鍵
    CONSTRAINT fk_salary_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
)
PARTITION BY RANGE (effective_date) (
    PARTITION p2023 VALUES LESS THAN (DATE '2024-01-01'),
    PARTITION p2024 VALUES LESS THAN (DATE '2025-01-01'),
    PARTITION p2025 VALUES LESS THAN (DATE '2026-01-01'),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- 績效考核表
CREATE TABLE performance_reviews (
    review_id       NUMBER          DEFAULT seq_review_id.NEXTVAL PRIMARY KEY,
    employee_id     NUMBER          NOT NULL,
    reviewer_id     NUMBER          NOT NULL,        -- 考核者（主管）
    review_year     NUMBER(4)       NOT NULL,
    review_quarter  NUMBER(1)       CHECK (review_quarter IN (1,2,3,4)),
    score           NUMBER(5,2)     CHECK (score BETWEEN 0 AND 100),
    grade           VARCHAR2(2)     CHECK (grade IN ('S','A','B','C','D')),
    comments        CLOB,                            -- CLOB：Oracle 大文字型別
    review_date     DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_review_emp      FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_review_reviewer FOREIGN KEY (reviewer_id) REFERENCES employees(employee_id),
    CONSTRAINT uq_review_period   UNIQUE (employee_id, review_year, review_quarter)
);

-- 稽核 Log 表（由 Trigger 自動填入）
CREATE TABLE audit_log (
    audit_id        NUMBER          DEFAULT seq_audit_id.NEXTVAL PRIMARY KEY,
    table_name      VARCHAR2(50)    NOT NULL,
    operation       VARCHAR2(10)    NOT NULL,        -- INSERT / UPDATE / DELETE
    record_id       NUMBER          NOT NULL,
    changed_by      VARCHAR2(100)   DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'),
    changed_at      TIMESTAMP       DEFAULT SYSTIMESTAMP, -- TIMESTAMP 比 DATE 更精確
    old_values      CLOB,
    new_values      CLOB
);
