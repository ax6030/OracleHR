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
  id: number
  empCode: string
  fullName: string
  email: string
  phone: string | null
  hireDate: string        // ISO 8601 日期字串
  status: string          // Active | OnLeave | Resigned
  departmentName: string | null
  managerName: string | null
}

/** GET /api/employees/{id} */
export async function getEmployee(id: number): Promise<EmployeeDto> {
  const { data } = await apiClient.get<EmployeeDto>(`/employees/${id}`)
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
