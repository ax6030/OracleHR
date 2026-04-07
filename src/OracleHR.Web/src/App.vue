<template>
  <div id="app-root">
    <!-- 導覽列 -->
    <nav class="navbar">
      <span class="brand">OracleHR</span>
      <div class="nav-links">
        <!--
          RouterLink = Vue Router 的連結元件
          active-class：當路由匹配時自動加上此 class
        -->
        <RouterLink to="/employees" active-class="active">員工查詢</RouterLink>
        <RouterLink to="/employees/manage" active-class="active">員工管理</RouterLink>
        <RouterLink to="/departments" active-class="active">組織架構</RouterLink>
      </div>
    </nav>

    <!-- 路由出口：目前路由對應的 View 會渲染在這裡 -->
    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>

<script setup lang="ts">
// Composition API 寫法：<script setup> 是 Vue 3 推薦的語法糖
// 在這個根元件不需要額外邏輯，只負責佈局
</script>

<style scoped>
/* scoped：這裡的 CSS 只作用在這個元件，不會污染全域 */
#app-root {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  font-family: 'Segoe UI', system-ui, sans-serif;
}

.navbar {
  display: flex;
  align-items: center;
  gap: 2rem;
  padding: 0 2rem;
  height: 56px;
  background: #1a3a5c;
  color: white;
}

.brand {
  font-size: 1.2rem;
  font-weight: 700;
  letter-spacing: 0.05em;
}

.nav-links {
  display: flex;
  gap: 1.5rem;
}

.nav-links a {
  color: rgba(255, 255, 255, 0.75);
  text-decoration: none;
  padding: 0.25rem 0;
  border-bottom: 2px solid transparent;
  transition: color 0.2s, border-color 0.2s;
}

.nav-links a:hover,
.nav-links a.active {
  color: white;
  border-bottom-color: #4fc3f7;
}

.main-content {
  flex: 1;
  padding: 2rem;
  background: #f5f7fa;
}
</style>
