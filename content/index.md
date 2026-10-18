<script setup>
import { withBase } from 'vitepress'
</script>

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

<div class="author-card">
  <div class="author-card__portrait">
    <img :src="withBase('/images/benjamin-berglund.jpg')" alt="Porträtt av Benjamin Berglund" />
  </div>
  <div class="author-card__copy">
    <h2>Om författaren</h2>
    <p><strong>Benjamin Berglund</strong>, systemutvecklare, utbildare och utbildningsutvecklare med lång erfarenhet av att konstruera digitala system, leda utvecklingsarbete och att undervisa inom utveckling, data och samarbete. Med ett särskilt intresse för sambanden mellan information, teknik, människor och verksamheter.</p>
  </div>
</div>


[Börja läsa – Kapitel 1](/sv/chapters/01-vad-ar-en-databas.html)

[Ladda ner boken som A5-PDF](/downloads/studera-sql-sv-a5.pdf)

[Bilaga: ladda ner bokhandelns exempeldatabas](/sv/bilaga-exempeldatabas.html)
