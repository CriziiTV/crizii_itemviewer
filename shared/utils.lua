-- Gemeinsame Hilfsfunktionen für crizii_itemviewer

Utils = {}

-- Logging-Funktion
function Utils.log(message, level, context)
    if not Config.Logging.enabled then return end
    
    local shouldLog = false
    if level == "DEBUG" and Config.Logging.showDebug then
        shouldLog = true
    elseif level == "INFO" and Config.Logging.showInfo then
        shouldLog = true
    elseif level == "WARN" and Config.Logging.showWarnings then
        shouldLog = true
    elseif level == "ERROR" and Config.Logging.showErrors then
        shouldLog = true
    end
    
    if shouldLog then
        local contextStr = context and string.format('[%s]', context) or ''
        print(string.format('[crizii_itemviewer]%s [%s] %s', contextStr, level or 'INFO', message))
    end
end

-- Admin-Gruppen prüfen
function Utils.isAdminGroup(group)
    if not group then return false end
    
    for _, adminGroup in ipairs(Config.Admin.groups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end

-- Itemnamen bereinigen
function Utils.cleanItemName(itemName)
    if not itemName or itemName == '' then
        return nil
    end
    
    local cleanName = itemName
    if cleanName:sub(-4) == ".png" then
        cleanName = cleanName:sub(1, -5)
    end
    
    return cleanName
end

-- Menge validieren
function Utils.validateAmount(amount, min, max)
    local validAmount = tonumber(amount) or 1
    min = min or 1
    max = max or 1000
    
    if validAmount < min then
        validAmount = min
    elseif validAmount > max then
        validAmount = max
    end
    
    return validAmount
end

-- Daten validieren
function Utils.validateData(data, requiredFields)
    if not data or type(data) ~= 'table' then
        return false
    end
    
    if requiredFields then
        for _, field in ipairs(requiredFields) do
            if not data[field] or data[field] == '' then
                return false
            end
        end
    end
    
    return true
end

-- Cache-Status prüfen
function Utils.isCacheValid(lastUpdate, duration)
    return lastUpdate > 0 and (os.time() - lastUpdate) < duration
end

-- Performance-Metriken
Utils.Metrics = {
    startTime = 0,
    measurements = {}
}

function Utils.startTimer(name)
    Utils.Metrics.measurements[name] = GetGameTimer()
end

function Utils.endTimer(name)
    if Utils.Metrics.measurements[name] then
        local duration = GetGameTimer() - Utils.Metrics.measurements[name]
        Utils.log(string.format('Performance: %s took %dms', name, duration), 'DEBUG', 'PERF')
        Utils.Metrics.measurements[name] = nil
        return duration
    end
    return 0
end 