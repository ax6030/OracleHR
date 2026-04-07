import { createRouter, createWebHistory } from 'vue-router'
import EmployeeView       from '@/views/EmployeeView.vue'
import EmployeeManageView from '@/views/EmployeeManageView.vue'
import DepartmentTreeView from '@/views/DepartmentTreeView.vue'
import SalaryView         from '@/views/SalaryView.vue'
import PerformanceView    from '@/views/PerformanceView.vue'

const routes = [
  { path: '/', redirect: '/employees' },
  { path: '/employees',         name: 'employee',        component: EmployeeView },
  { path: '/employees/manage',  name: 'employee-manage', component: EmployeeManageView },
  { path: '/employees/:id/salaries', name: 'salary',     component: SalaryView },
  { path: '/employees/:id/reviews',  name: 'review',     component: PerformanceView },
  { path: '/departments',       name: 'department-tree', component: DepartmentTreeView },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
