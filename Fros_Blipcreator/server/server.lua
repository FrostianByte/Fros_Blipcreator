local blips = {} -- Store blips on the server

-- Function to load blips from JSON file
local function loadBlips()
    local file = LoadResourceFile(GetCurrentResourceName(), "blips.json")
    if file and file ~= "" then
        local decoded = json.decode(file)
        if decoded then
            blips = decoded
        else
            blips = {} 
        end
    else
        blips = {} 
    end
    print("📍 Blips loaded:", json.encode(blips))
end


-- Load blips from JSON when server starts
CreateThread(function()
    local savedBlips = LoadResourceFile(GetCurrentResourceName(), "blips.json")
    if savedBlips then
        blips = json.decode(savedBlips) or {}
        print('Loaded ' .. #blips .. ' blips from storage')
    end
end)


-- Function to save blips to JSON file
local function saveBlips()
    SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(blips, { indent = true }), -1)
    print("📝 Blips saved:", json.encode(blips))
end

-- Load blips from JSON file on server start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local savedBlips = LoadResourceFile(GetCurrentResourceName(), "blips.json")
        if savedBlips then
            blips = json.decode(savedBlips) or {}
            print("📍 Loaded " .. #blips .. " blips from storage")
        end
    end
end)


-- Save blips when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(blips, {indent = true}), -1)
        print("📝 Saved " .. #blips .. " blips to storage")
    end
end)

-- Save new blips
RegisterNetEvent('blips:saveBlip')
AddEventHandler('blips:saveBlip', function(blipData)
    -- Remove the ID before saving (client-side only data)
    blipData.id = nil
    table.insert(blips, blipData)
    SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(blips, {indent = true}), -1)
    -- Sync to all clients
    TriggerClientEvent('blips:syncAll', -1, blips)
end)

-- Handle blip deletion
RegisterNetEvent('blips:deleteBlip')
AddEventHandler('blips:deleteBlip', function(blipName)
    for i = #blips, 1, -1 do
        if blips[i].name == blipName then
            table.remove(blips, i)
            break
        end
    end
    SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(blips, {indent = true}), -1)
    TriggerClientEvent('blips:syncAll', -1, blips)
end)

-- Handle blip sync requests
RegisterNetEvent('blips:requestSync')
AddEventHandler('blips:requestSync', function()
    TriggerClientEvent('blips:syncAll', source, blips)
end)

-- Handle new player connections
AddEventHandler('playerJoining', function()
    local source = source
    TriggerClientEvent('blips:syncAll', source, blips)
end)
