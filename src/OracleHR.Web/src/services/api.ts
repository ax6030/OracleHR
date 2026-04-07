import axios from 'axios'
import type { EmploymentStatus } from '@/types'

const apiClient = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
})

// ─── 員工相關 DTO ──────────────────────────────────────────────

export interface EmployeeListItemDto {
  employeeId: number
  empCode: string
  fullName: string
  jobTitle: string
  deptName: string
  status: string
}

export interface EmployeeDto {
  employeeId: number
  empCode: string
  fullName: string
  email: string
  jobTitle: string
  deptName: string
  baseSalary: number
  status: string
  hireDate: string   // ISO 8601
}

export interface CreateEmployeeRequest {
  firstName: string
  lastName: string
  email: string
  phone: string | null
  hireDate: string   // ISO 8601
  jobTitle: string
  departmentId: number
  managerId: number | null
  baseSalary: number
}

export interface UpdateEmployeeRequest {
  employeeId: number
  firstName: string
  lastName: string
  email: string
  phone: string | null
  jobTitle: string
  departmentId: number
  managerId: number | null
  baseSalary: number
  status: EmploymentStatus
}

export interface SalaryRecordDto {
  salaryId: number
  effectiveDate: string
  baseSalary: number
  bonus: number
  totalSalary: number
  remark: string | null
}

export interface PerformanceReviewDto {
  reviewId: number
  reviewYear: number
  reviewQuarter: number
  score: number
  grade: string
  comments: string | null
  reviewerName: string
  reviewDate: string
}

// 注意：字段名對應後端 GetDepartmentTree.DeptNodeDto 的 camelCase 序列化結果
export interface DepartmentNodeDto {
  departmentId: number
  deptName: string
  parentDeptId: number | null
  depth: number
  fullPath: string
  isLeaf: boolean
}

export interface DepartmentListItemDto {
  departmentId: number
  deptName: string
}

// ─── API 函式 ─────────────────────────────────────────────────

export async function listEmployees(): Promise<EmployeeListItemDto[]> {
  const { data } = await apiClient.get<EmployeeListItemDto[]>('/employees')
  return data
}

export async function getEmployee(id: number): Promise<EmployeeDto> {
  const { data } = await apiClient.get<EmployeeDto>(`/employees/${id}`)
  return data
}

export async function createEmployee(req: CreateEmployeeRequest): Promise<number> {
  const { data } = await apiClient.post<{ employeeId: number }>('/employees', req)
  return data.employeeId
}

export async function updateEmployee(id: number, req: UpdateEmployeeRequest): Promise<void> {
  await apiClient.put(`/employees/${id}`, req)
}

export async function deleteEmployee(id: number): Promise<void> {
  await apiClient.delete(`/employees/${id}`)
}

export async function getSalaryRecords(employeeId: number): Promise<SalaryRecordDto[]> {
  const { data } = await apiClient.get<SalaryRecordDto[]>(`/employees/${employeeId}/salaries`)
  return data
}

export async function getPerformanceReviews(employeeId: number): Promise<PerformanceReviewDto[]> {
  const { data } = await apiClient.get<PerformanceReviewDto[]>(`/employees/${employeeId}/reviews`)
  return data
}

export async function getDepartmentTree(): Promise<DepartmentNodeDto[]> {
  const { data } = await apiClient.get<DepartmentNodeDto[]>('/departments/tree')
  return data
}

export async function listDepartments(): Promise<DepartmentListItemDto[]> {
  const { data } = await apiClient.get<DepartmentListItemDto[]>('/departments')
  return data
}
