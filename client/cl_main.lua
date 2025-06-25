-- VORP benötigt keine Core-Initialisierung auf Client-Seite für diese Funktionen
lib.locale()

-- Cache für Admin-Status
local adminStatus = {
    isAdmin = false,
    lastCheck = 0,
    checkInterval = Config.Admin.checkInterval or 60
}

-- Hilfsfunktionen
local function log(message, level)
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
        print(string.format('[crizii_itemviewer] [CLIENT] [%s] %s', level or 'INFO', message))
    end
end

local function getCurrentTime()
    return GetGameTimer() / 1000
end

local function isAdminStatusValid()
    return adminStatus.lastCheck > 0 and 
           (getCurrentTime() - adminStatus.lastCheck) < adminStatus.checkInterval
end

local function HasAdminPerms(callback)
    if isAdminStatusValid() then
        callback(adminStatus.isAdmin)
        return
    end
    
    lib.callback('hdrp-itemviewer:checkAdmin', false, function(isAdmin)
        adminStatus.isAdmin = isAdmin
        adminStatus.lastCheck = getCurrentTime()
        callback(isAdmin)
    end)
end

local function validateItemData(data)
    if not data or not data.itemName or data.itemName == '' then
        log('Ungültige Item-Daten erhalten', 'ERROR')
        return false
    end
    return true
end

-- Event Handler
RegisterCommand('itemviewer', function()
    log('Item-Viewer wird geöffnet', 'DEBUG')
    TriggerServerEvent('hdrp-itemviewer:getItems')
end)

RegisterNetEvent('hdrp-itemviewer:receiveItems', function(items)
    if not items or type(items) ~= 'table' then
        log('Keine gültigen Items erhalten', 'ERROR')
        lib.notify({ type = 'error', description = 'Fehler beim Laden der Items' })
        return
    end
    
    local processedItems = {}
    local itemCount = 0
    
    for key, item in pairs(items) do
        if item and item.item then
            item.imageUrl = "nui://vorp_inventory/html/img/items/" .. (item.image or "")
            processedItems[key] = item
            itemCount = itemCount + 1
        end
    end
    
    log(string.format('Items verarbeitet: %d Items', itemCount), 'DEBUG')
    
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    SendNUIMessage({
        action = 'loadItems',
        items = processedItems,
        options = Config.Options
    })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    log('Item-Viewer geschlossen', 'DEBUG')
    cb({})
end)

local tempItemData = nil

RegisterNUICallback('giveItem', function(data, cb)
    if not validateItemData(data) then
        lib.notify({ type = 'error', description = 'Ungültige Item-Daten' })
        cb({})
        return
    end
    
    tempItemData = data
    log(string.format('Item-Vergebung angefordert: %s', data.itemName), 'DEBUG')
    
    HasAdminPerms(function(isAdmin)
        if not isAdmin then
            log('Nicht-Admin versuchte Item zu vergeben', 'WARN')
            lib.notify({ type = 'error', description = 'Du hast keine Berechtigung, diese Funktion zu nutzen.' })
            return
        end

        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })

        TriggerServerEvent('hdrp-itemviewer:requestPlayers')
    end)
    cb({})
end)

RegisterNetEvent('hdrp-itemviewer:receivePlayers', function(players)
    if not players or #players == 0 then
        log('Keine Spieler verfügbar', 'WARN')
        lib.notify({ type = 'error', description = 'Keine Spieler verfügbar.' })
        return
    end

    local options = {}
    for _, player in ipairs(players) do
        if player and player.id and player.name then
            table.insert(options, {
                label = string.format("[%s] %s", player.id, player.name),
                value = player.id
            })
        end
    end
    
    if #options == 0 then
        log('Keine gültigen Spieler-Optionen', 'ERROR')
        lib.notify({ type = 'error', description = 'Keine gültigen Spieler gefunden.' })
        return
    end

    local result = lib.inputDialog('Spieler auswählen', {
        { type = 'select', label = 'Spieler', options = options, required = true },
        { type = 'number', label = 'Menge', required = true, min = 1, max = 1000 }
    })

    if result and result[1] and result[2] then
        local targetId = tonumber(result[1])
        local targetAmount = tonumber(result[2])
        
        if targetId and targetAmount and targetAmount > 0 then
            if tempItemData then
                log(string.format('Vergebe Item: %s an Spieler %s, Menge: %d', tempItemData.itemName, targetId, targetAmount), 'INFO')
                TriggerServerEvent('hdrp-itemviewer:server:giveitem', targetId, tempItemData.itemName, targetAmount)
                lib.notify({ type = 'success', description = 'Item erfolgreich gesendet.' })
            end
        else
            log('Ungültige Spieler-ID oder Menge', 'ERROR')
            lib.notify({ type = 'error', description = 'Ungültige Eingabe.' })
        end
    end

    tempItemData = nil
end)

RegisterNetEvent('sendNUI')
AddEventHandler('sendNUI', function(data)
    if data and data.action then
        SendNUIMessage(data)
        log(string.format('NUI Event gesendet: %s', data.action), 'DEBUG')
    end
end)

-- Cache-Reset Command für Admins
RegisterCommand('resetitemviewercache', function()
    HasAdminPerms(function(isAdmin)
        if isAdmin then
            TriggerServerEvent('hdrp-itemviewer:resetCache')
            log('Cache-Reset angefordert', 'INFO')
        else
            lib.notify({ type = 'error', description = 'Nur Admins können den Cache zurücksetzen.' })
        end
    end)
end)

-- Periodischer Admin-Status Check
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(adminStatus.checkInterval * 1000)
        if not isAdminStatusValid() then
            HasAdminPerms(function(isAdmin)
                log(string.format('Admin-Status aktualisiert: %s', isAdmin and 'Admin' or 'Nicht-Admin'), 'DEBUG')
            end)
        end
    end
end)