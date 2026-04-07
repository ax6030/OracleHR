<template>
  <div class="manage-view">
    <div class="view-header">
      <h2>員工管理</h2>
      <button class="btn-primary" @click="openCreate">+ 新增員工</button>
    </div>

    <p v-if="store.error" class="error-msg">{{ store.error }}</p>

    <!-- 員工列表 -->
    <div class="table-wrap">
      <table v-if="store.employeeList.length > 0">
        <thead>
          <tr>
            <th>員工編號</th>
            <th>姓名</th>
            <th>職稱</th>
            <th>部門</th>
            <th>狀態</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="emp in store.employeeList" :key="emp.employeeId">
            <td class="mono">{{ emp.empCode }}</td>
            <td>{{ emp.fullName }}</td>
            <td>{{ emp.jobTitle }}</td>
            <td>{{ emp.deptName }}</td>
            <td>
              <span :class="['badge', statusClass(emp.status)]">{{ emp.status }}</span>
            </td>
            <td class="actions">
              <RouterLink :to="`/employees/${emp.employeeId}`" class="btn-link">
                詳情
              </RouterLink>
              <button class="btn-edit" @click="openEdit(emp.employeeId)">編輯</button>
              <button class="btn-del" @click="confirmDelete(emp.employeeId, emp.fullName)">刪除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else-if="!store.loading" class="hint">尚無員工資料</p>
      <p v-if="store.loading" class="hint">載入中...</p>
    </div>

    <!-- 新增 / 編輯表單（Modal）-->
    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
        <h3>{{ editingId ? '編輯員工' : '新增員工' }}</h3>

        <div class="form-grid">
          <label>姓（Last Name） <span class="req">*</span>
            <input v-model="form.lastName" required />
          </label>
          <label>名（First Name） <span class="req">*</span>
            <input v-model="form.firstName" required />
          </label>
          <label>Email <span class="req">*</span>
            <input v-model="form.email" type="email" required />
          </label>
          <label>電話
            <input v-model="form.phone" />
          </label>
          <label>到職日 <span class="req">*</span>
            <input v-model="form.hireDate" type="date" required />
          </label>
          <label>職稱 <span class="req">*</span>
            <input v-model="form.jobTitle" required />
          </label>
          <label>部門 <span class="req">*</span>
            <select v-model="form.departmentId">
              <option value="">-- 選擇部門 --</option>
              <option
                v-for="d in departments"
                :key="d.departmentId"
                :value="d.departmentId"
              >{{ d.deptName }}</option>
            </select>
          </label>
          <label>底薪 <span class="req">*</span>
            <input v-model.number="form.baseSalary" type="number" min="0" required />
          </label>
          <label v-if="editingId">狀態
            <select v-model="form.status">
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
              <option value="Resigned">Resigned</option>
            </select>
          </label>
        </div>

        <p v-if="formError" class="error-msg">{{ formError }}</p>

        <div class="modal-footer">
          <button class="btn-cancel" @click="closeForm">取消</button>
          <button class="btn-primary" :disabled="store.loading" @click="submit">
            {{ store.loading ? '處理中...' : (editingId ? '儲存' : '新增') }}
          </button>
        </div>
      </div>
    </div>

    <!-- 刪除確認 -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="modal modal-sm">
        <h3>確認刪除</h3>
        <p>確定要刪除員工「{{ deleteTarget.name }}」嗎？此操作無法復原。</p>
        <div class="modal-footer">
          <button class="btn-cancel" @click="deleteTarget = null">取消</button>
          <button class="btn-del" :disabled="store.loading" @click="doDelete">
            {{ store.loading ? '刪除中...' : '確認刪除' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useEmployeeStore } from '@/stores/employeeStore'
import { listDepartments, getEmployee, type DepartmentListItemDto } from '@/services/api'
import type { EmploymentStatus } from '@/types'

const store = useEmployeeStore()

const departments = ref<DepartmentListItemDto[]>([])
const showForm    = ref(false)
const editingId   = ref<number | null>(null)
const formError   = ref<string | null>(null)

const deleteTarget = ref<{ id: number; name: string } | null>(null)

const emptyForm = () => ({
  firstName:    '',
  lastName:     '',
  email:        '',
  phone:        '',
  hireDate:     '',
  jobTitle:     '',
  departmentId: 0,
  managerId:    null as number | null,
  baseSalary:   0,
  status:       'Active' as EmploymentStatus,
})

const form = reactive(emptyForm())

onMounted(async () => {
  await store.loadList()
  departments.value = await listDepartments()
})

function openCreate() {
  Object.assign(form, emptyForm())
  editingId.value = null
  formError.value = null
  showForm.value  = true
}

async function openEdit(id: number) {
  editingId.value = id
  formError.value = null
  const emp = await getEmployee(id)
  // 拆回 firstName / lastName（fullName = lastName + ' ' + firstName）
  const parts = emp.fullName.split(' ')
  form.firstName    = parts[1] ?? ''
  form.lastName     = parts[0] ?? ''
  form.email        = emp.email
  form.phone        = ''
  form.hireDate     = emp.hireDate.substring(0, 10)
  form.jobTitle     = emp.jobTitle
  form.departmentId = 0   // 後端沒有直接回傳 deptId，先留空讓使用者重選
  form.baseSalary   = emp.baseSalary
  form.status       = emp.status as EmploymentStatus
  showForm.value    = true
}

function closeForm() {
  showForm.value  = false
  editingId.value = null
  formError.value = null
}

async function submit() {
  formError.value = null
  if (!form.lastName || !form.firstName || !form.email ||
      !form.hireDate || !form.jobTitle || !form.departmentId || !form.baseSalary) {
    formError.value = '請填寫所有必填欄位'
    return
  }

  if (editingId.value) {
    const ok = await store.update(editingId.value, {
      employeeId:   editingId.value,
      firstName:    form.firstName,
      lastName:     form.lastName,
      email:        form.email,
      phone:        form.phone || null,
      jobTitle:     form.jobTitle,
      departmentId: form.departmentId,
      managerId:    form.managerId,
      baseSalary:   form.baseSalary,
      status:       form.status,
    })
    if (ok) closeForm()
    else formError.value = store.error
  } else {
    const id = await store.create({
      firstName:    form.firstName,
      lastName:     form.lastName,
      email:        form.email,
      phone:        form.phone || null,
      hireDate:     new Date(form.hireDate).toISOString(),
      jobTitle:     form.jobTitle,
      departmentId: form.departmentId,
      managerId:    form.managerId,
      baseSalary:   form.baseSalary,
    })
    if (id !== null) closeForm()
    else formError.value = store.error
  }
}

function confirmDelete(id: number, name: string) {
  deleteTarget.value = { id, name }
}

async function doDelete() {
  if (!deleteTarget.value) return
  const ok = await store.remove(deleteTarget.value.id)
  if (ok) deleteTarget.value = null
}

function statusClass(status: string) {
  switch (status) {
    case 'Active':   return 'badge-active'
    case 'Inactive': return 'badge-inactive'
    case 'Resigned': return 'badge-resigned'
    default:         return ''
  }
}
</script>

<style scoped>
.manage-view { max-width: 1000px; margin: 0 auto; }

.view-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 1.5rem;
}
.view-header h2 { margin: 0; color: #1a3a5c; }

/* 表格 */
.table-wrap { background: white; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); overflow-x: auto; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid #eef0f3; font-size: 0.9rem; }
th { background: #f7f9fc; color: #7a8899; font-weight: 600; }
tr:last-child td { border-bottom: none; }
.mono { font-family: monospace; color: #7a8899; }

/* 狀態徽章 */
.badge { padding: 0.15rem 0.5rem; border-radius: 10px; font-size: 0.78rem; font-weight: 600; }
.badge-active   { background: #e8f5e9; color: #2e7d32; }
.badge-inactive { background: #fff8e1; color: #f57f17; }
.badge-resigned { background: #fce4ec; color: #c62828; }

/* 操作按鈕 */
.actions { display: flex; gap: 0.4rem; }
.btn-link { color: #1a3a5c; text-decoration: none; padding: 0.2rem 0.6rem; border: 1px solid #cdd5e0; border-radius: 4px; font-size: 0.82rem; }
.btn-link:hover { background: #f0f4f8; }
.btn-edit { padding: 0.2rem 0.6rem; background: #e3f2fd; color: #1565c0; border: 1px solid #bbdefb; border-radius: 4px; cursor: pointer; font-size: 0.82rem; }
.btn-del  { padding: 0.2rem 0.6rem; background: #fce4ec; color: #c62828; border: 1px solid #f8bbd0; border-radius: 4px; cursor: pointer; font-size: 0.82rem; }

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.4);
  display: flex; align-items: center; justify-content: center; z-index: 100;
}
.modal {
  background: white; border-radius: 12px; padding: 2rem;
  width: 560px; max-width: 95vw; max-height: 85vh; overflow-y: auto;
}
.modal-sm { width: 380px; }
.modal h3 { margin: 0 0 1.5rem; color: #1a3a5c; }

/* 表單 */
.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.form-grid label { display: flex; flex-direction: column; font-size: 0.85rem; color: #555; }
.form-grid label:nth-child(3),
.form-grid label:nth-child(6) { grid-column: 1 / -1; }
.form-grid input,
.form-grid select {
  margin-top: 0.3rem; padding: 0.45rem 0.6rem;
  border: 1px solid #cdd5e0; border-radius: 6px; font-size: 0.9rem;
}
.req { color: #d32f2f; }

.modal-footer { display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.5rem; }

/* 通用按鈕 */
.btn-primary {
  padding: 0.5rem 1.25rem; background: #1a3a5c; color: white;
  border: none; border-radius: 6px; cursor: pointer; font-size: 0.9rem;
}
.btn-primary:disabled { opacity: 0.6; cursor: not-allowed; }
.btn-cancel {
  padding: 0.5rem 1.25rem; background: white; color: #555;
  border: 1px solid #cdd5e0; border-radius: 6px; cursor: pointer; font-size: 0.9rem;
}

.error-msg { color: #d32f2f; margin: 0.5rem 0; }
.hint { padding: 1.5rem; color: #7a8899; text-align: center; }
</style>
