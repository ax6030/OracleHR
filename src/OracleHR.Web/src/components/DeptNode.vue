<template>
  <li class="dept-node">
    <div
      class="node-row"
      :style="{ paddingLeft: `${(node.level - 1) * 20}px` }"
      @click="toggle"
    >
      <!-- 展開/收合箭頭：只有有子節點才顯示 -->
      <span class="arrow" :class="{ open: isOpen }">
        {{ children.length > 0 ? '▶' : '　' }}
      </span>
      <span class="dept-name">{{ node.deptName }}</span>
      <span class="dept-code">{{ node.deptCode }}</span>
    </div>

    <!--
      v-show：展開/收合用 v-show 保留 DOM，避免每次重新渲染子樹
      遞迴渲染：DeptNode 呼叫自己（需要在 <script setup> 裡可被引用）
    -->
    <ul v-show="isOpen" class="child-list">
      <DeptNode
        v-for="child in children"
        :key="child.id"
        :node="child"
        :all-nodes="allNodes"
      />
    </ul>
  </li>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { DepartmentNodeDto } from '@/services/api'

// defineProps：宣告此元件接受的 props（外部傳入的資料）
const props = defineProps<{
  node: DepartmentNodeDto
  allNodes: DepartmentNodeDto[]
}>()

const isOpen = ref(true)

// computed：找出屬於這個節點的子節點
const children = computed(() =>
  props.allNodes.filter(n => n.parentId === props.node.id)
)

function toggle() {
  if (children.value.length > 0) {
    isOpen.value = !isOpen.value
  }
}
</script>

<style scoped>
.dept-node {
  list-style: none;
}

.child-list {
  padding: 0;
  margin: 0;
}

.node-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem 0.5rem;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.15s;
}

.node-row:hover {
  background: #f0f4f8;
}

.arrow {
  font-size: 0.6rem;
  color: #7a8899;
  transition: transform 0.2s;
  display: inline-block;
  width: 1em;
}

.arrow.open {
  transform: rotate(90deg);
}

.dept-name {
  flex: 1;
  font-size: 0.95rem;
  color: #1a3a5c;
}

.dept-code {
  font-size: 0.75rem;
  color: #7a8899;
  font-family: monospace;
}
</style>
