# Författarbox

Den kompakta författarboxen visas på webbens svenska författarsida och infogas före kapitel 1 i A5-PDF.

**Återstående manuellt steg:** Lägg den autentiska, oförändrade originalbilden som `content/public/images/benjamin-berglund.jpg` i denna branch innan merge. Bilden är bifogad i ChatGPT, men GitHub-kopplingen här kan inte överföra den bifogade binärfilen direkt. Det är avsiktligt **inte** en AI-genererad version som ska publiceras.

I webben sker beskärning med `object-fit: cover` i `.vitepress/theme/custom.css`, och i PDF med `publishing/print/book.css`.

Verifiera vid granskning att bilden visas på både `/sv/om-forfattaren.html` och i den första delen av den genererade A5-PDF:en.
