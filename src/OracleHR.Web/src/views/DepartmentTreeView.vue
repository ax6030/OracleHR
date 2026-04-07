<template>
  <div class="dept-view">
    <div class="view-header">
      <h2>組織架構</h2>
      <button @click="fetchTree" :disabled="loading">
        {{ loading ? '載入中...' : '重新整理' }}
      </button>
    </div>

    <p v-if="error" class="error-msg">{{ error }}</p>

    <div v-if="!loading && nodes.length > 0" class="tree-container">
      <ul class="tree-root">
        <DeptNode
          v-for="node in rootNodes"
          :key="node.departmentId"
          :node="node"
          :all-nodes="nodes"
        />
      </ul>
    </div>

    <p v-else-if="!loading" class="hint">尚無部門資料</p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { getDepartmentTree, type DepartmentNodeDto } from '@/services/api'
import DeptNode from '@/components/DeptNode.vue'

const nodes = ref<DepartmentNodeDto[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

// parentDeptId === null → 根節點
const rootNodes = computed(() =>
  nodes.value.filter(n => n.parentDeptId === null)
)

async function fetchTree() {
  loading.value = true
  error.value = null
  try {
    nodes.value = await getDepartmentTree()
  } catch {
    error.value = '載入部門資料失敗'
  } finally {
    loading.value = false
  }
}

onMounted(fetchTree)
</script>

<style scoped>
.dept-view { max-width: 700px; margin: 0 auto; }

.view-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}
.view-header h2 { margin: 0; color: #1a3a5c; }
.view-header button {
  padding: 0.4rem 1rem;
  background: #1a3a5c; color: white;
  border: none; border-radius: 6px; cursor: pointer;
}
.view-header button:disabled { opacity: 0.6; cursor: not-allowed; }

.tree-container {
  background: white; border-radius: 10px;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}
.tree-root { list-style: none; padding: 0; margin: 0; }

.error-msg { color: #d32f2f; }
.hint { color: #7a8899; }
</style>
