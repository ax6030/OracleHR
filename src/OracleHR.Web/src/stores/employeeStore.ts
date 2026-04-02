import { defineStore } from 'pinia'
import { ref } from 'vue'
import {
  getEmployee,
  getSalaryRecords,
  getPerformanceReviews,
  type EmployeeDto,
  type SalaryRecordDto,
  type PerformanceReviewDto,
} from '@/services/api'

/**
 * Pinia Store：employeeStore
 *
 * 職責：
 * - 持有「目前選定員工」的所有資料（基本資料、薪資、績效）
 * - 讓多個 View 共用同一份資料，不重複呼叫 API
 * - 集中管理 loading / error 狀態
 *
 * 使用方式（在任何 .vue 檔案中）：
 *   const store = useEmployeeStore()
 *   await store.loadEmployee(1)
 *   store.employee    // 員工資料
 *   store.salaries    // 薪資列表
 */
export const useEmployeeStore = defineStore('employee', () => {
  // ─── State（響應式狀態）────────────────────────────────────
  // 用 ref() 定義，等同 Vue 2 Options API 的 data()
  const currentId = ref<number | null>(null)
  const employee = ref<EmployeeDto | null>(null)
  const salaries = ref<SalaryRecordDto[]>([])
  const reviews = ref<PerformanceReviewDto[]>([])

  const loading = ref(false)
  const error = ref<string | null>(null)

  // ─── Actions（方法）────────────────────────────────────────
  // 載入員工基本資料（先查再快取，同一 ID 不重複 fetch）
  async function loadEmployee(id: number) {
    if (currentId.value === id && employee.value !== null) return

    loading.value = true
    error.value = null
    try {
      employee.value = await getEmployee(id)
      currentId.value = id
      // 切換員工時清掉舊的薪資 / 績效資料
      salaries.value = []
      reviews.value = []
    } catch {
      error.value = '找不到此員工'
      employee.value = null
    } finally {
      loading.value = false
    }
  }

  // 載入薪資記錄（只在資料為空時才 fetch）
  async function loadSalaries() {
    if (!currentId.value) return
    if (salaries.value.length > 0) return   // 已有快取，不重複呼叫

    loading.value = true
    error.value = null
    try {
      salaries.value = await getSalaryRecords(currentId.value)
    } catch {
      error.value = '載入薪資記錄失敗'
    } finally {
      loading.value = false
    }
  }

  // 載入績效考核
  async function loadReviews() {
    if (!currentId.value) return
    if (reviews.value.length > 0) return

    loading.value = true
    error.value = null
    try {
      reviews.value = await getPerformanceReviews(currentId.value)
    } catch {
      error.value = '載入績效考核失敗'
    } finally {
      loading.value = false
    }
  }

  // 切換員工時重置所有狀態
  function reset() {
    currentId.value = null
    employee.value = null
    salaries.value = []
    reviews.value = []
    error.value = null
  }

  // ─── 回傳給外部使用的 state 與 actions ─────────────────────
  // defineStore 的 setup 寫法：把要暴露的都 return 出去
  return {
    currentId,
    employee,
    salaries,
    reviews,
    loading,
    error,
    loadEmployee,
    loadSalaries,
    loadReviews,
    reset,
  }
})
