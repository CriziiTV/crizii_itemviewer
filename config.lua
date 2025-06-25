Config = {}

-- Performance & Cache Einstellungen
Config.Cache = {
    enabled = true,
    duration = 300, -- 5 Minuten Cache-Dauer
    maxItems = 1000 -- Maximale Anzahl Items im Cache
}

Config.Admin = {
    groups = {"admin", "superadmin"}, -- Admin-Gruppen
    checkInterval = 60 -- Admin-Status Check alle 60 Sekunden
}

Config.Performance = {
    maxPlayersPerRequest = 50, -- Maximale Spieler pro Request
    batchSize = 20, -- Batch-Größe für Datenbank-Updates
}

-- Logging-Konfiguration
Config.Logging = {
    enabled = true, -- Logging aktivieren/deaktivieren
    level = "WARN", -- Log-Level: DEBUG, INFO, WARN, ERROR
    showDebug = false, -- Debug-Nachrichten anzeigen
    showInfo = false, -- Info-Nachrichten anzeigen
    showWarnings = true, -- Warnungen anzeigen
    showErrors = true -- Fehler anzeigen
}

Config.Options = {
    activeInputFilter = true,
    showLabel = true,
    showName = true,
    showWeight = true,
    showType = true,
    showUnique = true,
    showDescription = true
}