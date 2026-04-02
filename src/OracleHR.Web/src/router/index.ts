import { createRouter, createWebHistory } from 'vue-router'
import EmployeeView from '@/views/EmployeeView.vue'
import DepartmentTreeView from '@/views/DepartmentTreeView.vue'
import SalaryView from '@/views/SalaryView.vue'
import PerformanceView from '@/views/PerformanceView.vue'

const routes = [
  { path: '/', redirect: '/employees' },

  // 員工查詢（主頁面）
  { path: '/employees', name: 'employee', component: EmployeeView },

  // 員工子頁面：路由參數 :id（useRoute().params.id 取值）
  { path: '/employees/:id/salaries', name: 'salary', component: SalaryView },
  { path: '/employees/:id/reviews', name: 'review', component: PerformanceView },

  // 組織架構
  { path: '/departments', name: 'department-tree', component: DepartmentTreeView },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
