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

## Build-Nummern
- **Lokal**: `{TF+1}.{counter}` (z.B. `31.1`, `31.2`) — in der App als "Local" markiert
- **Xcode Cloud**: Nutzt eigenen Auto-Increment-Counter (NICHT git commit count, es sei denn ci_post_clone.sh ueberschreibt das)
- `.testflight-build-number` — letzte bekannte TF/Xcode-Cloud Build-Nummer (git-tracked, manuell aktualisieren nach TF-Upload)
- `.local-build-count` — lokaler Zaehler (git-ignored)
- **Wichtig**: Vor dem Setzen von `.testflight-build-number` immer pruefen: `fastlane run latest_testflight_build_number`

## Fastlane
- `fastlane beta` — baut und laedt zu TestFlight hoch
- **Aktuelle App Store Build-Nummer abfragen**: `fastlane run app_store_build_number live:true` (zeigt Version + Build)
- **Aktuellen TestFlight Build abfragen**: `fastlane run latest_testflight_build_number`
- **Commit eines Xcode Cloud Builds finden**: Ueber die ASC API via Spaceship — CI Product ID ist `A1C21319-EF16-405D-AE6D-D4BA80A706F7`. Build Runs abfragen mit:
  ```ruby
  client = Spaceship::ConnectAPI.client.tunes_request_client
  runs = client.get("v1/ciProducts/A1C21319-EF16-405D-AE6D-D4BA80A706F7/buildRuns", {"limit" => 50})
  # Jeder Run hat attrs["sourceCommit"]["commitSha"]
  ```
  Hinweis: `Spaceship::ConnectAPI.get_builds()` ist wegen fastlane Bug #21104 (`betaBuildMetrics`) kaputt — daher den `tunes_request_client` direkt nutzen.
