
local activeBlips = {}
local blips = {} -- Store blips on the server

-- Add this event to handle loading saved blips
RegisterNetEvent('blips:loadSavedBlips')
AddEventHandler('blips:loadSavedBlips', function(savedBlips)
    for _, blipData in pairs(savedBlips) do
        local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
        SetBlipSprite(blip, blipData.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipData.scale)
        SetBlipColour(blip, blipData.color)
        SetBlipAsShortRange(blip, true)
        SetBlipPriority(blip, 10)
        
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(blipData.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(activeBlips, {
            id = blip,
            name = blipData.name,
            coords = blipData.coords,
            sprite = blipData.sprite,
            scale = blipData.scale,
            color = blipData.color
        })
    end
end)

-- Add this to your resource start handler
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('blips:requestSavedBlips')
end)


RegisterNetEvent('blips:syncAll')
AddEventHandler('blips:syncAll', function(serverBlips)
    print("Processing blips: " .. #serverBlips)
    
    for _, serverBlip in ipairs(serverBlips) do
        local blip = AddBlipForCoord(
            serverBlip.coords.x,
            serverBlip.coords.y,
            serverBlip.coords.z
        )
        
        SetBlipSprite(blip, serverBlip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, serverBlip.scale + 0.0)
        SetBlipColour(blip, serverBlip.color)
        SetBlipAsShortRange(blip, true)
        SetBlipPriority(blip, 10)
        
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(serverBlip.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(activeBlips, {
            id = blip,
            name = serverBlip.name,
            coords = serverBlip.coords,
            sprite = serverBlip.sprite,
            scale = serverBlip.scale,
            color = serverBlip.color
        })
    end
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('blips:requestSync')
end)

RegisterNetEvent('blips:sendBlips')
AddEventHandler('blips:sendBlips', function(blipsData)
    -- Clear existing blips first
    for _, blip in pairs(activeBlips) do
        if DoesBlipExist(blip.id) then
            RemoveBlip(blip.id)
        end
    end
    activeBlips = {}
    
    -- Create fresh blips from server data
    for _, blipData in pairs(blipsData) do
        local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
        SetBlipSprite(blip, blipData.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipData.scale)
        SetBlipColour(blip, blipData.color)
        SetBlipAsShortRange(blip, true)
        SetBlipPriority(blip, 10)
        
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(blipData.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(activeBlips, {
            id = blip,
            name = blipData.name,
            coords = blipData.coords,
            sprite = blipData.sprite,
            scale = blipData.scale,
            color = blipData.color
        })
    end
    print('✅ Blips loaded successfully:', #blipsData)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('blips:loadBlips')
    end
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('blips:loadBlips')
end)

-- Multiple trigger points to ensure loading
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('blips:loadBlips')
end)

-- Initial load request
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('blips:requestSync')
end)

-- At the top of your client file
RegisterNetEvent('blips:loadBlips')
AddEventHandler('blips:loadBlips', function()
    TriggerServerEvent('blips:requestSync')
end)

-- Add these handlers for different loading scenarios
-- Add this to ensure blips load when player joins
AddEventHandler('onClientResourceStart', function(resourceName)
    if(GetCurrentResourceName() == resourceName) then
        TriggerServerEvent('blips:requestSync')
    end
end)

CreateThread(function()
    Wait(1000) -- Short delay to ensure everything is ready
    TriggerServerEvent('blips:requestSync')
end)

-- Add this when player spawns
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('blips:requestSync')
end)






RegisterCommand(Config.Command, function()
    lib.registerContext({
        id = 'main_menu',
        title = 'Blip Creator',
        options = {
            {
                title = 'Create Blip',
                description = 'Add new map markers',
                icon = 'map-marker',
                menu = 'blip_menu'
            },
            {
                title = 'View Created Blips',
                description = 'View and manage your blips',
                icon = 'eye',
                onSelect = function()
                    local blipOptions = {}
                    local seenBlips = {} -- Track unique blips
                    
                    if #activeBlips == 0 then
                        lib.notify({
                            title = 'No Blips Found',
                            description = 'Create some blips first!',
                            type = 'info'
                        })
                        return
                    end
                    
                    for i, blip in ipairs(activeBlips) do
                        if not seenBlips[blip.name] then
                            seenBlips[blip.name] = true
                            table.insert(blipOptions, {
                                title = blip.name,
                                description = string.format('Coords: %.2f, %.2f, %.2f', blip.coords.x, blip.coords.y, blip.coords.z),
                                icon = 'location-dot',
                                onSelect = function()
                                    lib.registerContext({
                                        id = 'blip_actions',
                                        title = blip.name,
                                        menu = 'main_menu',
                                        options = {
                                            {
                                                title = 'Set Waypoint',
                                                description = 'Set GPS route to this blip',
                                                icon = 'route',
                                                onSelect = function()
                                                    SetNewWaypoint(blip.coords.x, blip.coords.y)
                                                    lib.notify({
                                                        title = 'Waypoint Set',
                                                        description = 'Route set to ' .. blip.name,
                                                        type = 'success'
                                                    })
                                                end
                                            },
                                            {
                                                title = 'Delete Blip',
                                                description = 'Remove this blip from the map',
                                                icon = 'trash',
                                                onSelect = function()
                                                    -- Remove from map
                                                    for _, activeBlip in ipairs(activeBlips) do
                                                        if DoesBlipExist(activeBlip.id) then
                                                            RemoveBlip(activeBlip.id)
                                                        end
                                                    end
                                                    
                                                    -- Clear from active blips
                                                    activeBlips = {}
                                                    
                                                    -- Delete from server
                                                    TriggerServerEvent('blips:deleteBlip', blip.name)
                                                    
                                                    -- Close menu and notify
                                                    lib.showContext('main_menu')
                                                    lib.notify({
                                                        title = 'Blip Deleted',
                                                        description = blip.name .. ' has been removed',
                                                        type = 'success'
                                                    })
                                                end
                                            }
                                        }
                                    })
                                    lib.showContext('blip_actions')
                                end
                            })
                        end
                    end
                    
                    lib.registerContext({
                        id = 'view_blips',
                        title = 'Created Blips',
                        menu = 'main_menu',
                        options = blipOptions
                    })
                    
                    lib.showContext('view_blips')
                end
            }
        }
    })

    lib.registerContext({
        id = 'blip_menu',
        title = 'Blip Creator',
        menu = 'main_menu',
        options = {
            {
                title = 'Create New Blip',
                description = 'Add a new map marker at your location',
                icon = 'plus',
                onSelect = function()
                    local input = lib.inputDialog('Create New Blip', {
                        {type = 'input', label = 'Blip Name', description = 'Enter name for the blip', required = true},
                        {type = 'select', label = 'Blip Type', options = {
                            {label = 'Standard', value = 1},
                            {label = 'Car', value = 225},
                            {label = 'Luxury Car', value = 523},
                            {label = 'Race Car', value = 127},
                            {label = 'Mechanic', value = 446},
                            {label = 'Car Dealership', value = 326},
                            {label = 'Store', value = 52},
                            {label = 'Police Station', value = 60},
                            {label = 'Hospital', value = 61},
                            {label = 'Bank', value = 108},
                            {label = 'Race Flag', value = 38},
                            {label = 'Garage', value = 357},
                            {label = 'Gas Station', value = 361},
                            {label = 'Weed Leaf', value = 140},
                            {label = 'Skull', value = 303},
                            {label = 'Question Mark', value = 66}, 
                            {label = 'Warning', value = 84},
                            {label = 'Briefcase', value = 408}, 
                            {label = 'Dollar Sign', value = 500},
                            {label = 'Clothes Store', value = 73},
                            {label = 'Gun Store', value = 110},
                            {label = 'Car Dealership', value = 326},
                            {label = 'Pills', value = 51},
                            {label = 'Chemical', value = 499},
                            {label = 'Razor Blade', value = 615},
                            {label = 'Restaurant', value = 93},
                            {label = 'Bar', value = 93},
                            {label = 'Club', value = 121},
                            {label = 'House', value = 40},
                            {label = 'Apartment', value = 475},
                            {label = 'Office', value = 475},
                            {label = 'Warehouse', value = 473},
                            {label = 'Helicopter', value = 43},
                            {label = 'Plane', value = 307},
                            {label = 'Boat', value = 427},
                            {label = 'Parking', value = 357},
                            {label = 'Repair Shop', value = 446},
                            {label = 'Casino', value = 679},
                            {label = 'Golf', value = 109}
                        }, default = 1, required = true},
                        {type = 'select', label = 'Blip Color', options = {
                            {label = 'White', value = 0},
                            {label = 'Red', value = 1},
                            {label = 'Green', value = 2},
                            {label = 'Blue', value = 3},
                            {label = 'Yellow', value = 5},
                            {label = 'Purple', value = 7},
                            {label = 'Pink', value = 8},
                            {label = 'Orange', value = 17},
                            {label = 'Light Blue', value = 38},
                            {label = 'Lime Green', value = 52},
                            {label = 'Gray', value = 64},
                            {label = 'Black', value = 40}
                        }, default = 0, required = true},
                        {type = 'number', label = 'Blip Scale', description = 'Enter blip scale (0.1-2.0)', default = 1.0, required = true}
                    })
                    
                    if input then
                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
                        
                        -- Create and configure the blip
                        local blip = AddBlipForCoord(x, y, z)
                        
                        -- Essential blip configuration
                        SetBlipSprite(blip, input[2])
                        SetBlipDisplay(blip, 4)
                        SetBlipScale(blip, input[4] + 0.0)
                        SetBlipColour(blip, input[3])
                        SetBlipAsShortRange(blip, true)
                        SetBlipPriority(blip, 10)
                        
                        -- Set blip name
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentString(input[1])
                        EndTextCommandSetBlipName(blip)
                        
                        -- Store blip reference with all necessary data
                        local blipData = {
                            id = blip,
                            name = input[1],
                            coords = vector3(x, y, z),
                            sprite = input[2],
                            scale = input[4],
                            color = input[3]
                        }
                        
                        -- Add to local blips immediately
                        table.insert(activeBlips, blipData)
                        
                        -- Save to server
                        TriggerServerEvent('blips:saveBlip', blipData)
                        
                        -- Force immediate display
                        TriggerEvent('blips:syncAll', {blipData})
                        lib.notify({
                            title = 'Blip Created',
                            description = 'Name: ' .. input[1] .. ' at your location',
                            type = 'success',
                            duration = 5000
                        })
                    end
                end
            },
            {
                title = 'Test Blip',
                description = 'Create a test blip with preset values',
                icon = 'vial',
                onSelect = function()
                    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
                    local blip = AddBlipForCoord(x, y, z)
                    SetBlipSprite(blip, 1)
                    SetBlipDisplay(blip, 4)
                    SetBlipScale(blip, 1.0)
                    SetBlipColour(blip, 2)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString('Test Blip')
                    EndTextCommandSetBlipName(blip)
                    
                    lib.notify({
                        title = 'Test Blip Created',
                        description = 'A test blip has been placed at your location',
                        type = 'success',
                        duration = 5000
                    })
                end
            }
        }
    })

    lib.showContext('main_menu')
end)

