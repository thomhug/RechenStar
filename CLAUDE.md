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

### Abfragen
- **Aktuelle App Store Build-Nummer**: `fastlane run app_store_build_number live:true`
- **Aktuellen TestFlight Build**: `fastlane run latest_testflight_build_number`
- **Commit eines Xcode Cloud Builds finden**: Ueber die ASC API via Spaceship — CI Product ID ist `A1C21319-EF16-405D-AE6D-D4BA80A706F7`. Build Runs abfragen mit:
  ```ruby
  client = Spaceship::ConnectAPI.client.tunes_request_client
  runs = client.get("v1/ciProducts/A1C21319-EF16-405D-AE6D-D4BA80A706F7/buildRuns", {"limit" => 50})
  # Jeder Run hat attrs["sourceCommit"]["commitSha"]
  ```
  Hinweis: `Spaceship::ConnectAPI.get_builds()` ist wegen fastlane Bug #21104 (`betaBuildMetrics`) kaputt — daher den `tunes_request_client` direkt nutzen.

### Release-Vorgang (App Store)
1. **Build in Xcode Cloud starten** (oder `fastlane beta` fuer lokalen Upload)
2. **Warten bis Build in TestFlight "Ready to Submit" ist**
3. **Version in App Store Connect erstellen + Metadata/Release Notes hochladen**:
   ```
   fastlane deliver --app_version "X.Y.Z" --skip_screenshots --skip_binary_upload --force
   ```
   Release Notes vorher in `fastlane/metadata/de-DE/release_notes.txt` schreiben.
4. **Build anhaengen und zur Review einreichen**:
   ```
   fastlane deliver --app_version "X.Y.Z" --build_number "N" --skip_screenshots --skip_binary_upload --skip_metadata --submit_for_review --automatic_release --force
   ```
5. **Nach dem Einreichen — Version bumpen**:
   - MARKETING_VERSION in `project.yml` und `RechenStar.xcodeproj/project.pbxproj` erhoehen
   - `.testflight-build-number` auf die eingereichte Build-Nummer setzen
   - `.local-build-count` loeschen (reset)
   - Committen und pushen
