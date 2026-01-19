# Nightscout Desktop Widget für macOS

Ein macOS Desktop Widget, das Glukose-Werte von einem Nightscout-Server anzeigt.

## Features

- **Echtzeit Glukose-Anzeige**: Zeigt den aktuellen BG-Wert mit Trendpfeil an
- **Graph-Ansicht**: Mini-Graph mit den letzten 45 Minuten Daten
- **Mehrere Widget-Größen**: Klein, Mittel, Groß
- **Auto-Refresh**: Aktualisiert sich automatisch jede Minute

## Anforderungen

- macOS 14.0 oder neuer
- Xcode 15.0 oder neuer
- Swift 5.9 oder neuer
- Ein Nightscout-Server mit API-Zugang

## Installation

### Aus dem DMG (Release)

1. Lade die neueste `NightscoutWidget.dmg` von den [Releases](https://github.com/sebastiansucker/nightscout_widget/releases) herunter
2. Öffne das DMG und ziehe `NightscoutWidget.app` in den `Applications`-Ordner
3. Starte die App einmal aus dem Applications-Ordner (für die Erstkonfiguration)
4. Öffne das **Benachrichtigungscenter** (oberer rechter Bildschirmrand)
5. Klicke unten auf **"Widgets bearbeiten"** 
6. Suche nach **"NightscoutWidget"** in der Liste
7. Ziehe das Widget auf deinen Desktop oder ins Benachrichtigungscenter
8. Wähle die gewünschte Widget-Größe (Klein, Mittel oder Groß)

**Wichtig:** Das Widget ist **innerhalb** der App eingebettet (unter `NightscoutWidget.app/Contents/PlugIns/`). Du wirst im DMG nur die App selbst sehen, nicht das Widget separat - das ist korrekt so!

### Aus dem Quellcode

1. Projekt in Xcode öffnen
2. Bundle Identifier anpassen (falls nötig)
3. Widget Extension kompilieren und ausführen
4. Widget wie oben beschrieben zum Desktop hinzufügen

## Konfiguration

- Nightscout URL in der App eingeben
- Optional: Access Token für geschützte Server
- BG-Einheiten wählen (mg/dL oder mmol/L)

## Fehlerbehebung

### Widget erscheint nicht im Widget-Katalog

Falls das Widget nach der Installation nicht im Widget-Katalog erscheint:

1. **App erneut öffnen** und mindestens 10 Sekunden warten
2. **System-Cache zurücksetzen** (Terminal öffnen und folgende Befehle ausführen):
   ```bash
   pluginkit -r
   killall Dock
   killall NotificationCenter
   ```
3. Warte einige Sekunden und öffne dann das Benachrichtigungscenter erneut
4. Das Widget sollte jetzt unter "Nightscout" im Katalog erscheinen

### Widget zeigt keine Daten an

- Überprüfe die Nightscout-URL in den Einstellungen
- Stelle sicher, dass dein Nightscout-Server erreichbar ist
- Prüfe ob ein API-Token benötigt wird
- Schau in den Systemeinstellungen nach, ob die App Netzwerkzugriff hat

## Disclaimer

Dieses Projekt dient ausschließlich zu Bildungs- und Informationszwecken. Es ist nicht FDA-zugelassen und sollte nicht für medizinische Entscheidungen verwendet werden.
