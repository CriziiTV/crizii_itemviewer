# crizii_itemviewer

---

## 🇬🇧 English

**crizii_itemviewer** is a modern item viewer for RedM servers using VORP-Core and vorp_inventory. Admins can browse all items and view details, and directly give items to other players. Regular players do not have access to the item viewer.

### ✨ Features
- Clear item list with image, name & description (admin only)
- Search & filter function
- Responsive, dark UI (90% of display)
- Admin panel: give items to players
- Multilingual (default: German)
- **NEW:** Intelligent caching system for better performance
- **NEW:** Advanced error handling and logging
- **NEW:** Performance monitoring and metrics
- **NEW:** Configurable admin groups and cache settings
- **NEW:** Keyboard navigation (arrow keys, ESC, Enter)

### ⚙️ Requirements
- RedM server with VORP-Core & vorp_inventory
- ox_lib
- Populated `items` table (item, label, desc, ...)
- Item images: `vorp_inventory/html/img/items/<item>.png`

### 🚀 Installation
1. Copy `crizii_itemviewer` folder to `resources`
2. Add to `server.cfg`:
   ```
   ensure crizii_itemviewer
   ```
3. Make sure `vorp_inventory` & `ox_lib` are loaded

### 🛠️ Configuration
- Main settings: `config.lua`
- Language/UI: customizable in HTML & JS
- **NEW:** Cache settings, admin groups, performance options

### 🎮 Usage
- In-game: type `/itemviewer` in chat (admin only)
- Browse & filter items
- Select item, player & amount
- **NEW:** `/resetitemviewercache` to manually reset cache

### ⌨️ Keyboard Controls
- **ESC:** Close item viewer
- **Arrow Keys:** Navigate between items
- **Enter:** Select focused item for giving
- **Mouse:** Click to focus items

### ℹ️ Notes
- Only items with image & DB entry are shown
- Item viewer and giving items is admin-only (VORP group)
- UI adapts to screen size
- **NEW:** Automatic cache invalidation every 5 minutes
- **NEW:** Performance logging for debugging

### 💬 Support
Questions/feedback: contact crizii or open an issue

---

## 🇩🇪 Deutsch

**crizii_itemviewer** ist ein moderner Item-Betrachter für RedM-Server mit VORP-Core und vorp_inventory. Nur Admins können alle Items durchsuchen, Details einsehen und Items direkt an andere Spieler vergeben. Normale Spieler haben keinen Zugriff auf den Item-Betrachter.

### ✨ Funktionen
- Übersichtliche Item-Liste mit Bild, Name & Beschreibung (nur Admin)
- Such- & Filterfunktion
- Responsive, dunkle UI (90% Display)
- Admin-Panel: Items an Spieler vergeben
- Mehrsprachigkeit (Standard: Deutsch)
- **NEU:** Intelligentes Cache-System für bessere Performance
- **NEU:** Erweiterte Fehlerbehandlung und Logging
- **NEU:** Performance-Monitoring und Metriken
- **NEU:** Konfigurierbare Admin-Gruppen und Cache-Einstellungen
- **NEU:** Tastatur-Navigation (Pfeiltasten, ESC, Enter)

### ⚙️ Voraussetzungen
- RedM-Server mit VORP-Core & vorp_inventory
- ox_lib
- Gefüllte `items`-Tabelle (item, label, desc, ...)
- Item-Bilder: `vorp_inventory/html/img/items/<item>.png`

### 🚀 Installation
1. Ordner `crizii_itemviewer` nach `resources` kopieren
2. In `server.cfg` eintragen:
   ```
   ensure crizii_itemviewer
   ```
3. `vorp_inventory` & `ox_lib` müssen geladen sein

### 🛠️ Konfiguration
- Einstellungen: `config.lua`
- Sprache/UI: HTML & JS anpassbar
- **NEU:** Cache-Einstellungen, Admin-Gruppen, Performance-Optionen

### 🎮 Nutzung
- Im Spiel: `/itemviewer` im Chat eingeben (nur Admin)
- Items durchsuchen & filtern
- Item auswählen, Spieler & Menge wählen
- **NEU:** `/resetitemviewercache` für manuellen Cache-Reset

### ⌨️ Tastatur-Steuerung
- **ESC:** Item-Viewer schließen
- **Pfeiltasten:** Zwischen Items navigieren
- **Enter:** Fokussiertes Item zum Vergeben auswählen
- **Maus:** Klick zum Fokussieren von Items

### ℹ️ Hinweise
- Nur Items mit Bild & Datenbank-Eintrag werden angezeigt
- Item-Betrachter und Item-Vergabe nur für Admins (VORP-Gruppe)
- UI passt sich Bildschirmgröße an
- **NEU:** Automatische Cache-Invalidierung alle 5 Minuten
- **NEU:** Performance-Logging für Debugging
- **1.2.9**: Das Kachel-Grid nutzt jetzt 90% der Itemviewer-Breite, zeigt immer ganze Kacheln pro Zeile (keine abgeschnittenen Kacheln mehr) und ist responsiver sowie moderner.

### 💬 Support
Fragen/Feedback: crizii kontaktieren oder Issue eröffnen


## 📝 Changelog

### 🇬🇧 English
- **1.2.9**: The item grid now uses 90% of the item viewer width, always shows full tiles per row (no cut-off tiles), and is more responsive and modern.
- **1.2.8**: Tooltip overlay (blue box top left) is now hidden by default to prevent a distracting element after login
- **1.2.7**: Increased tile, image, and font size for better readability and less truncated item names
- **1.2.6**: Added keyboard navigation (ESC, arrow keys, Enter) and improved UX with focus indicators
- **1.2.5**: Improved logging system - Debug and Info messages disabled by default, configurable log levels
- **1.2.4**: Changed command from `/openitemviewer` to `/itemviewer` for better usability
- **1.2.3**: Simplified tooltip - now shows only display name, description, item name and weight
- **1.2.2**: Fixed VORP-Core function calls (getGroup and getUsedCharacter are properties, not functions)
- **1.2.1**: Performance optimizations, intelligent caching system, improved error handling, admin status caching, performance metrics, configurable settings
- **1.2.0**: Tooltip improvements (last image in row now shows tooltip on the left)
- **1.1**: Tooltip wider, smaller font
- **1.0**: Release, responsive UI, admin panel, item images, readability improvements, bugfixes

### 🇩🇪 Deutsch
- **1.2.9**: Das Kachel-Grid nutzt jetzt 90% der Itemviewer-Breite, zeigt immer ganze Kacheln pro Zeile (keine abgeschnittenen Kacheln mehr) und ist responsiver sowie moderner.
- **1.2.8**: Tooltip-Overlay (blaues Kästchen oben links) wird nun standardmäßig ausgeblendet, um ein störendes Element nach dem Login zu verhindern
- **1.2.7**: Kachel-, Bild- und Schriftgröße erhöht für bessere Lesbarkeit und weniger abgeschnittene Itemnamen
- **1.2.6**: Tastatur-Navigation hinzugefügt (ESC, Pfeiltasten, Enter) und UX mit Fokus-Indikatoren verbessert
- **1.2.5**: Verbessertes Logging-System - Debug und Info-Nachrichten standardmäßig deaktiviert, konfigurierbare Log-Level
- **1.2.4**: Command von `/openitemviewer` zu `/itemviewer` geändert für bessere Benutzerfreundlichkeit
- **1.2.3**: Tooltip vereinfacht - zeigt jetzt nur noch Displayname, Beschreibung, Itemname und Gewicht
- **1.2.2**: VORP-Core Funktionsaufrufe behoben (getGroup und getUsedCharacter sind Eigenschaften, keine Funktionen)
- **1.2.1**: Performance-Optimierungen, intelligentes Cache-System, verbesserte Fehlerbehandlung, Admin-Status-Caching, Performance-Metriken, konfigurierbare Einstellungen
- **1.2.0**: Tooltip erscheint beim letzten Bild einer Reihe immer links
- **1.1**: Tooltip breiter, Schrift kleiner
- **1.0**: Release, responsive UI, Admin-Panel, Item-Bilder, Lesbarkeit, Bugfixes

