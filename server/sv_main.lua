local VORPcore = {}
TriggerEvent("getCore",function(core)
    VORPcore = core
end)
lib.locale()

-- Cache-System für Items
local itemCache = {
    data = {},
    lastUpdate = 0,
    isUpdating = false
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
        print(string.format('[crizii_itemviewer] [%s] %s', level or 'INFO', message))
    end
end

local function isAdmin(source)
    local User = VORPcore.getUser(source)
    if not User then return false end
    
    local group = User.getGroup
    for _, adminGroup in ipairs(Config.Admin.groups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end

local function getCurrentTime()
    return os.time()
end

local function isCacheValid()
    return itemCache.lastUpdate > 0 and 
           (getCurrentTime() - itemCache.lastUpdate) < Config.Cache.duration
end

local function loadItemsFromDatabase(callback)
    if itemCache.isUpdating then
        -- Warte bis Update fertig ist
        Citizen.CreateThread(function()
            while itemCache.isUpdating do
                Citizen.Wait(100)
            end
            callback(itemCache.data)
        end)
        return
    end
    
    itemCache.isUpdating = true
    log('Lade Items aus Datenbank...', 'DEBUG')
    
    exports.oxmysql:execute('SELECT * FROM items', {}, function(result)
        if not result then
            log('Fehler beim Laden der Items aus der Datenbank', 'ERROR')
            itemCache.isUpdating = false
            callback({})
            return
        end
        
        local items = {}
        local itemCount = 0
        
        for _, item in ipairs(result) do
            if item.item and item.item ~= '' and itemCount < Config.Cache.maxItems then
                items[item.item] = {
                    item = item.item,
                    label = item.label,
                    image = item.item .. ".png",
                    description = item.desc or "",
                    weight = item.weight or 0,
                    type = item.type or "",
                    unique = false,
                    useable = item.usable == 1
                }
                itemCount = itemCount + 1
            elseif itemCount >= Config.Cache.maxItems then
                log(string.format('Cache-Limit erreicht (%d Items)', Config.Cache.maxItems), 'WARN')
                break
            else
                log(string.format('WARNUNG: Item ohne gültigen Namen gefunden: %s', tostring(item.item)), 'WARN')
            end
        end
        
        itemCache.data = items
        itemCache.lastUpdate = getCurrentTime()
        itemCache.isUpdating = false
        
        log(string.format('Items erfolgreich geladen: %d Items', itemCount), 'INFO')
        callback(items)
    end)
end

local function getItems(source, callback)
    if Config.Cache.enabled and isCacheValid() then
        log('Verwende gecachte Items', 'DEBUG')
        callback(itemCache.data)
    else
        loadItemsFromDatabase(callback)
    end
end

-- Event Handler
RegisterNetEvent('hdrp-itemviewer:getItems', function()
    local src = source
    
    -- Admin-Status prüfen
    if not isAdmin(src) then
        log(string.format('Nicht-Admin versuchte Zugriff: %s', src), 'WARN')
        TriggerClientEvent('vorp:TipBottom', src, 'Nur Admins können den Item-Viewer nutzen!', 4000)
        return
    end
    
    getItems(src, function(items)
        TriggerClientEvent('hdrp-itemviewer:receiveItems', src, items)
        
        -- Admin-Status an Client senden
        TriggerClientEvent('sendNUI', src, {action = 'setAdmin', isAdmin = true})
    end)
end)

lib.callback.register('hdrp-itemviewer:checkAdmin', function(source)
    return isAdmin(source)
end)

RegisterNetEvent('hdrp-itemviewer:requestPlayers', function()
    local src = source
    
    if not isAdmin(src) then
        log(string.format('Nicht-Admin versuchte Spielerliste abzurufen: %s', src), 'WARN')
        return
    end
    
    local players = {}
    local playerCount = 0
    local maxPlayers = Config.Performance.maxPlayersPerRequest
    
    for _, playerId in ipairs(GetPlayers()) do
        if playerCount >= maxPlayers then
            log(string.format('Spieler-Limit erreicht (%d Spieler)', maxPlayers), 'WARN')
            break
        end
        
        local targetSrc = tonumber(playerId)
        local User = VORPcore.getUser(targetSrc)
        if User then
            local Character = User.getUsedCharacter
            if Character then
                table.insert(players, {
                    id = targetSrc,
                    name = (Character.firstname or "John") .. " " .. (Character.lastname or "Doe")
                })
                playerCount = playerCount + 1
            end
        end
    end
    
    TriggerClientEvent('hdrp-itemviewer:receivePlayers', src, players)
    log(string.format('Spielerliste gesendet: %d Spieler', playerCount), 'DEBUG')
end)

RegisterNetEvent('hdrp-itemviewer:server:giveitem', function(targetId, itemName, amount)
    local src = source
    
    if not isAdmin(src) then
        log(string.format('Nicht-Admin versuchte Item zu geben: %s', src), 'WARN')
        TriggerClientEvent('vorp:TipBottom', src, 'Nur Admins können Items vergeben!', 4000)
        return
    end
    
    local TargetUser = VORPcore.getUser(targetId)
    if not TargetUser then
        log(string.format('Zielspieler nicht gefunden: %s', targetId), 'ERROR')
        TriggerClientEvent('vorp:TipBottom', src, 'Spieler nicht gefunden!', 4000)
        return
    end
    
    local Character = TargetUser.getUsedCharacter
    if not Character then
        log(string.format('Charakter nicht gefunden für Spieler: %s', targetId), 'ERROR')
        TriggerClientEvent('vorp:TipBottom', src, 'Charakter nicht gefunden!', 4000)
        return
    end

    -- Itemnamen bereinigen
    local cleanItemName = itemName
    if not cleanItemName or cleanItemName == "" then
        log('FEHLER: Kein gültiger Itemname übergeben', 'ERROR')
        TriggerClientEvent('vorp:TipBottom', src, 'Ungültiger Itemname!', 4000)
        return
    end
    
    if cleanItemName:sub(-4) == ".png" then
        cleanItemName = cleanItemName:sub(1, -5)
    end
    
    -- Menge validieren
    local validAmount = tonumber(amount) or 1
    if validAmount <= 0 then
        validAmount = 1
    end
    
    log(string.format('Gebe Item: %s an Spieler: %s Menge: %d', cleanItemName, targetId, validAmount), 'INFO')

    -- Item geben über vorp_inventory
    local success = exports.vorp_inventory:addItem(targetId, cleanItemName, validAmount)
    
    if success then
        TriggerClientEvent('vorp:TipBottom', src, "Item erfolgreich gesendet", 4000)
        log(string.format('Item erfolgreich vergeben: %s -> %s (%d)', cleanItemName, targetId, validAmount), 'INFO')
    else
        TriggerClientEvent('vorp:TipBottom', src, "Fehler beim Senden des Items", 4000)
        log(string.format('Fehler beim Vergeben von Item: %s -> %s (%d)', cleanItemName, targetId, validAmount), 'ERROR')
    end
end)

RegisterNetEvent('editItem', function(data)
    local src = source
    
    if not isAdmin(src) then
        log(string.format('Nicht-Admin versuchte Item zu bearbeiten: %s', src), 'WARN')
        TriggerClientEvent('vorp:TipBottom', src, 'Nur Admins dürfen Items bearbeiten!', 4000)
        return
    end
    
    if not data or not data.item or data.item == '' then
        log('Ungültige Daten beim Bearbeiten von Item', 'ERROR')
        TriggerClientEvent('vorp:TipBottom', src, 'Ungültige Daten!', 4000)
        return
    end
    
    log(string.format('Bearbeite Item: %s', data.item), 'INFO')
    
    -- Update Query mit verbesserter Fehlerbehandlung
    exports.oxmysql:execute('UPDATE items SET label = ?, desc = ?, weight = ?, type = ?, unique = ?, usable = ?, decay = ?, `delete` = ?, shouldClose = ? WHERE item = ?', {
        data.label or '',
        data.description or '',
        data.weight or 0,
        data.type or '',
        data.unique and 1 or 0,
        data.useable and 1 or 0,
        data.decay or '',
        data.delete and 1 or 0,
        data.shouldClose and 1 or 0,
        data.item
    }, function(affected)
        if affected and affected > 0 then
            -- Cache invalidieren
            itemCache.lastUpdate = 0
            
            -- Itemdaten neu laden und an den Client schicken
            exports.oxmysql:execute('SELECT * FROM items WHERE item = ?', {data.item}, function(result)
                if result and result[1] then
                    local item = result[1]
                    local itemData = {
                        item = item.item,
                        label = item.label,
                        image = item.item .. ".png",
                        description = item.desc or "",
                        weight = item.weight or 0,
                        type = item.type or "",
                        unique = item.unique == 1,
                        useable = item.usable == 1,
                        decay = item.decay or "",
                        delete = item["delete"] == 1,
                        shouldClose = item.shouldClose == 1
                    }
                    TriggerClientEvent('hdrp-itemviewer:liveUpdateItem', src, itemData)
                    TriggerClientEvent('vorp:TipBottom', src, 'Item erfolgreich gespeichert!', 4000)
                    TriggerClientEvent('editItem:response', src, {success=true})
                    log(string.format('Item erfolgreich bearbeitet: %s', data.item), 'INFO')
                else
                    log(string.format('Item nicht gefunden nach Update: %s', data.item), 'ERROR')
                    TriggerClientEvent('editItem:response', src, {success=false, error='Item nicht gefunden nach Update!'})
                end
            end)
        else
            log(string.format('Update fehlgeschlagen für Item: %s', data.item), 'ERROR')
            TriggerClientEvent('editItem:response', src, {success=false, error='Update fehlgeschlagen!'})
        end
    end)
end)

-- Cache-Reset Event für Admins
RegisterNetEvent('hdrp-itemviewer:resetCache', function()
    local src = source
    
    if not isAdmin(src) then
        log(string.format('Nicht-Admin versuchte Cache zu resetten: %s', src), 'WARN')
        return
    end
    
    itemCache.lastUpdate = 0
    itemCache.data = {}
    log('Cache manuell zurückgesetzt', 'INFO')
    TriggerClientEvent('vorp:TipBottom', src, 'Cache zurückgesetzt!', 4000)
end)

-- Periodischer Cache-Reset (alle 5 Minuten)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Cache.duration * 1000)
        if Config.Cache.enabled then
            itemCache.lastUpdate = 0
            log('Cache automatisch zurückgesetzt', 'DEBUG')
        end
    end
end)