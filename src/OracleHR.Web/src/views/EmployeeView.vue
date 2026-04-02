<template>
  <div class="employee-view">
    <h2>員工查詢</h2>

    <div class="search-bar">
      <input
        v-model="searchId"
        type="number"
        placeholder="輸入員工 ID"
        min="1"
        @keyup.enter="search"
      />
      <button @click="search" :disabled="store.loading">
        {{ store.loading ? '查詢中...' : '查詢' }}
      </button>
    </div>

    <p v-if="store.error" class="error-msg">{{ store.error }}</p>

    <div v-else-if="store.employee" class="employee-card">
      <div class="card-header">
        <span class="emp-code">{{ store.employee.empCode }}</span>
        <span :class="['status-badge', statusClass]">{{ store.employee.status }}</span>
      </div>

      <h3 class="emp-name">{{ store.employee.fullName }}</h3>

      <dl class="info-grid">
        <dt>職稱</dt>
        <dd>{{ store.employee.jobTitle }}</dd>

        <dt>Email</dt>
        <dd>{{ store.employee.email }}</dd>

        <dt>到職日</dt>
        <dd>{{ formattedHireDate }}</dd>

        <dt>部門</dt>
        <dd>{{ store.employee.deptName }}</dd>

        <dt>底薪</dt>
        <dd>{{ formatCurrency(store.employee.baseSalary) }}</dd>
      </dl>

      <!-- 導覽到子頁面 -->
      <div class="sub-links">
        <RouterLink :to="`/employees/${store.currentId}/salaries`" class="sub-link">
          薪資記錄 →
        </RouterLink>
        <RouterLink :to="`/employees/${store.currentId}/reviews`" class="sub-link">
          績效考核 →
        </RouterLink>
      </div>
    </div>

    <p v-else class="hint">請輸入員工 ID 開始查詢</p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useEmployeeStore } from '@/stores/employeeStore'

// 從 store 取資料，不再自己 call API
const store = useEmployeeStore()
const searchId = ref<string>(store.currentId?.toString() ?? '')

const formattedHireDate = computed(() => {
  if (!store.employee) return ''
  return new Date(store.employee.hireDate).toLocaleDateString('zh-TW', {
    year: 'numeric', month: '2-digit', day: '2-digit',
  })
})

const statusClass = computed(() => {
  switch (store.employee?.status) {
    case 'Active':   return 'status-active'
    case 'OnLeave':  return 'status-on-leave'
    case 'Resigned': return 'status-resigned'
    default:         return ''
  }
})

function formatCurrency(val: number) {
  return new Intl.NumberFormat('zh-TW', { style: 'currency', currency: 'TWD', maximumFractionDigits: 0 }).format(val)
}

async function search() {
  const id = Number(searchId.value)
  if (!id || id <= 0) return
  await store.loadEmployee(id)
}
</script>

<style scoped>
.employee-view { max-width: 600px; margin: 0 auto; }
h2 { margin-bottom: 1.5rem; color: #1a3a5c; }

.search-bar { display: flex; gap: 0.5rem; margin-bottom: 1.5rem; }
.search-bar input {
  flex: 1; padding: 0.5rem 0.75rem;
  border: 1px solid #cdd5e0; border-radius: 6px; font-size: 1rem;
}
.search-bar button {
  padding: 0.5rem 1.25rem; background: #1a3a5c; color: white;
  border: none; border-radius: 6px; cursor: pointer; font-size: 1rem;
}
.search-bar button:disabled { opacity: 0.6; cursor: not-allowed; }

.error-msg { color: #d32f2f; }
.hint { color: #7a8899; }

.employee-card {
  background: white; border-radius: 10px;
  padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}
.card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; }
.emp-code { font-size: 0.85rem; color: #7a8899; font-family: monospace; }
.emp-name { margin: 0 0 1.25rem; font-size: 1.4rem; color: #1a3a5c; }

.status-badge { padding: 0.2rem 0.6rem; border-radius: 12px; font-size: 0.8rem; font-weight: 600; }
.status-active   { background: #e8f5e9; color: #2e7d32; }
.status-on-leave { background: #fff8e1; color: #f57f17; }
.status-resigned { background: #fce4ec; color: #c62828; }

.info-grid { display: grid; grid-template-columns: 80px 1fr; gap: 0.6rem 1rem; margin: 0 0 1.5rem; }
.info-grid dt { color: #7a8899; font-size: 0.85rem; align-self: center; }
.info-grid dd { margin: 0; font-size: 0.95rem; }

.sub-links { display: flex; gap: 1rem; border-top: 1px solid #eef0f3; padding-top: 1rem; }
.sub-link {
  color: #1a3a5c; text-decoration: none; font-size: 0.9rem;
  padding: 0.4rem 0.8rem; border: 1px solid #cdd5e0;
  border-radius: 6px; transition: background 0.15s;
}
.sub-link:hover { background: #f0f4f8; }
</style>
