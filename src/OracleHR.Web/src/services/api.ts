import axios from 'axios'

// axios 實例：baseURL 指向後端
// 開發時 vite proxy 攔截 /api/* → http://localhost:6000
// 生產時 nginx 靜態服務，/api/* 直接打後端容器
const apiClient = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// ─── 員工相關 ───────────────────────────────────────────────

/** 後端回傳的員工 DTO（對應 GetEmployee.Dto） */
export interface EmployeeDto {
  employeeId: number
  empCode: string
  fullName: string
  email: string
  jobTitle: string
  deptName: string
  baseSalary: number
  status: string          // Active | OnLeave | Resigned
  hireDate: string        // ISO 8601 日期字串
}

/** GET /api/employees/{id} */
export async function getEmployee(id: number): Promise<EmployeeDto> {
  const { data } = await apiClient.get<EmployeeDto>(`/employees/${id}`)
  return data
}

/** 後端回傳的薪資記錄 DTO（對應 GetSalaryRecords.Dto） */
export interface SalaryRecordDto {
  salaryId: number
  effectiveDate: string   // ISO 8601
  baseSalary: number
  bonus: number
  totalSalary: number     // Oracle VIRTUAL column 計算值
  remark: string | null
}

/** GET /api/employees/{id}/salaries */
export async function getSalaryRecords(employeeId: number): Promise<SalaryRecordDto[]> {
  const { data } = await apiClient.get<SalaryRecordDto[]>(`/employees/${employeeId}/salaries`)
  return data
}

/** 後端回傳的績效考核 DTO（對應 GetPerformanceReviews.Dto） */
export interface PerformanceReviewDto {
  reviewId: number
  reviewYear: number
  reviewQuarter: number
  score: number
  grade: string           // S / A / B / C / D
  comments: string | null
  reviewerName: string
  reviewDate: string      // ISO 8601
}

/** GET /api/employees/{id}/reviews */
export async function getPerformanceReviews(employeeId: number): Promise<PerformanceReviewDto[]> {
  const { data } = await apiClient.get<PerformanceReviewDto[]>(`/employees/${employeeId}/reviews`)
  return data
}

// ─── 部門相關 ───────────────────────────────────────────────

/** 後端回傳的部門節點（CONNECT BY 拉平後的結構） */
export interface DepartmentNodeDto {
  id: number
  deptCode: string
  deptName: string
  level: number           // CONNECT BY 階層深度
  parentId: number | null
}

/** GET /api/departments/tree */
export async function getDepartmentTree(): Promise<DepartmentNodeDto[]> {
  const { data } = await apiClient.get<DepartmentNodeDto[]>('/departments/tree')
  return data
}
