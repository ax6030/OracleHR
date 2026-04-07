-- =============================================================
-- 08_seed_data.sql  範例資料（PL/SQL 區塊版）
-- 使用 RETURNING INTO 取得實際生成的 ID，不依賴硬編碼數字，
-- 可在 Sequence 已被使用的情況下安全執行。
-- =============================================================
DECLARE
    -- 部門 ID
    v_dept_root  NUMBER;
    v_dept_it    NUMBER;
    v_dept_hr    NUMBER;
    v_dept_fin   NUMBER;
    v_dept_dev   NUMBER;
    v_dept_ops   NUMBER;

    -- 員工 ID
    v_emp_ceo    NUMBER;
    v_emp_cio    NUMBER;
    v_emp_hr_mgr NUMBER;
    v_emp_senior NUMBER;
    v_emp_dev1   NUMBER;
    v_emp_ops    NUMBER;
    v_emp_dev2   NUMBER;
    v_emp_hr_sp  NUMBER;

BEGIN
    -- ── 部門（manager_id 暫設 NULL，待員工建立後更新）──────────

    INSERT INTO departments (dept_name, parent_dept_id)
    VALUES ('總公司', NULL)
    RETURNING department_id INTO v_dept_root;

    INSERT INTO departments (dept_name, parent_dept_id)
    VALUES ('資訊技術部', v_dept_root)
    RETURNING department_id INTO v_dept_it;

    INSERT INTO departments (dept_name, parent_dept_id)
    VALUES ('人力資源部', v_dept_root)
    RETURNING department_id INTO v_dept_hr;

    INSERT INTO departments (dept_name, parent_dept_id)
    VALUES ('財務部', v_dept_root)
    RETURNING department_id INTO v_dept_fin;

    INSERT INTO departments (dept_name, parent_dept_id)
    VALUES ('軟體開發組', v_dept_it)
    RETURNING department_id INTO v_dept_dev;

    INSERT INTO departments (dept_name, parent_dept_id)
    VALUES ('系統維運組', v_dept_it)
    RETURNING department_id INTO v_dept_ops;

    -- ── 員工（emp_code 由 trg_employee_code trigger 自動產生）──

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('小明', '王', 'wang.xiaoming@oraclehr.com',
         DATE '2020-01-15', '總經理',
         v_dept_root, NULL, 150000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_ceo;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('大衛', '陳', 'chen.david@oraclehr.com',
         DATE '2020-03-01', '資訊長',
         v_dept_it, v_emp_ceo, 120000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_cio;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('美麗', '林', 'lin.meili@oraclehr.com',
         DATE '2020-05-01', 'HR 主管',
         v_dept_hr, v_emp_ceo, 100000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_hr_mgr;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('志偉', '張', 'zhang.zhiwei@oraclehr.com',
         DATE '2021-07-01', '資深工程師',
         v_dept_dev, v_emp_cio, 90000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_senior;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('雅婷', '李', 'li.yating@oraclehr.com',
         DATE '2022-02-14', '工程師',
         v_dept_dev, v_emp_cio, 75000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_dev1;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('建國', '黃', 'huang.jianguo@oraclehr.com',
         DATE '2021-09-01', '系統管理員',
         v_dept_ops, v_emp_cio, 80000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_ops;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('俊傑', '劉', 'liu.junjie@oraclehr.com',
         DATE '2023-04-01', '工程師',
         v_dept_dev, v_emp_senior, 70000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_dev2;

    INSERT INTO employees
        (first_name, last_name, email, hire_date, job_title,
         department_id, manager_id, base_salary, status)
    VALUES
        ('淑芬', '吳', 'wu.shufen@oraclehr.com',
         DATE '2022-11-01', 'HR 專員',
         v_dept_hr, v_emp_hr_mgr, 65000, 'ACTIVE')
    RETURNING employee_id INTO v_emp_hr_sp;

    -- ── 更新部門主管 ─────────────────────────────────────────────

    UPDATE departments SET manager_id = v_emp_ceo    WHERE department_id = v_dept_root;
    UPDATE departments SET manager_id = v_emp_cio    WHERE department_id = v_dept_it;
    UPDATE departments SET manager_id = v_emp_hr_mgr WHERE department_id = v_dept_hr;
    UPDATE departments SET manager_id = v_emp_senior WHERE department_id = v_dept_dev;
    UPDATE departments SET manager_id = v_emp_ops    WHERE department_id = v_dept_ops;

    -- ── 薪資歷史記錄 ─────────────────────────────────────────────

    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_ceo, DATE '2024-01-01', 150000, 30000, '年度調薪');
    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_ceo, DATE '2023-01-01', 140000, 25000, '年度調薪');

    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_cio, DATE '2024-01-01', 120000, 20000, '年度調薪');
    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_cio, DATE '2023-01-01', 110000, 18000, NULL);

    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_senior, DATE '2024-01-01', 90000, 15000, '績效調薪');
    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_senior, DATE '2023-01-01', 85000, 12000, NULL);

    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_dev1, DATE '2024-01-01', 75000, 10000, NULL);
    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_dev1, DATE '2022-07-01', 72000, 8000, '試用期結束調薪');

    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_dev2, DATE '2024-01-01', 70000, 8000, NULL);
    INSERT INTO salary_records (employee_id, effective_date, base_salary, bonus, remark)
    VALUES (v_emp_hr_sp, DATE '2024-01-01', 65000, 7000, NULL);

    -- ── 績效考核記錄 ─────────────────────────────────────────────

    INSERT INTO performance_reviews
        (employee_id, reviewer_id, review_year, review_quarter, score, grade, comments)
    VALUES (v_emp_senior, v_emp_cio, 2024, 1, 92, 'A', '技術能力優秀，按時完成所有任務');

    INSERT INTO performance_reviews
        (employee_id, reviewer_id, review_year, review_quarter, score, grade, comments)
    VALUES (v_emp_senior, v_emp_cio, 2023, 4, 88, 'A', '積極主動，解決多個技術難題');

    INSERT INTO performance_reviews
        (employee_id, reviewer_id, review_year, review_quarter, score, grade, comments)
    VALUES (v_emp_dev1, v_emp_cio, 2024, 1, 85, 'A', '學習能力強，代碼品質良好');

    INSERT INTO performance_reviews
        (employee_id, reviewer_id, review_year, review_quarter, score, grade, comments)
    VALUES (v_emp_dev1, v_emp_cio, 2023, 4, 80, 'B', '表現穩定，持續進步');

    INSERT INTO performance_reviews
        (employee_id, reviewer_id, review_year, review_quarter, score, grade, comments)
    VALUES (v_emp_dev2, v_emp_senior, 2024, 1, 78, 'B', '新員工，進步迅速');

    INSERT INTO performance_reviews
        (employee_id, reviewer_id, review_year, review_quarter, score, grade, comments)
    VALUES (v_emp_hr_sp, v_emp_hr_mgr, 2024, 1, 90, 'A', '服務熱情，員工關係良好');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('✅ 種子資料寫入完成');
    DBMS_OUTPUT.PUT_LINE('   部門根節點 ID: ' || v_dept_root);
    DBMS_OUTPUT.PUT_LINE('   CEO employee_id: ' || v_emp_ceo);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ 錯誤: ' || SQLERRM);
        RAISE;
END;
/
