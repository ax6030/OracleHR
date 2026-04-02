<template>
  <div class="dept-view">
    <div class="view-header">
      <h2>組織架構</h2>
      <!--
        @click：事件綁定（等同原生 onclick）
        :disabled：動態屬性綁定（: 是 v-bind: 的縮寫）
      -->
      <button @click="fetchTree" :disabled="loading">
        {{ loading ? '載入中...' : '重新整理' }}
      </button>
    </div>

    <p v-if="error" class="error-msg">{{ error }}</p>

    <!--
      v-if vs v-show 差異：
      v-if  → 條件不成立時，DOM 節點完全不存在
      v-show → 條件不成立時，DOM 存在但 display:none
      這裡用 v-if，因為初始沒有資料，不需要保留節點
    -->
    <div v-if="!loading && nodes.length > 0" class="tree-container">
      <!--
        v-for：列表渲染，:key 讓 Vue 識別每個節點
        只渲染最頂層節點（parentId === null），
        子節點由元件遞迴處理
      -->
      <ul class="tree-root">
        <DeptNode
          v-for="node in rootNodes"
          :key="node.id"
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

// computed：從扁平陣列篩出頂層節點
const rootNodes = computed(() =>
  nodes.value.filter(n => n.parentId === null)
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

// onMounted：元件掛載到 DOM 後執行（類似 React useEffect with []）
onMounted(fetchTree)
</script>

<style scoped>
.dept-view {
  max-width: 700px;
  margin: 0 auto;
}

.view-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.view-header h2 {
  margin: 0;
  color: #1a3a5c;
}

.view-header button {
  padding: 0.4rem 1rem;
  background: #1a3a5c;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.view-header button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.tree-container {
  background: white;
  border-radius: 10px;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.tree-root {
  list-style: none;
  padding: 0;
  margin: 0;
}

.error-msg { color: #d32f2f; }
.hint      { color: #7a8899; }
</style>
