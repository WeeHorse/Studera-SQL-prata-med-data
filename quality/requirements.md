# Krav och acceptanskriterier · version 0.1

| ID | Krav | Acceptanskriterium | Testmetod |
|---|---|---|---|
| STR-01 | Varje kapitel har Grund, Avancerat och Reflektion | Alla tre rubriker finns i rätt ordning | Automatiskt |
| STR-02 | Varje kapitel avslutas med tre reflektionsfrågor | Tre öppna frågor per kapitel | Automatisk kontroll + manuell |
| PED-01 | Begrepp introduceras före förutsatt användning | Dokumenterad kapitelvis progression | Redaktionellt |
| MOD-01 | Bokhandelns data är konsekventa | Tabeller och attribut existerar vid respektive exempel | SQL-integrationstest |
| SQL-01 | Körbara exempel fungerar i referensdialekt | Förväntad SQL-utmatning verifieras | SQL-test |
| TER-01 | Tekniska termer används konsekvent | Gemensam ordlista; skyddad kod påverkas inte av översättning | Terminologitest |
| L10N-01 | Varje språk har eget källträd | content/<språk>/chapters/ | Filtest |
| L10N-02 | Maskinöversättning får inte ändra kod | SQL-fences, inline-kod, länkmål och identifierare förblir lika | Strukturjämförelse |
| WEB-01 | Webbversionen kan byggas | VitePress exit code 0 | CI |
| PDF-01 | A5-PDF kan byggas | PDF skapas med A5 sidformat | CI och filinspektion |
| PRT-01 | Trycklayout fungerar | Kodblock, tabeller, sidbrytningar fungerar | Manuell PDF-granskning |
| HEL-01 | Helheten uppfyller synopsis | Granskningsrapport anger belägg och avvikelser | Acceptansgranskning |

**Status:** Pilot täcker endast kapitel 1. Inget av de ännu ej implementerade testerna ska beskrivas som godkänt.
