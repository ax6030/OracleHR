import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'

// 建立 Vue 應用實例
const app = createApp(App)

// 安裝插件：狀態管理（Pinia）、路由（Vue Router）
app.use(createPinia())
app.use(router)

// 掛載到 index.html 的 <div id="app">
app.mount('#app')
