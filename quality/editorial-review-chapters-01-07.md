# Redaktionell slutgranskning: kapitel 1–7

Granskningens syfte är att stärka språklig precision, pedagogisk progression och överensstämmelse mellan exempel och bokhandelns gemensamma datamodell, utan att korta eller förenkla de reflekterande partierna.

## Rättningar i denna PR

- **Kapitel 3:** Rättad hänvisning: kapitel 4 handlar om datatyper och värden, medan fördjupningen om SQL-villkor följer i kapitel 5. Övergången anger nu båda stegen i progressionen.
- **Kapitel 5:** Inledningen skiljer på kunders namn och **adressernas orter**. Det senare finns i `addresses.city`, inte direkt i tabellen `customers`.
- **Kapitel 6:** Resultattabellen till det första `CASE`-exemplet kompletterad med femte produkten `Mellan raderna`, som annars saknades trots att `SELECT` saknar filtrering.

## Oförändrat med avsikt

- De reflekterande avsnitten, längre förklaringarna och samtliga reflektionsfrågor bevaras.
- Kapitel 1–2, 4 och 7 har lästs för språklig och pedagogisk kontinuitet men får inga spekulativa ändringar.
- SQL-kodblocken har inte ändrats. Test- och publiceringskedjan bör ändå köras i PR-kontrollen.

## Fortsatt arbete

Nästa redaktionella omgång bör omfatta kapitel 8–14, särskilt tabellerna med förväntade resultat, hänvisningar till tidigare kapitel och relationen mellan grunddata och tillfälliga utökningar.
