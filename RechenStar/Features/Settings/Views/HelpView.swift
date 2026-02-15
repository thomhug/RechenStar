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
                        text: "Tippe auf \"Spielen\", um eine Runde zu starten. Du bekommst Rechenaufgaben mit Plus und Minus. Tippe die Antwort auf dem Zahlenfeld ein und drücke den grünen Haken."
                    )

                    helpSection(
                        icon: "star.fill",
                        color: .appSunYellow,
                        title: "Sterne sammeln",
                        text: "Für jede richtige Antwort bekommst du Sterne. Beim ersten Versuch gibt es 3 Sterne, beim zweiten 2 und beim dritten noch 1 Stern."
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
                        icon: "chart.line.uptrend.xyaxis",
                        color: .appGrassGreen,
                        title: "Fortschritt",
                        text: "Im Fortschritt-Tab siehst du, wie viele Aufgaben du schon gelöst hast und wie lang deine aktuelle Serie ist."
                    )

                    helpSection(
                        icon: "gearshape.fill",
                        color: .appTextSecondary,
                        title: "Einstellungen",
                        text: "Passe die Schriftgrösse, Töne und die Anzahl der Aufgaben pro Runde an. Du findest die Einstellungen im letzten Tab."
                    )

                    helpSection(
                        icon: "person.2.fill",
                        color: .appPurple,
                        title: "Elternbereich",
                        text: "Eltern können oben rechts auf das Personen-Symbol tippen. Nach einer Rechenaufgabe für Erwachsene seht ihr detaillierte Statistiken."
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
