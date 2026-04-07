#!/bin/bash
# =============================================================
# 00_init.sh  資料庫初始化入口
# ─────────────────────────────────────────────────────────────
# 【為什麼需要這個檔案？】
# gvenzl/oracle-xe 鏡像會以 SYS SYSDBA 身分自動執行
# /docker-entrypoint-initdb.d/ 頂層的 .sql 檔。
# 若以 SYS 建立 TABLE/TRIGGER，Oracle 會拋出：
#   ORA-04089: cannot create triggers on objects owned by SYS
# 解法：把 SQL 腳本放在 scripts/ 子目錄（不會被自動執行），
# 改由此 shell script 以 $APP_USER 連線後依序執行。
# =============================================================

set -e  # 任何指令失敗即中止

SCRIPTS_DIR="/docker-entrypoint-initdb.d/scripts"

echo ">>> [OracleHR] 以 ${APP_USER} 身分開始初始化..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/XEPDB1" <<ENDSQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON SIZE UNLIMITED

-- 1. Sequences
@${SCRIPTS_DIR}/01_sequences.sql

-- 2. Tables
@${SCRIPTS_DIR}/02_tables.sql

-- 3. Triggers
@${SCRIPTS_DIR}/03_triggers.sql

-- 4. Stored Procedures / Functions
@${SCRIPTS_DIR}/04_stored_procedures.sql

-- 5. Materialized Views（依賴 04 的 Function）
@${SCRIPTS_DIR}/05_materialized_view.sql

-- 6. Seed Data
@${SCRIPTS_DIR}/08_seed_data.sql

EXIT 0
ENDSQL

echo ">>> [OracleHR] 初始化完成！"
