---
layout: false
---

<script setup>
import { withBase } from 'vitepress'
import { onMounted, onUnmounted } from 'vue'

let removeCoverScrollListeners
onMounted(() => {
  const destination = withBase('/sv/innehall.html')
  let touchStartY = null
  let navigating = false
  const openContents = () => {
    if (navigating) return
    navigating = true
    window.location.assign(destination)
  }
  const onWheel = (event) => {
    if (event.deltaY > 15) openContents()
  }
  const onTouchStart = (event) => {
    touchStartY = event.touches[0]?.clientY ?? null
  }
  const onTouchEnd = (event) => {
    if (touchStartY === null) return
    const endY = event.changedTouches[0]?.clientY ?? touchStartY
    if (touchStartY - endY > 45) openContents()
    touchStartY = null
  }
  window.addEventListener('wheel', onWheel, { passive: true })
  window.addEventListener('touchstart', onTouchStart, { passive: true })
  window.addEventListener('touchend', onTouchEnd, { passive: true })
  removeCoverScrollListeners = () => {
    window.removeEventListener('wheel', onWheel)
    window.removeEventListener('touchstart', onTouchStart)
    window.removeEventListener('touchend', onTouchEnd)
  }
})
onUnmounted(() => removeCoverScrollListeners?.())
import '../index-cover.css'
</script>

<a class="book-cover-entry" :href="withBase('/sv/innehall.html')" aria-label="Öppna boken – gå till innehållsförteckningen">
<section class="sql-cover" aria-label="Omslag: Studera SQL – Prata med data">
  <p class="sql-cover__eyebrow">RESEARCH REPORT NH2026-3</p>
  <div class="sql-cover__heading">
    <h1>STUDERA SQL: PRATA MED DATA</h1>
    <p class="sql-cover__subtitle">Datafilosofi och praktisk implementation</p>
  </div>
  <div class="sql-cover__author">
    <p>av Benjamin Berglund</p>
    <p>Node Hill Research Laboratory</p>
    <p>Lund, Sweden</p>
  </div>
  <div class="sql-cover__example">
    <p class="sql-cover__example-label">Example 1: Complex Query</p>
    <pre>+----------------------------------+
| SELECT NAME, SALARY              |
| FROM EMPLOYEES                   |
| WHERE                            |
| DEPARTMENT_NO = 'D01'            |
| AND                              |
| SALARY &gt; (SELECT AVG(SALARY)     |
|           FROM EMPLOYEES)        |
+----------------------------------+</pre>
  </div>
  <footer class="sql-cover__footer">
    <div class="sql-cover__brand">NODEHILL</div>
    <div class="sql-cover__brand-sub">Research</div>
    <div class="sql-cover__edition">OCT 2026 (Current Edition)</div>
  </footer>
</section>
</a>
