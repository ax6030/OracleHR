# OracleHR — 開發指南

> 人力資源管理平台，以 Oracle Database 為核心學習目標。
> 技術棧：ASP.NET Core .NET 9 + Clean Architecture + Oracle XE 21c + Docker + CloudBeaver

---

## 快速啟動

### 1. 前置需求

| 工具 | 最低版本 |
|------|---------|
| Docker Desktop | 4.x |
| .NET SDK | 9.x |
| Node.js | 20.x LTS |

### 2. 環境設定

```bash
# 複製環境變數範本
cp .env.example .env

# 編輯 .env（填入密碼，預設值可直接使用）
```

### 3. 啟動所有服務

```bash
# 第一次啟動（Oracle 需要約 2～3 分鐘初始化）
docker compose up -d

# 查看 Oracle 是否就緒
docker compose logs -f oracle-db

# 看到 "DATABASE IS READY TO USE!" 即可繼續
```

### 4. 服務位址

| 服務 | URL | 說明 |
|------|-----|------|
| 前端 | http://localhost:6001 | React + Vite |
| API | http://localhost:6000/swagger | Swagger UI |
| CloudBeaver | http://localhost:6080 | Web DB UI |
| Oracle | localhost:6521/XEPDB1 | 直接連線用 |

---

## CloudBeaver 設定

1. 開啟 http://localhost:6080
2. 第一次進入需建立管理員帳號
3. 點擊左上「New Connection」→ 選擇 **Oracle**
4. 填入連線資訊：

```
Host:        oracle-db    （Docker 網路內名稱，容器間通訊）
Port:        1521
Service:     XEPDB1
Username:    hr_user
Password:    OracleHR_App123   （對應 .env 的 ORACLE_APP_PASSWORD）
```

> 從主機本地工具（DBeaver 桌面版）連線用：
> `Host: localhost | Port: 6521 | Service: XEPDB1`

---

## .NET 開發

```bash
# 進入 API 專案
cd src/OracleHR.API

# 新增 Oracle Migration
dotnet ef migrations add InitOracle \
    --project ../OracleHR.Infrastructure \
    --startup-project .

# 套用到 Oracle DB
dotnet ef database update \
    --project ../OracleHR.Infrastructure \
    --startup-project .

# 執行 API（本地開發）
dotnet run
```

### 連線字串設定（appsettings.Development.json）

```json
{
  "ConnectionStrings": {
    "Oracle": "User Id=hr_user;Password=OracleHR_App123;Data Source=localhost:6521/XEPDB1;"
  }
}
```

---

## 手動執行 SQL 腳本

透過 CloudBeaver 或直接在容器內執行：

```bash
# 進入 Oracle 容器
docker exec -it oraclehr_db bash

# 連線（使用應用帳號）
sqlplus hr_user/OracleHR_App123@localhost:1521/XEPDB1

# 或使用 SYS（管理）
sqlplus sys/OracleHR_Sys123@localhost:1521/XEPDB1 as sysdba
```

腳本執行順序：

```
01_sequences.sql      → 建立 Sequence
02_tables.sql         → 建立資料表（含 Partitioned Table）
03_triggers.sql       → 建立 Trigger
04_stored_procedures.sql → 建立 PL/SQL Procedure / Function
05_materialized_view.sql → 建立 Materialized View
06_connect_by_demo.sql   → 階層查詢範例（查詢用，不需執行）
07_flashback_demo.sql    → Flashback 範例（查詢用，不需執行）
```

---

## 常用 Docker 指令

```bash
docker compose up -d                  # 啟動所有服務
docker compose up -d oracle-db        # 僅啟動 Oracle
docker compose logs -f oracle-db      # 即時查看 Oracle log
docker compose logs -f api            # 即時查看 API log
docker compose down                   # 停止（保留資料卷）
docker compose down -v                # 停止並刪除資料（重置 DB）
docker compose ps                     # 查看服務狀態
```

---

## Oracle 與 SQL Server 快速差異對照

| 項目 | Oracle | SQL Server |
|------|--------|-----------|
| 自動編號 | `SEQUENCE` / `GENERATED AS IDENTITY` | `IDENTITY` |
| 字串型別 | `VARCHAR2` | `VARCHAR` |
| 整數 | `NUMBER(10)` | `INT` |
| 金額 | `NUMBER(12,2)` | `DECIMAL(12,2)` |
| 大文字 | `CLOB` | `VARCHAR(MAX)` |
| 日期含時間 | `DATE`（含時分秒） | `DATETIME` |
| 精確時間戳記 | `TIMESTAMP` | `DATETIME2` |
| NULL 替換 | `NVL(col, 0)` | `ISNULL(col, 0)` |
| 取條件值 | `DECODE(x, 1,'A', 2,'B', 'C')` | `CASE WHEN` |
| 虛擬表 | `SELECT 1 FROM DUAL` | `SELECT 1` |
| 階層查詢 | `CONNECT BY PRIOR` | Recursive CTE |
| 分頁 | `OFFSET n ROWS FETCH NEXT m ROWS ONLY` | `OFFSET / FETCH` |
| 時間點查詢 | `AS OF TIMESTAMP` | 無直接對應 |

---

## 常見 Oracle 錯誤排解

| 錯誤碼 | 原因 | 解決方式 |
|--------|------|---------|
| ORA-00942 | 資料表不存在 | 確認 Schema（使用者）是否正確 |
| ORA-01400 | NULL 插入 NOT NULL 欄位 | 檢查 INSERT 語句 |
| ORA-00001 | 唯一鍵重複 | 檢查是否重複插入 |
| ORA-01555 | Flashback 資料已過期 | 需在 UNDO_RETENTION 時間內查詢 |
| ORA-02292 | 違反外鍵約束 | 先刪除子表資料再刪父表 |
| ORA-12541 | 無法連線到 TNS | 確認 Oracle 容器已啟動、port 正確 |

---

## 專案架構說明

```
src/
├── OracleHR.Domain/         # 純 C# 實體，不依賴外層
├── OracleHR.Application/    # Vertical Slice Features（CQRS）
├── OracleHR.Infrastructure/ # EF Core + Oracle 實作
├── OracleHR.API/            # ASP.NET Core 薄 Controller
└── OracleHR.Web/            # React + TypeScript + Vite
```

詳細 Oracle 特性說明請見 [docs/ORACLE_GUIDE.md](docs/ORACLE_GUIDE.md)
