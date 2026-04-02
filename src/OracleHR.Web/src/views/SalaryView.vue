<template>
  <div class="salary-view">
    <div class="view-header">
      <!-- RouterLink 帶 id 參數回到員工頁 -->
      <RouterLink :to="`/employees`" class="back-link">← 返回員工查詢</RouterLink>
      <h2>薪資記錄</h2>
      <p v-if="store.employee" class="subtitle">{{ store.employee.fullName }}</p>
    </div>

    <p v-if="store.loading" class="hint">載入中...</p>
    <p v-else-if="store.error" class="error-msg">{{ store.error }}</p>

    <!-- 薪資統計卡 -->
    <div v-else-if="store.salaries.length > 0">
      <div class="stat-cards">
        <div class="stat-card">
          <span class="stat-label">最新底薪</span>
          <span class="stat-value">{{ formatCurrency(latest.baseSalary) }}</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">最新獎金</span>
          <span class="stat-value">{{ formatCurrency(latest.bonus) }}</span>
        </div>
        <div class="stat-card highlight">
          <span class="stat-label">最新總薪</span>
          <span class="stat-value">{{ formatCurrency(latest.totalSalary) }}</span>
        </div>
      </div>

      <!-- 薪資記錄表格 -->
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>生效日期</th>
              <th class="num">底薪</th>
              <th class="num">獎金</th>
              <th class="num">總薪資</th>
              <th>備註</th>
            </tr>
          </thead>
          <tbody>
            <!--
              v-for 搭配 :key：Vue 用 key 精準更新 DOM
              這裡用 salaryId 作為唯一 key
            -->
            <tr v-for="record in store.salaries" :key="record.salaryId">
              <td>{{ formatDate(record.effectiveDate) }}</td>
              <td class="num">{{ formatCurrency(record.baseSalary) }}</td>
              <td class="num">{{ formatCurrency(record.bonus) }}</td>
              <td class="num bold">{{ formatCurrency(record.totalSalary) }}</td>
              <td class="remark">{{ record.remark ?? '—' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <p v-else class="hint">此員工尚無薪資記錄</p>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useEmployeeStore } from '@/stores/employeeStore'

const route = useRoute()
const router = useRouter()
const store = useEmployeeStore()

// 從路由參數取得員工 ID
const employeeId = Number(route.params.id)

// computed：取最新一筆薪資（後端已按日期降冪排列）
const latest = computed(() => store.salaries[0])

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('zh-TW', { year: 'numeric', month: '2-digit', day: '2-digit' })
}

function formatCurrency(val: number) {
  return new Intl.NumberFormat('zh-TW', { style: 'currency', currency: 'TWD', maximumFractionDigits: 0 }).format(val)
}

onMounted(async () => {
  if (!employeeId) {
    router.push('/employees')
    return
  }
  // 先確保員工基本資料已載入（store 有快取則不重複 fetch）
  await store.loadEmployee(employeeId)
  // 再載入薪資記錄
  await store.loadSalaries()
})
</script>

<style scoped>
.salary-view { max-width: 800px; margin: 0 auto; }

.view-header { margin-bottom: 1.5rem; }
.back-link { font-size: 0.85rem; color: #1a3a5c; text-decoration: none; }
.back-link:hover { text-decoration: underline; }
h2 { margin: 0.5rem 0 0.25rem; color: #1a3a5c; }
.subtitle { margin: 0; color: #7a8899; font-size: 0.9rem; }

.hint  { color: #7a8899; }
.error-msg { color: #d32f2f; }

.stat-cards {
  display: grid; grid-template-columns: repeat(3, 1fr);
  gap: 1rem; margin-bottom: 1.5rem;
}
.stat-card {
  background: white; border-radius: 10px; padding: 1.25rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.07);
  display: flex; flex-direction: column; gap: 0.4rem;
}
.stat-card.highlight { background: #1a3a5c; }
.stat-card.highlight .stat-label,
.stat-card.highlight .stat-value { color: white; }

.stat-label { font-size: 0.8rem; color: #7a8899; }
.stat-value { font-size: 1.3rem; font-weight: 700; color: #1a3a5c; }

.table-wrap {
  background: white; border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.07); overflow: hidden;
}
table { width: 100%; border-collapse: collapse; }
thead { background: #f5f7fa; }
th, td { padding: 0.75rem 1rem; text-align: left; font-size: 0.9rem; }
th { color: #7a8899; font-weight: 600; border-bottom: 1px solid #eef0f3; }
td { border-bottom: 1px solid #f5f7fa; }
tr:last-child td { border-bottom: none; }
tr:hover td { background: #fafbfc; }

.num  { text-align: right; font-family: 'Courier New', monospace; }
.bold { font-weight: 700; color: #1a3a5c; }
.remark { color: #7a8899; font-size: 0.85rem; }
</style>
