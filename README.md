<div align="center">

<img src="docs/AppIcon.svg" width="96" alt="App-Icon" />

# Arbeitszeiterfassung

**Gleitzeit-Tracker im Liquid-Glass-Design für iOS 26**

Einstempeln mit einem Tap · Feierabendzeit automatisch errechnet · lokale Erinnerung · Gleitzeitkonto

![iOS](https://img.shields.io/badge/iOS-26%2B-1d1d1f?style=flat&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5-F05138?style=flat&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF?style=flat)
![SwiftData](https://img.shields.io/badge/Persistenz-SwiftData-30B0C7?style=flat)
![Plattform](https://img.shields.io/badge/Ger%C3%A4t-iPhone-8e8e93?style=flat)

</div>

---

Morgens **„Jetzt einstempeln"** antippen — die App errechnet deine Feierabendzeit aus
Sollarbeitszeit und Pause, erinnert dich pünktlich per Benachrichtigung und führt
nach dem Ausstempeln dein Gleitzeitkonto. Alles lokal auf dem iPhone, ohne Server,
ohne Konto, ohne Datenweitergabe.

<!-- Screenshots: Bilder nach docs/screenshots/ legen und die Zeile einkommentieren.
<p align="center">
  <img src="docs/screenshots/heute.png" width="240" alt="Heute-Tab" />
  <img src="docs/screenshots/auswertung.png" width="240" alt="Auswertung" />
  <img src="docs/screenshots/einstellungen.png" width="240" alt="Einstellungen" />
</p>
-->

## Features

**Heute — die Stempeluhr**
- Ein Tap zum Ein- und Ausstempeln, exakt zur Uhrzeit des Antippens
- Errechnete Feierabendzeit groß im Blick, mit Fortschrittsring
- Ein- und Ausstempeln auch rückwirkend mit frei gewählter Zeit (wenn die App gerade nicht zur Hand war) — die Auswahl bleibt bis zum Stempeln erhalten
- Start, Ende und Pause jederzeit direkt auf der Karte korrigierbar, „Weiter arbeiten" nach versehentlichem Ausstempeln

**Feierabend-Benachrichtigung**
- Lokale Push zur errechneten Feierabendzeit, optional mit Vorwarnung (5–30 Min vorher)
- Wird beim Einstempeln geplant und bei jeder Zeitänderung automatisch umgeplant — komplett offline, kein Server nötig

**Verlauf**
- Alle Tage mit Start, Ende, Pause und Tagessaldo
- Bearbeiten, Löschen und Nachtragen vergessener Tage

**Auswertung**
- Ø Startzeit, Ø Feierabend, Ø Arbeitszeit und Kontostand als Kennzahlen
- Tagessaldo-Diagramm um die Nulllinie und Start-/Feierabendzeiten im Zeitverlauf (Swift Charts)
- Zeitraumfilter: 7 Tage · 30 Tage · Gesamt

**Einstellungen**
- Sollarbeitszeit und Pausendauer frei einstellbar
- Startsaldo fürs Gleitzeitkonto, minutengenau (falls dein echtes Konto nicht bei ±0 beginnt)

## So rechnet die App

```
Feierabend     = Startzeit + Sollarbeitszeit + Pause
Tagessaldo     = (Ende − Start − Pause) − Sollarbeitszeit
Gleitzeitkonto = Startsaldo + Summe aller Tagessalden
```

Sollzeit und Pause werden **beim Einstempeln in den Tag kopiert** — änderst du später
die Einstellungen, bleiben historische Tage und dein Saldo unverfälscht. Pro Tag
lassen sich beide Werte trotzdem individuell anpassen.

## Installation

**Voraussetzungen:** macOS mit Xcode 26 · iPhone mit iOS 26 · Apple-Konto in Xcode
(ein kostenloses Konto reicht für das eigene Gerät)

1. Repository klonen und `Arbeitszeiterfassung.xcodeproj` in Xcode öffnen
2. Projekt → Target **Arbeitszeiterfassung** → **Signing & Capabilities** → bei
   **Team** dein Apple-Konto wählen (lehnt Xcode die Bundle-ID ab, einfach eine
   eigene eintragen, z. B. `de.deinname.Arbeitszeiterfassung`)
3. iPhone anschließen, oben als Ziel auswählen, **⌘R**
4. Beim ersten Start ggf. unter *Einstellungen → Allgemein → VPN & Geräteverwaltung*
   dem Entwicklerzertifikat vertrauen
5. Beim ersten Einstempeln die Mitteilungs-Berechtigung **erlauben** — sonst kommt
   keine Feierabend-Push

> **Hinweis (kostenloses Apple-Konto):** Die Signatur läuft nach 7 Tagen ab — dann
> die App einfach erneut über Xcode installieren. Mit bezahltem Developer-Account
> entfällt das.

## Tech-Stack

| Technologie | Einsatz |
|---|---|
| **SwiftUI** | Gesamte Oberfläche, iOS-26-Minimum-Target |
| **Liquid Glass** | Natives `glassEffect` auf Karten und Primäraktionen |
| **SwiftData** | Persistenz der Arbeitstage, lokal auf dem Gerät |
| **Swift Charts** | Saldo- und Zeiten-Diagramme in der Auswertung |
| **UserNotifications** | Lokale Feierabend-Push inkl. Vorwarnung |

## Projektstruktur

```
Arbeitszeiterfassung/
├── ArbeitszeiterfassungApp.swift   App-Entry, SwiftData-Container, Notification-Delegate
├── Models/
│   ├── WorkDay.swift               Arbeitstag (@Model, SwiftData)
│   └── AppSettings.swift           Einstellungen (UserDefaults, @Observable)
├── Logic/
│   ├── WorkDayCalculator.swift     Reine Rechen- und Formatierlogik
│   └── NotificationManager.swift   Lokale Feierabend-Benachrichtigung
└── Views/
    ├── RootTabView.swift           Tabs: Heute · Verlauf · Auswertung · Einstellungen
    ├── Today/                      Stempeluhr mit drei Tageszuständen
    ├── History/                    Liste, Editor, Nachtragen
    ├── Stats/                      Kennzahlen + Swift-Charts-Diagramme
    └── Settings/                   Einstellungs-Formular
```

## Design-Entscheidungen

**Lokale Push statt Telegram.** Eine Telegram-Nachricht bräuchte einen Server, der
zur richtigen Zeit sendet. Die lokale Benachrichtigung wird direkt beim Einstempeln
auf dem Gerät geplant — zuverlässiger, offlinefähig, null Infrastruktur.

**Eingefrorene Tageswerte.** Sollzeit und Pause wandern beim Einstempeln in den
Datensatz des Tages. Einstellungsänderungen wirken nur nach vorn — die Historie
und das Gleitzeitkonto bleiben korrekt.

**Dezentes Liquid Glass.** Native Container (TabView, Form, NavigationStack)
bringen den Look von selbst mit; `glassEffect` gibt es nur gezielt auf Karten und
Primär-Buttons. Ruhige Farbwelt, ein Akzentton, keine überladenen Effekte.

---

<div align="center">
<sub>Privates Projekt · alle Daten bleiben lokal auf dem iPhone · keine Analytics, keine Server</sub>
</div>
