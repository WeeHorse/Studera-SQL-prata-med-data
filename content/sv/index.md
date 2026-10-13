<script setup>
import { withBase } from 'vitepress'
</script>

<section class="sql-cover" aria-label="Omslag: Studera SQL – Prata med data">
  <p class="sql-cover__eyebrow">STUDERA SQL · 2026</p>
  <div class="sql-cover__heading">
    <h1>STUDERA SQL</h1>
    <p class="sql-cover__subtitle">Prata med data</p>
  </div>
  <p class="sql-cover__author">Benjamin Berglund</p>
  <div class="sql-cover__example">
    <p class="sql-cover__example-label">EXEMPEL 01: EN QUERY</p>
    <pre>SELECT title, price
FROM products
WHERE stock &gt; 0
ORDER BY title;</pre>
  </div>
  <div class="sql-cover__footer">
    <p>En introduktion till databaser och SQL</p>
    <p>2026 års utgåva</p>
  </div>
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
