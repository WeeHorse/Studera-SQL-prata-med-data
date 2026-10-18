---
layout: false
---

<script setup>
import { withBase } from 'vitepress'
import './index-cover.css'
</script>

<a class="book-cover-entry" :href="withBase('/sv/forfattare.html')" aria-label="Öppna boken – gå till författarsidan">
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
