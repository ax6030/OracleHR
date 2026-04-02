<template>
  <div class="perf-view">
    <div class="view-header">
      <RouterLink to="/employees" class="back-link">← 返回員工查詢</RouterLink>
      <h2>績效考核</h2>
      <p v-if="store.employee" class="subtitle">{{ store.employee.fullName }}</p>
    </div>

    <p v-if="store.loading" class="hint">載入中...</p>
    <p v-else-if="store.error" class="error-msg">{{ store.error }}</p>

    <div v-else-if="store.reviews.length > 0">
      <!-- 績效等級分布統計 -->
      <div class="grade-summary">
        <!--
          v-for 遍歷物件陣列，:key 用 grade 字母
          :class 動態綁定等級色票 class
        -->
        <div
          v-for="item in gradeSummary"
          :key="item.grade"
          :class="['grade-chip', `grade-${item.grade.toLowerCase()}`]"
        >
          <span class="grade-letter">{{ item.grade }}</span>
          <span class="grade-count">{{ item.count }} 次</span>
        </div>
      </div>

      <!-- 考核記錄卡片列表 -->
      <div class="review-list">
        <div
          v-for="review in store.reviews"
          :key="review.reviewId"
          class="review-card"
        >
          <div class="review-head">
            <div class="period">
              {{ review.reviewYear }} 年 Q{{ review.reviewQuarter }}
            </div>
            <span :class="['grade-badge', `grade-${review.grade.toLowerCase()}`]">
              {{ review.grade }}
            </span>
          </div>

          <div class="review-meta">
            <span>分數：{{ review.score }}</span>
            <span>考核人：{{ review.reviewerName }}</span>
            <span>日期：{{ formatDate(review.reviewDate) }}</span>
          </div>

          <!-- v-if：只有有 comments 才渲染段落 -->
          <p v-if="review.comments" class="review-comments">
            {{ review.comments }}
          </p>
        </div>
      </div>
    </div>

    <p v-else class="hint">此員工尚無績效考核記錄</p>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useEmployeeStore } from '@/stores/employeeStore'

const route = useRoute()
const router = useRouter()
const store = useEmployeeStore()

const employeeId = Number(route.params.id)

// computed：統計各等級出現次數
const gradeSummary = computed(() => {
  const grades = ['S', 'A', 'B', 'C', 'D']
  return grades
    .map(grade => ({
      grade,
      count: store.reviews.filter(r => r.grade === grade).length,
    }))
    .filter(item => item.count > 0)   // 只顯示有資料的等級
})

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('zh-TW', { year: 'numeric', month: '2-digit', day: '2-digit' })
}

onMounted(async () => {
  if (!employeeId) {
    router.push('/employees')
    return
  }
  await store.loadEmployee(employeeId)
  await store.loadReviews()
})
</script>

<style scoped>
.perf-view { max-width: 700px; margin: 0 auto; }

.view-header { margin-bottom: 1.5rem; }
.back-link { font-size: 0.85rem; color: #1a3a5c; text-decoration: none; }
.back-link:hover { text-decoration: underline; }
h2 { margin: 0.5rem 0 0.25rem; color: #1a3a5c; }
.subtitle { margin: 0; color: #7a8899; font-size: 0.9rem; }

.hint      { color: #7a8899; }
.error-msg { color: #d32f2f; }

/* 等級分布 */
.grade-summary { display: flex; gap: 0.75rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
.grade-chip {
  display: flex; align-items: center; gap: 0.4rem;
  padding: 0.4rem 0.8rem; border-radius: 20px; font-weight: 600;
}
.grade-letter { font-size: 1.1rem; }
.grade-count  { font-size: 0.8rem; opacity: 0.8; }

/* 等級色票（badge 和 chip 共用） */
.grade-s { background: #e8f5e9; color: #1b5e20; }
.grade-a { background: #e3f2fd; color: #0d47a1; }
.grade-b { background: #fff8e1; color: #e65100; }
.grade-c { background: #fce4ec; color: #880e4f; }
.grade-d { background: #f3e5f5; color: #4a148c; }

/* 考核卡片 */
.review-list { display: flex; flex-direction: column; gap: 1rem; }
.review-card {
  background: white; border-radius: 10px; padding: 1.25rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.07);
}
.review-head {
  display: flex; justify-content: space-between;
  align-items: center; margin-bottom: 0.75rem;
}
.period { font-size: 1rem; font-weight: 700; color: #1a3a5c; }
.grade-badge { padding: 0.2rem 0.75rem; border-radius: 12px; font-weight: 700; font-size: 0.9rem; }

.review-meta {
  display: flex; gap: 1.5rem; font-size: 0.82rem;
  color: #7a8899; margin-bottom: 0.75rem;
}

.review-comments {
  margin: 0; font-size: 0.88rem; color: #444;
  background: #f5f7fa; padding: 0.75rem; border-radius: 6px;
  line-height: 1.6;
}
</style>
