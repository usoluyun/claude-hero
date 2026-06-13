# 导航栏重组计划 (Navigation Redesign)

## TL;DR

**目标**:将混乱的 10 项一级导航重组为 5 项极简结构,统一 3 类页面(index/mechanism/docs)的导航体验。

**改动范围**:
- CSS:`site/public/css/docs.css`(重写下拉系统)
- HTML:7 个页面(index.html, mechanism.html, docs-index.html, 6 个 doc pages)

**预计工作量**:30-40 分钟

**风险**:低(纯前端,不涉及后端逻辑)

---

## 问题诊断

### 现状

```
index.html (10 项一级导航 + 1 个下拉):
[领航 HERO]  理念  原理  能力  角色  组队  文档▾  机制  安装  自建
                                            ↑
                                          卡在中间

mechanism.html (7 项 + 1 个下拉,完全不同的结构):
[领航 HERO]  首页  架构  协作  调度  工作流  特性  文档▾

doc pages (用 docs-nav 类名,与 topnav 不兼容):
[领航 HERO]  首页  机制  文档▾
```

### 3 个核心问题

1. **视觉拥挤**:index.html 顶部 10 个一级项挤在一行,移动端必然换行/溢出
2. **样式断裂**:HTML 用 `<button class="dropdown-btn">`,但 docs.css 写的是 `.docs-dropdown` → **下拉可能根本没生效**
3. **逻辑混乱**:
   - "机制" 页的锚点(架构/协作/调度/工作流/特性)本质是"原理"的子话题
   - "安装"和"自建"是行动类,不该和说明类混排
   - 三个页面导航结构完全不同,用户跳转时失去空间感

---

## 新导航结构

### 顶层(5 项)

```
[领航 HERO]    首页   原理▾   角色▾   文档▾   安装▾
                  ↓      ↓       ↓       ↓       ↓
               → /    mechan.  index   docs    index
                      .html   .html   中心    .html
```

### 下拉菜单内容

#### 1. **原理▾** → 跳转到 `mechanism.html` 的各个锚点

| 菜单项 | 链接 | 说明 |
|-------|------|------|
| 整体架构 | `mechanism.html#architecture` | 5 层架构图 |
| Agent 协作 | `mechanism.html#collaboration` | Wave 工作流 |
| Skill 调度 | `mechanism.html#skill-dispatch` | 4 大核心 Skill |
| 工作流执行 | `mechanism.html#workflow` | 可视化 Demo |
| 隐藏特性 | `mechanism.html#hidden-features` | 高级功能 |

#### 2. **角色▾** → 跳转到 `index.html` 的角色相关章节

| 菜单项 | 链接 | 说明 |
|-------|------|------|
| 角色介绍 | `index.html#roles` | 9 个 Agent 角色 |
| 组队模式 | `index.html#teams` | Agent 协作 |

#### 3. **文档▾** → 跳转到 `pages/` 下的文档页面

| 菜单项 | 链接 | 说明 |
|-------|------|------|
| 📚 文档中心 | `docs-index.html` | 文档首页 |
| ───────── | (分隔线) | |
| 🏗️ Agent 分层架构 | `pages/hero-agent-layers.html` | 多层架构设计 |
| ⚙️ 工作流详解 | `pages/workflow.html` | 完整工作流程 |
| 🔄 PRD 转 Java | `pages/prd-to-java.html` | 开发流水线 |
| 📊 CodeGraph | `pages/codegraph.html` | 代码图谱 |
| 🔄 刷新机制 | `pages/refresh.html` | 知识保鲜 |
| 🚀 新人入门 | `pages/onboarding.html` | 快速上手 |

#### 4. **安装▾** → 跳转到 `index.html` 的安装相关章节

| 菜单项 | 链接 | 说明 |
|-------|------|------|
| 10 分钟安装 | `index.html#install` | 快速开始 |
| 自建领航员 | `index.html#build-pilot` | 创建自己的 Agent |
| 卸载 | `index.html#uninstall` | 清理指南 |

### 链接路径规则

不同页面类型的相对路径不同:

| 页面类型 | 路径前缀 | 示例 |
|---------|---------|------|
| `index.html`,`mechanism.html` | (无前缀) | `mechanism.html#architecture` |
| `docs-index.html` | (无前缀) | `pages/hero-agent-layers.html` |
| `pages/*.html` | `../` | `../mechanism.html#architecture` |

---

## 执行任务

### Task 1:重写下拉菜单 CSS (25 min)

**文件**:`site/public/css/docs.css`

**目标**:删除旧的 `.docs-dropdown` 系统,新增 `.dropdown` / `.dropdown-btn` / `.dropdown-content` 系统。

**具体要求**:

1. **删除旧代码**(约 100 行):
   ```css
   /* 删除以下选择器 */
   .docs-dropdown { ... }
   .docs-nav-item:hover .docs-dropdown { ... }
   .docs-dropdown::before { ... }
   .docs-dropdown-item { ... }
   .docs-dropdown-link { ... }
   .docs-dropdown-link:hover { ... }
   .docs-dropdown-link.is-current { ... }
   ```

2. **新增下拉系统**:
   ```css
   /* ========================================
      下拉菜单系统 — Dropdown Menu System
      ======================================== */

   /* 下拉容器:相对定位,悬停展开 */
   .dropdown {
     position: relative;
   }

   /* 下拉按钮:与普通链接风格一致 */
   .dropdown-btn {
     display: flex;
     align-items: center;
     gap: var(--space-xs);
     font-size: var(--text-sm);
     color: var(--color-baiyan);
     opacity: 0.8;
     letter-spacing: 0.04em;
     padding: var(--space-sm) var(--space-md);
     border-radius: var(--radius-sm);
     transition: all 0.25s ease;
     cursor: pointer;
     background: none;
     border: none;
     font-family: inherit;
   }

   .dropdown-btn:hover {
     opacity: 1;
     color: var(--color-bronze-soft);
     background: rgba(234, 228, 218, 0.08);
   }

   /* 箭头:悬停时 180° 旋转 */
   .dropdown-btn::after {
     content: '▾';
     font-size: var(--text-xs);
     opacity: 0.6;
     transition: transform 0.25s ease;
   }

   .dropdown.open .dropdown-btn::after,
   .dropdown:hover .dropdown-btn::after {
     transform: rotate(180deg);
   }

   /* 下拉内容面板 */
   .dropdown-content {
     position: absolute;
     top: calc(100% + var(--space-sm));
     left: 0;
     min-width: 240px;
     background: var(--color-white);
     border: 1px solid var(--color-line);
     border-radius: var(--radius-md);
     box-shadow: var(--shadow-lg);
     opacity: 0;
     visibility: hidden;
     transform: translateY(-8px);
     transition:
       opacity 0.25s ease,
       visibility 0.25s ease,
       transform 0.25s ease;
     list-style: none;
     margin: 0;
     padding: var(--space-sm) 0;
     z-index: 1000;
   }

   /* 悬停展开;移动端改用 .open class 展开(JS 切换) */
   .dropdown:hover .dropdown-content,
   .dropdown.open .dropdown-content {
     opacity: 1;
     visibility: visible;
     transform: translateY(0);
   }

   /* 顶部小三角,强化菜单来源感 */
   .dropdown-content::before {
     content: '';
     position: absolute;
     top: -6px;
     left: 24px;
     border-left: 6px solid transparent;
     border-right: 6px solid transparent;
     border-bottom: 6px solid var(--color-white);
   }

   /* 下拉菜单项 */
   .dropdown-content a {
     display: block;
     padding: var(--space-sm) var(--space-lg);
     font-size: var(--text-sm);
     color: var(--color-ink-70);
     text-decoration: none;
     transition: all 0.2s ease;
     border-left: 3px solid transparent;
   }

   .dropdown-content a:hover {
     background: var(--color-baiyan);
     color: var(--color-woye);
     border-left-color: var(--color-bronze);
     padding-left: calc(var(--space-lg) + 4px);
   }

   /* 当前页样式 */
   .dropdown-content a.active {
     background: var(--color-baiyan);
     color: var(--color-woye);
     font-weight: var(--font-medium);
     border-left-color: var(--color-bronze);
   }

   /* 分隔线 */
   .dropdown-content hr {
     margin: var(--space-xs) var(--space-md);
     border: none;
     border-top: 1px solid var(--color-line-light);
   }

   /* 移动端菜单按钮(桌面隐藏) */
   .nav-toggle {
     display: none;
     background: none;
     border: none;
     color: var(--color-baiyan);
     font-size: var(--text-xl);
     padding: var(--space-sm);
     cursor: pointer;
     line-height: 1;
   }

   /* ========================================
      响应式 — 移动端
      ======================================== */
   @media (max-width: 768px) {
     .topnav-links {
       display: none;
       flex-direction: column;
       gap: var(--space-sm);
       width: 100%;
       padding: var(--space-md) 0;
     }

     .topnav.is-menu-open .topnav-links {
       display: flex;
     }

     .nav-toggle {
       display: block;
     }

     .dropdown-content {
       position: static;
       opacity: 1;
       visibility: visible;
       transform: none;
       box-shadow: none;
       border-radius: 0;
       border: none;
       background: rgba(234, 228, 218, 0.05);
       margin-top: var(--space-xs);
     }

     .dropdown-content::before {
       display: none;
     }

     .dropdown-content a {
       padding: var(--space-sm) var(--space-xl);
     }
   }
   ```

3. **验证**:
   - 桌面端:鼠标悬停 250ms 后展开,平滑过渡
   - 移动端:点击按钮展开/收起
   - 箭头旋转动画
   - 所有下拉菜单样式一致

**验收标准**:
- [x] 旧 `.docs-dropdown` 代码全部删除
- [x] 新 `.dropdown` 系统完整实现
- [x] 桌面悬停 + 移动端点击都工作
- [x] 箭头旋转动画流畅
- [x] 响应式断点正确(768px)

---

### Task 2:更新 index.html 导航 (15 min)

**文件**:`site/public/index.html`

**目标**:替换顶部导航为 5 项结构。

**当前**(第 87-130 行):
```html
<nav class="topnav">
  <div class="topnav-inner">
    <a class="topnav-brand" href="/">领航 <span class="topnav-brand-en">HERO</span></a>
    <button class="nav-toggle" aria-label="菜单">☰</button>
    <ul class="topnav-links">
      <li><a href="#idea">理念</a></li>
      <li><a href="#how">原理</a></li>
      <li><a href="#skills">能力</a></li>
      <li><a href="#pilots">试点</a></li>
      <li><a href="#roles">角色</a></li>
      <li><a href="#issue">Issue 驱动</a></li>
      <li><a href="#teams">组队</a></li>
      <li><a href="#install">安装</a></li>
      <li><a href="#uninstall">卸载</a></li>
      <li><a href="#build-pilot">领航英雄</a></li>
      <li><a href="mechanism.html">机制</a></li>
      <li class="dropdown">
        <button class="dropdown-btn">文档 ▾</button>
        <div class="dropdown-content">
          <a href="docs-index.html">文档中心</a>
          <hr>
          <a href="pages/hero-agent-layers.html">🏗️ Agent 分层架构</a>
          ...
        </div>
      </li>
    </ul>
  </div>
</nav>
```

**替换为**:
```html
<nav class="topnav">
  <div class="topnav-inner">
    <a class="topnav-brand" href="/">领航 <span class="topnav-brand-en">HERO</span></a>
    <button class="nav-toggle" aria-label="菜单">☰</button>
    <ul class="topnav-links">
      <li><a href="/">首页</a></li>

      <!-- 原理下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">原理 ▾</button>
        <div class="dropdown-content">
          <a href="mechanism.html#architecture">整体架构</a>
          <a href="mechanism.html#collaboration">Agent 协作</a>
          <a href="mechanism.html#skill-dispatch">Skill 调度</a>
          <a href="mechanism.html#workflow">工作流执行</a>
          <hr>
          <a href="mechanism.html#hidden-features">隐藏特性</a>
        </div>
      </li>

      <!-- 角色下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">角色 ▾</button>
        <div class="dropdown-content">
          <a href="#roles">角色介绍</a>
          <a href="#teams">组队模式</a>
        </div>
      </li>

      <!-- 文档下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">文档 ▾</button>
        <div class="dropdown-content">
          <a href="docs-index.html">📚 文档中心</a>
          <hr>
          <a href="pages/hero-agent-layers.html">🏗️ Agent 分层架构</a>
          <a href="pages/workflow.html">⚙️ 工作流详解</a>
          <a href="pages/prd-to-java.html">🔄 PRD 转 Java</a>
          <a href="pages/codegraph.html">📊 CodeGraph</a>
          <a href="pages/refresh.html">🔄 刷新机制</a>
          <a href="pages/onboarding.html">🚀 新人入门</a>
        </div>
      </li>

      <!-- 安装下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">安装 ▾</button>
        <div class="dropdown-content">
          <a href="#install">10 分钟安装</a>
          <a href="#build-pilot">自建领航员</a>
          <hr>
          <a href="#uninstall">卸载</a>
        </div>
      </li>
    </ul>
  </div>
</nav>
```

**新增 JavaScript**(放在 `</body>` 前):
```html
<script>
  // 移动端菜单切换
  document.querySelector('.nav-toggle').addEventListener('click', () => {
    document.querySelector('.topnav').classList.toggle('is-menu-open');
  });

  // 移动端下拉菜单切换(点击而非悬停)
  if (window.innerWidth <= 768) {
    document.querySelectorAll('.dropdown-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        btn.parentElement.classList.toggle('open');
      });
    });
  }
</script>
```

**验证**:
- 桌面端悬停展开所有 4 个下拉
- 移动端点击 `☰` 展开菜单,点击下拉按钮展开子菜单
- 所有链接跳转到正确位置

---

### Task 3:更新 mechanism.html 导航 (10 min)

**文件**:`site/public/mechanism.html`

**目标**:与 index.html 使用完全相同的导航结构。

**关键点**:
- 第 24-30 行是当前的导航,需要替换
- "原理▾" 下拉菜单中,所有链接都是页面内锚点(`#architecture` 等)——因为用户已经在 mechanism.html
- 其他下拉菜单的链接需要完整路径(`index.html#roles`、`docs-index.html`、`pages/*.html`)

**替换为**:
```html
<nav class="topnav">
  <div class="topnav-inner">
    <a class="topnav-brand" href="/">领航 <span class="topnav-brand-en">HERO</span></a>
    <button class="nav-toggle" aria-label="菜单">☰</button>
    <ul class="topnav-links">
      <li><a href="/">首页</a></li>

      <!-- 原理下拉(当前页,所以用锚点) -->
      <li class="dropdown">
        <button class="dropdown-btn">原理 ▾</button>
        <div class="dropdown-content">
          <a href="#architecture">整体架构</a>
          <a href="#collaboration">Agent 协作</a>
          <a href="#skill-dispatch">Skill 调度</a>
          <a href="#workflow">工作流执行</a>
          <hr>
          <a href="#hidden-features">隐藏特性</a>
        </div>
      </li>

      <!-- 角色下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">角色 ▾</button>
        <div class="dropdown-content">
          <a href="index.html#roles">角色介绍</a>
          <a href="index.html#teams">组队模式</a>
        </div>
      </li>

      <!-- 文档下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">文档 ▾</button>
        <div class="dropdown-content">
          <a href="docs-index.html">📚 文档中心</a>
          <hr>
          <a href="pages/hero-agent-layers.html">🏗️ Agent 分层架构</a>
          <a href="pages/workflow.html">⚙️ 工作流详解</a>
          <a href="pages/prd-to-java.html">🔄 PRD 转 Java</a>
          <a href="pages/codegraph.html">📊 CodeGraph</a>
          <a href="pages/refresh.html">🔄 刷新机制</a>
          <a href="pages/onboarding.html">🚀 新人入门</a>
        </div>
      </li>

      <!-- 安装下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">安装 ▾</button>
        <div class="dropdown-content">
          <a href="index.html#install">10 分钟安装</a>
          <a href="index.html#build-pilot">自建领航员</a>
          <hr>
          <a href="index.html#uninstall">卸载</a>
        </div>
      </li>
    </ul>
  </div>
</nav>
```

**新增同样的 JavaScript**(与 index.html 相同)。

**验证**:
- 悬停"原理▾"展开到页面内锚点
- 点击"角色▾"中的链接跳转到 index.html#roles

---

### Task 4:更新 docs-index.html 导航 (10 min)

**文件**:`site/public/docs-index.html`

**目标**:与前两个页面使用相同的导航结构,但路径需要加 `../`。

**关键点**:
- 所有链接都要加 `../` 前缀(因为 docs-index.html 在根目录,但链接到其他根目录文件)
- 实际上 docs-index.html 就在根目录,所以不需要 `../`——与 index.html 相同

**替换为**:与 index.html 完全相同的导航 HTML。

---

### Task 5:更新 6 个文档页面导航 (6×5 = 30 min)

**文件**:`site/public/pages/*.html`(6 个)

**文件列表**:
1. `hero-agent-layers.html`
2. `workflow.html`
3. `prd-to-java.html`
4. `codegraph.html`
5. `refresh.html`
6. `onboarding.html`

**目标**:所有 6 个页面使用统一的 5 项导航,但路径需要 `../` 前缀。

**替换为**:
```html
<nav class="topnav">
  <div class="topnav-inner">
    <a class="topnav-brand" href="../">领航 <span class="topnav-brand-en">HERO</span></a>
    <button class="nav-toggle" aria-label="菜单">☰</button>
    <ul class="topnav-links">
      <li><a href="../">首页</a></li>

      <!-- 原理下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">原理 ▾</button>
        <div class="dropdown-content">
          <a href="../mechanism.html#architecture">整体架构</a>
          <a href="../mechanism.html#collaboration">Agent 协作</a>
          <a href="../mechanism.html#skill-dispatch">Skill 调度</a>
          <a href="../mechanism.html#workflow">工作流执行</a>
          <hr>
          <a href="../mechanism.html#hidden-features">隐藏特性</a>
        </div>
      </li>

      <!-- 角色下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">角色 ▾</button>
        <div class="dropdown-content">
          <a href="../index.html#roles">角色介绍</a>
          <a href="../index.html#teams">组队模式</a>
        </div>
      </li>

      <!-- 文档下拉(当前页,所以链接用同级路径) -->
      <li class="dropdown">
        <button class="dropdown-btn">文档 ▾</button>
        <div class="dropdown-content">
          <a href="../docs-index.html">📚 文档中心</a>
          <hr>
          <a href="hero-agent-layers.html">🏗️ Agent 分层架构</a>
          <a href="workflow.html">⚙️ 工作流详解</a>
          <a href="prd-to-java.html">🔄 PRD 转 Java</a>
          <a href="codegraph.html">📊 CodeGraph</a>
          <a href="refresh.html">🔄 刷新机制</a>
          <a href="onboarding.html">🚀 新人入门</a>
        </div>
      </li>

      <!-- 安装下拉 -->
      <li class="dropdown">
        <button class="dropdown-btn">安装 ▾</button>
        <div class="dropdown-content">
          <a href="../index.html#install">10 分钟安装</a>
          <a href="../index.html#build-pilot">自建领航员</a>
          <hr>
          <a href="../index.html#uninstall">卸载</a>
        </div>
      </li>
    </ul>
  </div>
</nav>
```

**新增**:
- 每个页面的"文档▾"下拉菜单中,当前页面的链接加 `class="active"`
- 新增同样的 JavaScript(放在 `</body>` 前)
- 如果页面用的是 `docs-nav` 类名,需要统一改为 `topnav`

**验收标准**:
- [x] 6 个页面的导航结构完全一致
- [x] 所有链接的路径正确(根目录用 `../`,pages/ 内用同级)
- [x] 当前页面的链接在"文档▾"下拉中有 `active` 高亮

---

### Task 6:删除 docs-pages 中的冗余面包屑 (10 min)

**文件**:`site/public/pages/*.html`(6 个)

**问题**:当前 6 个文档页面顶部都有一个"首页 / 文档 / XXX"的面包屑,与新导航重复。

**删除**:
```html
<!-- 删除这部分 -->
<nav class="docs-breadcrumb" aria-label="面包屑">
  <ol class="docs-breadcrumb-list">
    <li><a href="../index.html">首页</a></li>
    <li><a href="../docs-index.html">文档</a></li>
    <li>Agent 分层架构</li>
  </ol>
</nav>
```

**验收标准**:
- [x] 6 个页面都不再有面包屑
- [x] 页面顶部直接从 Hero region 开始

---

## 执行顺序

1. **Task 1**(CSS 重写)→ 必须先完成,后续任务都依赖新样式
2. **Task 2**(index.html)→ 作为模板
3. **Task 3**(mechanism.html)→ 复制 index 的导航,调整路径
4. **Task 4**(docs-index.html)→ 复制 index 的导航
5. **Task 5**(6 个 doc pages)→ 复制导航模板,调整路径,加 active 高亮
6. **Task 6**(删除面包屑)→ 最后清理

**依赖关系**:
```
Task 1 (CSS)
    ↓
Task 2 (index.html 模板)
    ↓
    ├─→ Task 3 (mechanism.html)
    ├─→ Task 4 (docs-index.html)
    └─→ Task 5 (6 个 doc pages,可并行)
              ↓
         Task 6 (删除面包屑)
```

**预计总耗时**:25 + 15 + 10 + 10 + 30 + 10 = **100 分钟**

---

## 风险与应对

| 风险 | 概率 | 影响 | 应对 |
|------|------|------|------|
| 旧 `.docs-dropdown` 样式没删干净,冲突 | 中 | 中 | Task 1 完成后立即测试 hover 效果 |
| 移动端 JS 事件绑定失败 | 低 | 高 | Task 2 完成后立即在手机/模拟器测试 |
| 6 个 doc pages 路径错误 | 中 | 低 | Task 5 每个页面单独测试点击 |
| 面包屑删除后页面布局错乱 | 低 | 中 | Task 6 前先检查 `.docs-breadcrumb` 是否有关联样式 |

---

## 验收检查清单

**功能验收**:
- [x] 桌面端:鼠标悬停任一页面的 4 个下拉菜单,250ms 后平滑展开
- [x] 移动端:点击 `☰` 展开主菜单,点击下拉按钮展开子菜单
- [x] 所有下拉菜单的链接点击后正确跳转
- [x] 当前页面的链接在"文档▾"下拉中有 `active` 高亮(铜色左边框)
- [x] 面包屑已从 6 个 doc pages 中删除

**一致性验收**:
- [x] 7 个页面的导航 HTML 结构完全相同(除路径前缀)
- [x] 下拉菜单的样式、间距、动画完全一致
- [x] 所有页面都加载 `docs.css` 和 `tokens.css`

**跨页面体验**:
- [x] 从 index.html 点击"原理▾"→"整体架构",正确跳转到 mechanism.html
- [x] 从 mechanism.html 点击"角色▾"→"角色介绍",正确跳转到 index.html#roles
- [x] 从任一 doc page 点击"文档▾"→"文档中心",正确跳转到 docs-index.html
- [x] 从 docs-index.html 点击"文档▾"→"Agent 分层架构",正确跳转到 pages/hero-agent-layers.html

---

## 总结

**改动文件**:
- `site/public/css/docs.css`(重写 ~100 行下拉系统代码)
- `site/public/index.html`(替换导航)
- `site/public/mechanism.html`(替换导航)
- `site/public/docs-index.html`(替换导航)
- `site/public/pages/hero-agent-layers.html`(替换导航 + 删除面包屑)
- `site/public/pages/workflow.html`(替换导航 + 删除面包屑)
- `site/public/pages/prd-to-java.html`(替换导航 + 删除面包屑)
- `site/public/pages/codegraph.html`(替换导航 + 删除面包屑)
- `site/public/pages/refresh.html`(替换导航 + 删除面包屑)
- `site/public/pages/onboarding.html`(替换导航 + 删除面包屑)

**总计**:1 个 CSS 文件 + 9 个 HTML 文件

**预期效果**:
```
之前:  [领航 HERO]  理念  原理  能力  角色  组队  文档▾  机制  安装  自建
之后:  [领航 HERO]  首页  原理▾  角色▾  文档▾  安装▾
```

极简、统一、逻辑清晰。
