# Redaktionell slutgranskning: kapitel 15–21

Genomgången omfattar förändringar av data och schema, Views, CTE:er, fönsterfunktioner, transaktioner och index. Fokus är terminologi, saklig precision och progression. Längre resonemang och reflektionsavsnitt behålls.

## Rättningar

- **Kapitel 15:** Hänvisningen till fördjupningen om transaktioner, samtidighet och isolering är nu exakt: kapitel 20.
- **Kapitel 19:** Beskrivningen av `ROWS` som *fysiska positioner* har förtydligats till **radpositioner i fönstrets ordning**, inte den fysiska lagringsordningen. Det förhindrar en missuppfattning om hur SQL-fönsterfunktioner fungerar.

## Bedömning och avgränsning

Kapitel 16–18 och 20–21 har lästs med särskilt fokus på skillnaden mellan schema och data, View kontra CTE, transaktionella garantier, samt indextäckning och optimerarens frihet. Inga ytterligare säkert motiverade ändringar har gjorts i denna omgång.

Inga SQL-kodblock har ändrats. Befintliga funktionella MySQL-regressionstester ger stöd, men är inte fullständig ordagrann kontroll av samtliga bokblock. Granska projektets PR-checks (test, webb och PDF) före merge.

Nästa redaktionella omgång: kapitel 22–29.
