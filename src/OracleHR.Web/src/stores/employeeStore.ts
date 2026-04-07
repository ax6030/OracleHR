import { defineStore } from 'pinia'
import { ref } from 'vue'
import {
  listEmployees,
  getEmployee,
  createEmployee,
  updateEmployee,
  deleteEmployee,
  getSalaryRecords,
  getPerformanceReviews,
  type EmployeeListItemDto,
  type EmployeeDto,
  type SalaryRecordDto,
  type PerformanceReviewDto,
  type CreateEmployeeRequest,
  type UpdateEmployeeRequest,
} from '@/services/api'

export const useEmployeeStore = defineStore('employee', () => {
  // ─── 列表狀態 ─────────────────────────────────────────────
  const employeeList = ref<EmployeeListItemDto[]>([])

  // ─── 單筆詳情狀態 ─────────────────────────────────────────
  const currentId  = ref<number | null>(null)
  const employee   = ref<EmployeeDto | null>(null)
  const salaries   = ref<SalaryRecordDto[]>([])
  const reviews    = ref<PerformanceReviewDto[]>([])

  const loading = ref(false)
  const error   = ref<string | null>(null)

  // ─── 讀取列表 ─────────────────────────────────────────────
  async function loadList() {
    loading.value = true
    error.value = null
    try {
      employeeList.value = await listEmployees()
    } catch {
      error.value = '載入員工列表失敗'
    } finally {
      loading.value = false
    }
  }

  // ─── 讀取單筆 ─────────────────────────────────────────────
  async function loadEmployee(id: number) {
    if (currentId.value === id && employee.value !== null) return

    loading.value = true
    error.value = null
    try {
      employee.value  = await getEmployee(id)
      currentId.value = id
      salaries.value  = []
      reviews.value   = []
    } catch {
      error.value    = '找不到此員工'
      employee.value = null
    } finally {
      loading.value = false
    }
  }

  async function loadSalaries() {
    if (!currentId.value || salaries.value.length > 0) return
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

  async function loadReviews() {
    if (!currentId.value || reviews.value.length > 0) return
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

  // ─── CRUD ─────────────────────────────────────────────────
  async function create(req: CreateEmployeeRequest): Promise<number | null> {
    loading.value = true
    error.value = null
    try {
      const id = await createEmployee(req)
      await loadList()   // 重新整理列表
      return id
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: string } })?.response?.data
      error.value = msg ?? '新增員工失敗'
      return null
    } finally {
      loading.value = false
    }
  }

  async function update(id: number, req: UpdateEmployeeRequest): Promise<boolean> {
    loading.value = true
    error.value = null
    try {
      await updateEmployee(id, req)
      // 清快取，讓下次 loadEmployee 重新抓取
      if (currentId.value === id) {
        employee.value = null
        currentId.value = null
      }
      await loadList()
      return true
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: string } })?.response?.data
      error.value = msg ?? '更新員工失敗'
      return false
    } finally {
      loading.value = false
    }
  }

  async function remove(id: number): Promise<boolean> {
    loading.value = true
    error.value = null
    try {
      await deleteEmployee(id)
      if (currentId.value === id) reset()
      await loadList()
      return true
    } catch {
      error.value = '刪除員工失敗'
      return false
    } finally {
      loading.value = false
    }
  }

  function reset() {
    currentId.value = null
    employee.value  = null
    salaries.value  = []
    reviews.value   = []
    error.value     = null
  }

  return {
    employeeList,
    currentId, employee, salaries, reviews,
    loading, error,
    loadList, loadEmployee, loadSalaries, loadReviews,
    create, update, remove, reset,
  }
})
