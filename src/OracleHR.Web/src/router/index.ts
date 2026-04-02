import { createRouter, createWebHistory } from 'vue-router'
import EmployeeView from '@/views/EmployeeView.vue'
import DepartmentTreeView from '@/views/DepartmentTreeView.vue'

// 路由表：每個 path 對應一個 View 元件
const routes = [
  {
    path: '/',
    redirect: '/employees',
  },
  {
    path: '/employees',
    name: 'employee',
    component: EmployeeView,
  },
  {
    path: '/departments',
    name: 'department-tree',
    component: DepartmentTreeView,
  },
]

const router = createRouter({
  // history mode：URL 不含 #（需要 nginx try_files 配合）
  history: createWebHistory(),
  routes,
})

export default router
