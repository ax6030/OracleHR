<template>
  <li class="dept-node">
    <div
      class="node-row"
      :style="{ paddingLeft: `${(node.depth - 1) * 20}px` }"
      @click="toggle"
    >
      <span class="arrow" :class="{ open: isOpen }">
        {{ children.length > 0 ? '▶' : '　' }}
      </span>
      <span class="dept-name">{{ node.deptName }}</span>
    </div>

    <ul v-show="isOpen" class="child-list">
      <DeptNode
        v-for="child in children"
        :key="child.departmentId"
        :node="child"
        :all-nodes="allNodes"
      />
    </ul>
  </li>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { DepartmentNodeDto } from '@/services/api'

const props = defineProps<{
  node: DepartmentNodeDto
  allNodes: DepartmentNodeDto[]
}>()

const isOpen = ref(true)

const children = computed(() =>
  props.allNodes.filter(n => n.parentDeptId === props.node.departmentId)
)

function toggle() {
  if (children.value.length > 0) {
    isOpen.value = !isOpen.value
  }
}
</script>

<style scoped>
.dept-node { list-style: none; }
.child-list { padding: 0; margin: 0; }

.node-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem 0.5rem;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.15s;
}
.node-row:hover { background: #f0f4f8; }

.arrow {
  font-size: 0.6rem;
  color: #7a8899;
  transition: transform 0.2s;
  display: inline-block;
  width: 1em;
}
.arrow.open { transform: rotate(90deg); }

.dept-name {
  flex: 1;
  font-size: 0.95rem;
  color: #1a3a5c;
}
</style>
