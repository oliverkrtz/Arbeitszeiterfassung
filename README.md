# Arbeitszeiterfassung

Eine dezente iOS-App für dein Gleitzeitsystem im nativen **Liquid-Glass-Design** (iOS 26):
Morgens die Startzeit eintragen → die App errechnet deine Feierabendzeit, erinnert dich
per Benachrichtigung und führt dein Gleitzeitkonto.

## Funktionen

- **Heute:** Startzeit eintragen (oder „Jetzt starten“), errechnete Feierabendzeit
  groß im Blick, Fortschrittsring, ein Tap für den Feierabend-Stempel.
- **Feierabend-Benachrichtigung:** Lokale Push zur errechneten Feierabendzeit,
  optional mit Vorwarnung (z. B. 10 Min vorher). Komplett offline, kein Server nötig.
- **Gleitzeitkonto:** Tagessaldo (Ist − Soll) und laufender Gesamtsaldo,
  inkl. konfigurierbarem Startsaldo.
- **Verlauf:** Alle Tage einsehen, bearbeiten, löschen, vergessene Tage nachtragen.
- **Auswertung:** Ø Startzeit, Ø Feierabend, Ø Arbeitszeit, Kontostand sowie
  Diagramme (Tagessaldo, Start-/Feierabendzeiten) mit Zeitraumfilter.
- **Einstellungen:** Sollarbeitszeit, Pausendauer, Benachrichtigung, Startsaldo.

Berechnung: **Feierabend = Start + Sollarbeitszeit + Pause.**
Sollzeit und Pause werden pro Tag gespeichert — spätere Änderungen an den
Einstellungen verfälschen die Historie nicht.

## Voraussetzungen

- macOS mit **Xcode 26**
- iPhone mit **iOS 26** (Minimum-Target)
- Ein Apple-Konto in Xcode (kostenloses Konto reicht für die Installation aufs eigene Gerät)

## Installation aufs iPhone

1. Repository klonen und `Arbeitszeiterfassung.xcodeproj` in Xcode öffnen.
2. Im Projekt-Navigator das Projekt anklicken → Target **Arbeitszeiterfassung**
   → Tab **Signing & Capabilities** → bei **Team** dein Apple-Konto auswählen.
   Falls Xcode die Bundle-ID ablehnt, einfach eine eigene eintragen
   (z. B. `de.deinname.Arbeitszeiterfassung`).
3. iPhone per Kabel anschließen (oder WLAN-Debugging aktivieren) und oben in der
   Geräteliste auswählen.
4. **⌘R** — Xcode baut die App und installiert sie auf dem iPhone.
5. Beim ersten Start auf dem iPhone ggf. unter *Einstellungen → Allgemein →
   VPN & Geräteverwaltung* dem Entwicklerzertifikat vertrauen.
6. Beim ersten „Arbeitstag starten“ fragt die App die Berechtigung für
   Mitteilungen an — **Erlauben** antippen, sonst kommt keine Feierabend-Push.

> Hinweis (kostenloses Apple-Konto): Die Signatur läuft nach 7 Tagen ab, dann
> die App einfach erneut über Xcode installieren. Mit einem bezahlten
> Developer-Account entfällt das.

## Projektstruktur

```
Arbeitszeiterfassung/
├── ArbeitszeiterfassungApp.swift   App-Entry, SwiftData-Container, Notification-Delegate
├── Models/
│   ├── WorkDay.swift               Arbeitstag (@Model, SwiftData)
│   └── AppSettings.swift           Einstellungen (UserDefaults, @Observable)
├── Logic/
│   ├── WorkDayCalculator.swift     Reine Rechen-/Formatierlogik
│   └── NotificationManager.swift   Lokale Feierabend-Benachrichtigung
└── Views/
    ├── RootTabView.swift           Tabs: Heute · Verlauf · Auswertung · Einstellungen
    ├── Today/                      Kernscreen mit drei Zuständen
    ├── History/                    Liste, Editor, Nachtragen
    ├── Stats/                      Kennzahlen + Swift-Charts-Diagramme
    └── Settings/                   Einstellungs-Formular
```

## Design-Entscheidungen

- **Lokale Benachrichtigung statt Telegram:** Eine Telegram-Push bräuchte einen
  Server, der zur richtigen Zeit sendet. Die lokale iOS-Benachrichtigung wird
  direkt beim Eintragen der Startzeit geplant — zuverlässiger, offlinefähig,
  keine Infrastruktur.
- **Liquid Glass dezent:** Native Container (TabView, Form, NavigationStack)
  bringen den Look von selbst mit; `glassEffect` nur gezielt auf Karten und
  Primäraktionen.
- **SwiftData + UserDefaults:** Alle Daten bleiben lokal auf dem Gerät.
