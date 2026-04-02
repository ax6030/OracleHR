<template>
  <div class="employee-view">
    <h2>員工查詢</h2>

    <!-- 查詢表單 -->
    <div class="search-bar">
      <!--
        v-model：雙向綁定，輸入欄位值會同步到 searchId
        @keyup.enter：按 Enter 觸發查詢（Vue 的事件修飾符語法）
      -->
      <input
        v-model="searchId"
        type="number"
        placeholder="輸入員工 ID"
        min="1"
        @keyup.enter="fetchEmployee"
      />
      <button @click="fetchEmployee" :disabled="loading">
        {{ loading ? '查詢中...' : '查詢' }}
      </button>
    </div>

    <!-- 錯誤訊息 -->
    <!-- v-if / v-else-if / v-else：條件渲染 -->
    <p v-if="error" class="error-msg">{{ error }}</p>

    <!-- 員工資料卡 -->
    <div v-else-if="employee" class="employee-card">
      <div class="card-header">
        <span class="emp-code">{{ employee.empCode }}</span>
        <!--
          :class 動態綁定：根據 status 套用不同 CSS class
          status-active / status-on-leave / status-resigned
        -->
        <span :class="['status-badge', statusClass]">{{ employee.status }}</span>
      </div>

      <h3 class="emp-name">{{ employee.fullName }}</h3>

      <dl class="info-grid">
        <dt>Email</dt>
        <dd>{{ employee.email }}</dd>

        <dt>電話</dt>
        <!-- ?? 運算子：null / undefined 時顯示備用值 -->
        <dd>{{ employee.phone ?? '—' }}</dd>

        <dt>到職日</dt>
        <!-- computed 格式化日期 -->
        <dd>{{ formattedHireDate }}</dd>

        <dt>部門</dt>
        <dd>{{ employee.departmentName ?? '—' }}</dd>

        <dt>直屬主管</dt>
        <dd>{{ employee.managerName ?? '—' }}</dd>
      </dl>
    </div>

    <!-- 尚未查詢的提示 -->
    <p v-else class="hint">請輸入員工 ID 開始查詢</p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { getEmployee, type EmployeeDto } from '@/services/api'

// ref()：建立響應式變數
// 當 searchId 改變，畫面會自動更新
const searchId = ref<string>('')
const employee = ref<EmployeeDto | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

// computed()：依賴其他響應式變數，自動快取，只有依賴變化才重算
const formattedHireDate = computed(() => {
  if (!employee.value) return ''
  return new Date(employee.value.hireDate).toLocaleDateString('zh-TW', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
})

const statusClass = computed(() => {
  switch (employee.value?.status) {
    case 'Active':    return 'status-active'
    case 'OnLeave':   return 'status-on-leave'
    case 'Resigned':  return 'status-resigned'
    default:          return ''
  }
})

// 非同步函式：呼叫 API
async function fetchEmployee() {
  const id = Number(searchId.value)
  if (!id || id <= 0) {
    error.value = '請輸入有效的員工 ID'
    return
  }

  loading.value = true
  error.value = null
  employee.value = null

  try {
    employee.value = await getEmployee(id)
  } catch (e: unknown) {
    // 後端回 404 時 axios 會拋錯
    error.value = '找不到此員工，請確認 ID 是否正確'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.employee-view {
  max-width: 600px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 1.5rem;
  color: #1a3a5c;
}

.search-bar {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.search-bar input {
  flex: 1;
  padding: 0.5rem 0.75rem;
  border: 1px solid #cdd5e0;
  border-radius: 6px;
  font-size: 1rem;
}

.search-bar button {
  padding: 0.5rem 1.25rem;
  background: #1a3a5c;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
}

.search-bar button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-msg {
  color: #d32f2f;
}

.hint {
  color: #7a8899;
}

.employee-card {
  background: white;
  border-radius: 10px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.emp-code {
  font-size: 0.85rem;
  color: #7a8899;
  font-family: monospace;
}

.emp-name {
  margin: 0 0 1.25rem;
  font-size: 1.4rem;
  color: #1a3a5c;
}

.status-badge {
  padding: 0.2rem 0.6rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 600;
}

.status-active    { background: #e8f5e9; color: #2e7d32; }
.status-on-leave  { background: #fff8e1; color: #f57f17; }
.status-resigned  { background: #fce4ec; color: #c62828; }

.info-grid {
  display: grid;
  grid-template-columns: 90px 1fr;
  gap: 0.6rem 1rem;
  margin: 0;
}

.info-grid dt {
  color: #7a8899;
  font-size: 0.85rem;
  align-self: center;
}

.info-grid dd {
  margin: 0;
  font-size: 0.95rem;
}
</style>
