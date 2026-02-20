import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    helpSection(
                        icon: "play.circle.fill",
                        color: .appSkyBlue,
                        title: "Spielen",
                        text: "Tippe auf \"Spielen\", um eine Runde zu starten. Du bekommst Rechenaufgaben mit Plus, Minus und Mal. Tippe die Antwort auf dem Zahlenfeld ein und drücke den grünen Haken."
                    )

                    helpSection(
                        icon: "square.grid.2x2.fill",
                        color: .appSkyBlue,
                        title: "Aufgabentypen",
                        text: "In den Einstellungen kannst du auswählen, welche Aufgaben vorkommen: Addition und Subtraktion bis 10 oder bis 100, sowie kleines und grosses Einmaleins. Bei Subtraktion bis 100 gibt es einen ±-Knopf für negative Ergebnisse. Wenn Lückenaufgaben aktiviert sind, kommen auch Aufgaben wie ? + 4 = 7 oder 3 + ? = 7 vor."
                    )

                    helpSection(
                        icon: "star.fill",
                        color: .appSunYellow,
                        title: "Sterne sammeln",
                        text: "Für jede richtige Antwort bekommst du Sterne. Beim ersten Versuch gibt es 3 Sterne, beim zweiten 2 und beim dritten noch 1 Stern. Nach zwei falschen Antworten wird die Lösung gezeigt. Wenn du eine Aufgabe überspringst, siehst du ebenfalls die richtige Antwort."
                    )

                    helpSection(
                        icon: "trophy.fill",
                        color: .appOrange,
                        title: "Erfolge",
                        text: "Schalte Erfolge frei, indem du viele Aufgaben löst, Serien aufbaust oder besonders schnell rechnest. Schau im Erfolge-Tab nach deinem Fortschritt."
                    )

                    helpSection(
                        icon: "flame.fill",
                        color: .appCoral,
                        title: "Serien",
                        text: "Spiele jeden Tag eine Runde, um deine Serie zu verlängern. Je länger deine Serie, desto besser!"
                    )

                    helpSection(
                        icon: "brain.head.profile",
                        color: .appGrassGreen,
                        title: "Schlaues Üben",
                        text: "Die App merkt sich, welche Aufgaben dir schwerfallen, und zeigt sie dir öfter. Wenn du eine schwierige Aufgabe dann richtig löst, bekommst du Bonus-Sterne als Belohnung! Ausserdem erkennt die App, wenn du Plus und Minus verwechselst, und gibt dir einen Hinweis."
                    )

                    helpSection(
                        icon: "target",
                        color: .appSkyBlue,
                        title: "Tagesziel",
                        text: "Auf dem Startbildschirm siehst du dein Tagesziel. Versuche jeden Tag genug Aufgaben zu lösen, um den Balken zu füllen!"
                    )

                    helpSection(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .appGrassGreen,
                        title: "Fortschritt",
                        text: "Im Fortschritt-Tab siehst du dein Level und deinen Skill. Tippe auf die Badges, um alle Stufen zu sehen. Dein Level steigt mit der Anzahl gelöster Aufgaben, dein Skill zeigt deine Genauigkeit der letzten 7 Tage."
                    )

                    difficultySection

                    helpSection(
                        icon: "gearshape.fill",
                        color: .appTextSecondary,
                        title: "Einstellungen",
                        text: "Passe die Aufgabentypen, Schriftgrösse, Töne und die Anzahl der Aufgaben pro Runde an. Eltern können auch den Überspringen-Knopf ausblenden oder einen Timer einstellen, der die Lösung nach einer gewissen Zeit automatisch zeigt."
                    )

                    helpSection(
                        icon: "person.2.fill",
                        color: .appPurple,
                        title: "Elternbereich",
                        text: "Eltern können oben rechts auf das Personen-Symbol tippen. Nach einer Rechenaufgabe für Erwachsene seht ihr detaillierte Statistiken und Stärken pro Aufgabentyp."
                    )
                }
                .padding(20)
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("So funktioniert's")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 28))
                    .foregroundColor(.appSunYellow)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Schwierigkeitsstufen")
                        .font(AppFonts.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("Wähle \"Automatisch\" und die App passt sich an. Oder stelle die Schwierigkeit selbst ein:")
                        .font(AppFonts.body)
                        .foregroundColor(.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            difficultyTable(
                title: "Bis 10 (+ −)",
                subtitle: "Addition & Subtraktion",
                rows: [
                    ("Sehr leicht", "Zahlen 1–3"),
                    ("Leicht", "Zahlen 1–5"),
                    ("Mittel", "Zahlen 2–7"),
                    ("Schwer", "Zahlen 2–9"),
                ]
            )

            difficultyTable(
                title: "Kleines 1×1",
                subtitle: "Multiplikation bis 10",
                rows: [
                    ("Sehr leicht", "Faktoren 2–3"),
                    ("Leicht", "Faktoren 2–5"),
                    ("Mittel", "Faktoren 2–7"),
                    ("Schwer", "Faktoren 2–9"),
                ]
            )

            difficultyTable(
                title: "Bis 100 (+ −)",
                subtitle: "Addition & Subtraktion",
                rows: [
                    ("Sehr leicht", "Zahlen 1–20"),
                    ("Leicht", "Zahlen 1–40"),
                    ("Mittel", "Zahlen 2–70"),
                    ("Schwer", "Zahlen 2–99"),
                ]
            )

            difficultyTable(
                title: "Grosses 1×1",
                subtitle: "Faktoren bis 20",
                rows: [
                    ("Sehr leicht", "Ergebnis bis 50, ab 2×2"),
                    ("Leicht", "Ergebnis bis 100, ab 2×2"),
                    ("Mittel", "Ergebnis bis 200, ab 2×2"),
                    ("Schwer", "Ergebnis bis 400, ab 2×2"),
                ]
            )

            adaptiveExplanation
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
        )
        .accessibilityElement(children: .combine)
    }

    private var adaptiveExplanation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Automatische Anpassung")
                .font(AppFonts.caption)
                .fontWeight(.semibold)
                .foregroundColor(.appTextPrimary)
            Text("Im Automatik-Modus passt die App die Schwierigkeit alle 2 Aufgaben an:")
                .font(AppFonts.footnote)
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                adaptiveRow("Stufe hoch", "2/2 richtig und schnell gelöst (unter 3 Sekunden)")
                adaptiveRow("Bleibt gleich", "Teilweise richtig, oder richtig aber langsam")
                adaptiveRow("Stufe runter", "Beide falsch, oder zu langsam (über 7 Sekunden)")
            }
            .padding(.top, 4)

            Text("Wenn in den letzten 4 Aufgaben weniger als 2 richtig waren, wird die Stufe ebenfalls gesenkt und eine Ermutigungs-Nachricht angezeigt.")
                .font(AppFonts.footnote)
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appSunYellow.opacity(0.06))
        )
    }

    private func adaptiveRow(_ label: String, _ description: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(.appTextSecondary)
                .frame(width: 90, alignment: .leading)
            Text(description)
                .font(AppFonts.caption)
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func difficultyTable(title: String, subtitle: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFonts.caption)
                .fontWeight(.semibold)
                .foregroundColor(.appTextPrimary)
            Text(subtitle)
                .font(AppFonts.footnote)
                .foregroundColor(.appTextSecondary)

            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0)
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 80, alignment: .leading)
                    Text(row.1)
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appSunYellow.opacity(0.06))
        )
    }

    private func helpSection(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(.appTextPrimary)
                Text(text)
                    .font(AppFonts.body)
                    .foregroundColor(.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
        )
        .accessibilityElement(children: .combine)
    }
}
