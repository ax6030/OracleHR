# Oracle Database 特性學習指南

> 本文件整理 Oracle 核心特性與 SQL Server 差異，搭配本專案實際使用場景說明。

---

## 為何選 Oracle？

Oracle Database 在企業市場佔有率長期名列前茅，特別擅長：

| 強項 | 說明 |
|------|------|
| **超大規模資料** | 分區、並行查詢、RAC 叢集 |
| **複雜業務邏輯** | PL/SQL 儲存過程、觸發器 |
| **資料安全** | VPD 列層級安全、審計 |
| **高可用** | Data Guard、RAC、Streams |
| **時間旅行** | Flashback Technology |
| **階層資料** | CONNECT BY 原生支援 |
| **分析函式** | ROLLUP、CUBE、GROUPING SETS |

---

## 1. Sequence（序列）

### 與 SQL Server IDENTITY 的差異

```sql
-- Oracle：明確建立並引用
CREATE SEQUENCE seq_employee_id
    START WITH 1000
    INCREMENT BY 1
    CACHE 50;        -- 預先快取 50 個值，提升並發效能

-- 使用方式
SELECT seq_employee_id.NEXTVAL FROM DUAL;   -- 取下一個值
SELECT seq_employee_id.CURRVAL FROM DUAL;   -- 取當前值（同 session）

-- SQL Server：隱含在 IDENTITY 欄位中
-- INT IDENTITY(1000, 1)  -- 無法跨表共用
```

### Oracle 12c+ 的 GENERATED AS IDENTITY（更接近 SQL Server）

```sql
CREATE TABLE employees (
    employee_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1000),
    ...
);
```

### 本專案使用場景

`sql/01_sequences.sql` 建立了 5 個 Sequence，分別對應：
- `seq_department_id` → 部門編號（100+）
- `seq_employee_id` → 員工編號（1000+）
- `seq_salary_id` / `seq_review_id` / `seq_audit_id` → 各記錄表

---

## 2. CONNECT BY（階層查詢）

### 語法結構

```sql
SELECT [欄位]
FROM [表格]
START WITH [根節點條件]           -- 從哪裡開始
CONNECT BY PRIOR [父欄位] = [子欄位]  -- 父子關聯方向
[ORDER SIBLINGS BY [排序欄位]]    -- 同層節點排序
```

### 專屬虛擬欄位 / 函式

| 名稱 | 說明 |
|------|------|
| `LEVEL` | 目前節點深度（根 = 1） |
| `CONNECT_BY_ISLEAF` | 是否葉節點（1=是，0=否） |
| `CONNECT_BY_ROOT expr` | 取得根節點的欄位值 |
| `SYS_CONNECT_BY_PATH(col, sep)` | 從根到目前節點的路徑 |
| `PRIOR` | 參照父節點的值 |

### 範例：部門組織樹

```sql
SELECT
    LEVEL,
    LPAD(' ', (LEVEL-1)*4) || dept_name AS dept_tree,
    SYS_CONNECT_BY_PATH(dept_name, ' > ') AS full_path
FROM departments
START WITH parent_dept_id IS NULL
CONNECT BY PRIOR department_id = parent_dept_id
ORDER SIBLINGS BY dept_name;

-- 結果範例：
-- LEVEL  DEPT_TREE                    FULL_PATH
--   1    總公司                        > 總公司
--   2        技術部                    > 總公司 > 技術部
--   3            後端組                > 總公司 > 技術部 > 後端組
--   3            前端組                > 總公司 > 技術部 > 前端組
--   2        人事部                    > 總公司 > 人事部
```

### EF Core 中呼叫（原生 SQL）

```csharp
// Infrastructure/Oracle/OracleRawQuery.cs
var result = await _db.Database
    .SqlQueryRaw<DeptTreeDto>("""
        SELECT LEVEL as Depth,
               LPAD(' ', (LEVEL-1)*4) || dept_name AS DeptTree,
               SYS_CONNECT_BY_PATH(dept_name, ' > ') AS FullPath,
               department_id AS DepartmentId
        FROM departments
        START WITH parent_dept_id IS NULL
        CONNECT BY PRIOR department_id = parent_dept_id
    """)
    .ToListAsync(ct);
```

---

## 3. Partitioning（分區）

### 概念

將一張大表依指定條件分成多個實體分區，但對查詢者看起來是一張表。

```
salary_records（邏輯上一張表）
├── p2023  → effective_date < 2024-01-01
├── p2024  → effective_date < 2025-01-01
├── p2025  → effective_date < 2026-01-01
└── p_future → 其他（MAXVALUE）
```

### 效益

- 查詢時 Oracle 自動跳過無關分區（Partition Pruning）
- 例：`WHERE effective_date BETWEEN '2025-01-01' AND '2025-03-31'` 只掃 `p2025`

### 新增未來分區

```sql
ALTER TABLE salary_records
    ADD PARTITION p2026 VALUES LESS THAN (DATE '2027-01-01');
```

### 查詢分區資訊

```sql
SELECT partition_name, num_rows
FROM user_tab_partitions
WHERE table_name = 'SALARY_RECORDS';
```

---

## 4. PL/SQL（儲存過程 / 函式）

### 基本結構

```sql
CREATE OR REPLACE PROCEDURE proc_name (
    p_in    IN  NUMBER,        -- IN 參數：只讀
    p_out   OUT VARCHAR2,      -- OUT 參數：只寫（回傳值）
    p_io    IN OUT NUMBER      -- IN OUT：可讀可寫
)
AS
    v_local VARCHAR2(100);     -- 區域變數
BEGIN
    -- 邏輯
    SELECT name INTO v_local FROM t WHERE id = p_in;
    p_out := 'Result: ' || v_local;
EXCEPTION
    WHEN NO_DATA_FOUND THEN p_out := '找不到資料';
    WHEN OTHERS        THEN p_out := SQLERRM;  -- SQLERRM：取錯誤訊息
END proc_name;
/
```

### %TYPE 與 %ROWTYPE

```sql
-- %TYPE：對應表格欄位型別，欄位變更時自動同步
v_salary employees.base_salary%TYPE;

-- %ROWTYPE：對應整列型別
v_emp    employees%ROWTYPE;
SELECT * INTO v_emp FROM employees WHERE employee_id = 1001;
DBMS_OUTPUT.PUT_LINE(v_emp.first_name);
```

### 從 C# 呼叫 Stored Procedure

```csharp
// Infrastructure/Oracle/OracleRawQuery.cs
using Oracle.ManagedDataAccess.Client;

var conn = (OracleConnection)_db.Database.GetDbConnection();
await conn.OpenAsync(ct);

using var cmd = conn.CreateCommand();
cmd.CommandText = "sp_calculate_monthly_salary";
cmd.CommandType = CommandType.StoredProcedure;

cmd.Parameters.Add("p_employee_id", OracleDbType.Decimal, employeeId, ParameterDirection.Input);
cmd.Parameters.Add("p_year",        OracleDbType.Decimal, year,       ParameterDirection.Input);
cmd.Parameters.Add("p_month",       OracleDbType.Decimal, month,      ParameterDirection.Input);
cmd.Parameters.Add("p_total_salary",OracleDbType.Decimal, ParameterDirection.Output);
cmd.Parameters.Add("p_message",     OracleDbType.Varchar2, 500, ParameterDirection.Output);

await cmd.ExecuteNonQueryAsync(ct);

var total   = Convert.ToDecimal(cmd.Parameters["p_total_salary"].Value);
var message = cmd.Parameters["p_message"].Value?.ToString();
```

---

## 5. Trigger（觸發器）

### 類型

| 時機 | 層級 | 用途 |
|------|------|------|
| `BEFORE INSERT/UPDATE/DELETE` | `FOR EACH ROW` | 修改 :NEW 值（如自動填 emp_code） |
| `AFTER INSERT/UPDATE/DELETE` | `FOR EACH ROW` | 寫稽核 Log |
| `INSTEAD OF` | （View 用） | 可寫入 View |

### :NEW 與 :OLD

```sql
-- INSERT：只有 :NEW
-- UPDATE：:OLD（改前）、:NEW（改後）
-- DELETE：只有 :OLD
```

### 本專案的 Trigger

| Trigger | 表格 | 功能 |
|---------|------|------|
| `trg_employee_audit` | employees | AFTER 寫稽核 Log |
| `trg_employee_updated_at` | employees | BEFORE UPDATE 自動填 updated_at |
| `trg_employee_code` | employees | BEFORE INSERT 自動產生 EMP-xxxx |

---

## 6. Flashback Query

```sql
-- 查 30 分鐘前的資料
SELECT * FROM employees
AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '30' MINUTE);

-- 查指定時間點
SELECT * FROM employees
AS OF TIMESTAMP TO_TIMESTAMP('2025-03-20 14:00:00', 'YYYY-MM-DD HH24:MI:SS')
WHERE status = 'ACTIVE';
```

### 啟用 Flashback（若未啟用）

```sql
-- 需 DBA 權限（SYS）
ALTER DATABASE FLASHBACK ON;

-- 設定 UNDO 保留時間（秒），預設 900 = 15 分鐘
ALTER SYSTEM SET UNDO_RETENTION = 3600;  -- 1 小時
```

---

## 7. Materialized View

```sql
-- 建立
CREATE MATERIALIZED VIEW mv_name
BUILD IMMEDIATE                 -- 立即填充（vs DEFERRED 延後）
REFRESH COMPLETE                -- 完整刷新（vs FAST 增量）
START WITH SYSDATE
NEXT SYSDATE + 1               -- 每天刷新
AS
SELECT ... FROM ... JOIN ...;

-- 手動刷新
EXEC DBMS_MVIEW.REFRESH('mv_name', 'C');   -- C = Complete
EXEC DBMS_MVIEW.REFRESH('mv_name', 'F');   -- F = Fast（需 MV Log）

-- 查詢（與一般 TABLE 相同）
SELECT * FROM mv_monthly_salary_summary;
```

---

## 8. Oracle 資料型別速查

| Oracle 型別 | 說明 | C# 對應 |
|------------|------|---------|
| `NUMBER` | 任意精度數值 | `decimal` |
| `NUMBER(n)` | n 位整數 | `int` / `long` |
| `NUMBER(p,s)` | p 總位數、s 小數位 | `decimal` |
| `VARCHAR2(n)` | 可變長字串（最大 4000） | `string` |
| `CHAR(n)` | 固定長字串 | `string` |
| `CLOB` | 大文字（>4KB） | `string` |
| `DATE` | 日期 + 時間（精確到秒） | `DateTime` |
| `TIMESTAMP` | 高精度時間戳記（含奈秒） | `DateTime` |
| `TIMESTAMP WITH TIME ZONE` | 含時區 | `DateTimeOffset` |
| `BLOB` | 二進位大物件 | `byte[]` |

---

## Oracle 常用函式速查

```sql
-- 日期
SYSDATE                          -- 目前日期時間
SYSTIMESTAMP                     -- 目前高精度時間戳記
TO_DATE('2025-03-20', 'YYYY-MM-DD')
TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
ADD_MONTHS(SYSDATE, 3)           -- 加 3 個月
MONTHS_BETWEEN(date1, date2)     -- 兩日期相差月數

-- 字串
SUBSTR(str, start, len)          -- 擷取子字串
INSTR(str, substr)               -- 找子字串位置
LPAD('5', 4, '0')  → '0005'    -- 左補零
RPAD('A', 5, '-')  → 'A----'   -- 右補字元
TRIM('  hello  ') → 'hello'
UPPER / LOWER / INITCAP

-- 數值
ROUND(3.456, 2)    → 3.46
TRUNC(3.456, 2)    → 3.45       -- 截斷（不四捨五入）
MOD(10, 3)         → 1          -- 取餘數
ABS(-5)            → 5

-- NULL 處理
NVL(col, 0)                      -- NULL → 0
NVL2(col, 'Y', 'N')             -- 非NULL→'Y'，NULL→'N'
COALESCE(a, b, c)                -- 取第一個非 NULL

-- 條件
DECODE(x, 1,'一', 2,'二', '其他')  -- Oracle 特有，類似 CASE
CASE WHEN ... THEN ... ELSE ... END -- 標準 SQL，Oracle 也支援
```
