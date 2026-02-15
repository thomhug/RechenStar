# RechenStar - Projektkonventionen

## Sprache & Schreibweise
- Kein deutsches Doppel-s (ß) verwenden — immer "ss" schreiben (z.B. "heisst" statt "heißt", "gross" statt "groß")
- Standard-Benutzername: **Noah** (nicht Max)

## Entwicklungsumgebung
- Xcode **15.4** (Build 15F31d) — Projektformat muss objectVersion 56 sein, NICHT 77

## Workflow
- Nach jeder Aenderung: **committen, pushen, dann auf iPad und iPhone deployen**
- Build & Deploy: `./scripts/build-and-deploy.sh` (aktualisiert Build-Nummer, baut, installiert auf beiden Geraeten)
- Deploy-Targets:
  - iPad von Fritz: `00008020-001079801440402E`
  - iPhone von Tom: `00008130-0004446200698D3A`
