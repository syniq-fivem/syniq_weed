local success, msg = lib.checkDependency('oxmysql', '2.7.3')

if success then
    success, msg = lib.checkDependency('ox_lib', '3.24.0')
end

---@diagnostic disable-next-line: param-type-mismatch
if not success then return warn(msg) end

lib.locale()

local Plants = {}

MySQL.ready(function()
    Wait(1000)
    local success, error = pcall(MySQL.scalar.await, 'SELECT 1 FROM `weed_plants`')

    if not success then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `weed_plants` (
            `id` longtext DEFAULT NULL,
            `data` longtext DEFAULT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
        ]])

        print('Database was successfully created!')
    end
end)

local function fetchPlants()
    local result = MySQL.query.await('SELECT * FROM `weed_plants`')

    if result[1] then
        for k,v in pairs(result) do
            local data = json.decode(v.data)
            Plants[v.id] = {
                data = data,
                entity = CreateObjectNoOffset(table.type(data.seedData) == 'empty' and `weed_empty_pot` or Config.seeds[data.seedData.seed].stages[data.seedData.stage].prop, data.coords.x, data.coords.y, data.coords.z, true, true, false)
            }
            FreezeEntityPosition(Plants[v.id].entity, true)
            Wait(100)
            Plants[v.id].netId = NetworkGetNetworkIdFromEntity(Plants[v.id].entity)
        end

        TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == cache.resource then
        Wait(2500)
        fetchPlants()
    end
end)

-- ###### CALLBACKS ###### --

lib.callback.register('syniq_weed:fetchPlants', function (source)
    return Plants
end)

lib.callback.register('syniq_weed:insertPot', function (source, data)
    local Player = GetPlayer(source)
    if not Player then return end

    if HasItem(Player, Config.items.pot, 1) then
        RemoveItem(Player, Config.items.pot, 1)

        MySQL.insert('INSERT INTO `weed_plants` (id, data) VALUES (?, ?)', { data.id, json.encode(data, { sort_keys = true }) })

        Plants[data.id] = {
            data = data,
            entity = CreateObjectNoOffset(`weed_empty_pot`, data.coords.x, data.coords.y, data.coords.z, true, true, false)
        }
        FreezeEntityPosition(Plants[data.id].entity, true)
        Wait(100)
        Plants[data.id].netId = NetworkGetNetworkIdFromEntity(Plants[data.id].entity)

        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.potPlaced'), 5000, 'success')
        TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
        return true
    end

    return false
end)

lib.callback.register('syniq_weed:hasItem', function (source, item, amount)
    local Player = GetPlayer(source)
    if not Player then return end

    return HasItem(Player, item, amount), GetItemCount(Player, item)
end)

lib.callback.register('syniq_weed:canFeedPlant', function (source, data)
    local Player = GetPlayer(source)
    if not Player then return end

    if data.type == 'water' then
        if Plants[data.id].data.seedData.water < 100 then
            if HasItem(Player, Config.items.water, 1) then
                return true
            else
                TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noWater'), 5000, 'error')
            end
        else
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.maxWater'), 5000, 'error')
        end
    elseif data.type == 'fertilizer' then
        if Plants[data.id].data.seedData.fertilizer < 100 then
            if HasItem(Player, Config.items.fertilizer, 1) then
                return true
            else
                TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noFertilizer'), 5000, 'error')
            end
        else
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.maxFertilizer'), 5000, 'error')
        end
    elseif data.type == 'health' then
        if Plants[data.id].data.seedData.health < 100 then
            if HasItem(Player, Config.items.spray, 1) then
                return true
            else
                TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noSplay'), 5000, 'error')
            end
        else
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.maxSpray'), 5000, 'error')
        end
    end

    return false
end)

lib.callback.register('syniq_weed:checkDestroy', function (source, data)
    local Player = GetPlayer(source)
    if not Player then return end

    local plant = Plants[data.id]
    if not plant then return end

    if HasItem(Player, Config.items.canister, 1) then
        RemoveItem(Player, Config.items.canister, 1)
        return true
    else
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noCanister'), 5000, 'error')
        return false
    end
end)

-- ###### EVENTS ###### --

RegisterNetEvent('syniq_weed:placeSeed', function (data)
    local Player = GetPlayer(source)
    if not Player then return end
    
    if HasItem(Player, data.seed, 1) then
        RemoveItem(Player, data.seed, 1)

        Plants[data.id].data.seedData = {
            seed = data.seed,
            growth = 0.0,
            health = 30.0,
            water = 30.0,
            fertilizer = 30.0,
            stage = 1,
        }

        DeleteEntity(Plants[data.id].entity)
        Plants[data.id].entity = nil
        Plants[data.id].netId = nil
        Plants[data.id].entity = CreateObjectNoOffset(Config.seeds[data.seed].stages[1].prop, Plants[data.id].data.coords.x, Plants[data.id].data.coords.y, Plants[data.id].data.coords.z, true, true, false)
        FreezeEntityPosition(Plants[data.id].entity, true)
        Wait(100)
        Plants[data.id].netId = NetworkGetNetworkIdFromEntity(Plants[data.id].entity)

        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.seedPlaced'), 5000, 'success')
        TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
    end
end)

RegisterNetEvent('syniq_weed:feedPlant', function (data)
    local Player = GetPlayer(source)
    if not Player then return end

    local growth = Config.growth
    if data.type == 'water' then
        if HasItem(Player, Config.items.water, 1) then
            RemoveItem(Player, Config.items.water, 1)
            
            Plants[data.id].data.seedData.water += growth.giveWater
            if Plants[data.id].data.seedData.water > 100.0 then
                Plants[data.id].data.seedData.water = 100.0
            end

            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.wateredPlant'), 5000, 'success')
            TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
        else
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noWater'), 5000, 'error')
        end
    elseif data.type == 'fertilizer' then
        if HasItem(Player, Config.items.fertilizer, 1) then
            RemoveItem(Player, Config.items.fertilizer, 1)
            
            Plants[data.id].data.seedData.fertilizer += growth.giveFertilizer
            if Plants[data.id].data.seedData.fertilizer > 100.0 then
                Plants[data.id].data.seedData.fertilizer = 100.0
            end

            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.fetilizedPlant'), 5000, 'success')
            TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
        else
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noFertilizer'), 5000, 'error')
        end
    elseif data.type == 'health' then
        if HasItem(Player, Config.items.spray, 1) then
            RemoveItem(Player, Config.items.spray, 1)
            
            Plants[data.id].data.seedData.health += growth.giveHealth
            if Plants[data.id].data.seedData.health > 100.0 then
                Plants[data.id].data.seedData.health = 100.0
            end

            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.sprayedPlant'), 5000, 'success')
            TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
        else
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noSplay'), 5000, 'error')
        end
    end
end)

RegisterNetEvent('syniq_weed:harvestPlant', function (data)
    local Player = GetPlayer(source)
    if not Player then return end

    local plant = Plants[data.id]
    if not plant then return end

    if HasItem(Player, Config.items.shovel, 1) then
        if DoesEntityExist(Plants[data.id].entity) then
            DeleteEntity(Plants[data.id].entity)
    
            local reward = plant.data.seedData.health < 20.0 and Config.seeds[plant.data.seedData.seed].reward.min or (plant.data.seedData.health > 20.0 and plant.data.seedData.health < 100.0) and math.random(Config.seeds[plant.data.seedData.seed].reward.min, Config.seeds[plant.data.seedData.seed].reward.max) or (plant.data.seedData.health >= 98.0 or plant.data.seedData.health <= 100.0) and Config.seeds[plant.data.seedData.seed].reward.max
            AddItem(Player, Config.seeds[plant.data.seedData.seed].item, reward)
            TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.harvestedPlant'):format(reward, Config.seeds[plant.data.seedData.seed].label), 5000, 'success')

            MySQL.update('DELETE FROM `weed_plants` WHERE id = ?', { data.id })
            Plants[data.id] = nil
            TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
        end
    else
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noShovel'), 5000, 'error')
    end
end)

RegisterNetEvent('syniq_weed:destroyPlant', function (data)
    local Player = GetPlayer(source)
    if not Player then return end

    local plant = Plants[data.id]
    if not plant then return end

    if DoesEntityExist(Plants[data.id].entity) then
        DeleteEntity(Plants[data.id].entity)
        MySQL.update('DELETE FROM `weed_plants` WHERE id = ?', { data.id })
        Plants[data.id] = nil
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.destroyedPlant'), 5000, 'success')
        TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
    end
end)

RegisterNetEvent('syniq_weed:saveCoords', function (data)
    local Player = GetPlayer(source)
    if not Player then return end

    local plant = Plants[data.id]
    if not plant then return end

    Plants[data.id].data.coords = data.coords
    if data.enable then
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.plantCarried'), 5000, 'success') 
    end

    TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
end)

RegisterNetEvent('syniq_weed:purchaseItem', function (data)
    local Player = GetPlayer(source)
    if not Player then return end

    if HasMoney(Player, data.price) then
        RemoveMoney(Player, data.price)
        AddItem(Player, data.item, data.amount)
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.itemPurchased'):format(data.label, data.price), 5000, 'success')
    else
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.noMoney'), 5000, 'error')
    end
end)

-- ###### COMMANDS ###### --

if Config.commands['getId'] and Config.commands['getId'].enable then
    lib.addCommand(Config.commands['getId'].command, {
        help = Config.commands['getId'].help,
        restricted = Config.commands['getId'].permission
    }, function(source, args, raw)
        local Player = GetPlayer(source)
        if not Player then return end

        TriggerClientEvent('syniq_weed:getClosestPlant', source)
    end)
end

if Config.commands['tpPlant'] and Config.commands['tpPlant'].enable then
    lib.addCommand(Config.commands['tpPlant'].command, {
        help = Config.commands['tpPlant'].help,
        restricted = Config.commands['tpPlant'].permission,
        params = Config.commands['tpPlant'].params,
    }, function(source, args, raw)
        local Player = GetPlayer(source)
        if not Player then return end

        local plant = Plants[args.id]
        if not plant then
            TriggerClientEvent('syniq_weed:notify', source, locale('notify.error.title'), locale('notify.error.noPlant'), 5000, 'error')
            return
        end

        SetEntityCoords(GetPlayerPed(source), plant.data.coords.x, plant.data.coords.y, plant.data.coords.z)
        TriggerClientEvent('syniq_weed:notify', source, locale('notify.success.title'), locale('notify.success.teleportedPlant'), 5000, 'success')
    end)
end

if Config.commands['deletePlant'] and Config.commands['deletePlant'].enable then
    lib.addCommand(Config.commands['deletePlant'].command, {
        help = Config.commands['deletePlant'].help,
        restricted = Config.commands['deletePlant'].permission,
        params = Config.commands['deletePlant'].params,
    }, function(source, args, raw)
        local Player = GetPlayer(source)
        if not Player then return end

        local plant = Plants[args.id]
        if not plant then
            TriggerClientEvent('syniq_weed:notify', source, locale('notify.error.title'), locale('notify.error.noPlant'), 5000, 'error')
            return
        end

        if DoesEntityExist(plant.entity) then
            DeleteEntity(plant.entity)
        end

        Plants[args.id] = nil
        MySQL.update('DELETE FROM `weed_plants` WHERE id = ?', { args.id })
        
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.success.title'), locale('notify.success.deletedPlant'), 5000, 'success')
        TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
    end)
end

-- ###### USABLE ITEMS ###### --

CreateUsableItem(Config.items.pot, function (source)
    local Player = GetPlayer(source)
    if not Player then return end

    local count = 0

    for k,v in pairs(Plants) do
        if v.data.owner == GetPlayerId(Player) then
            count += 1
        end
    end

    if count == Config.maxPlants then
        TriggerClientEvent('syniq_weed:notify', GetPlayerSource(Player), locale('notify.error.title'), locale('notify.error.maxPlants'), 5000, 'error')
        return
    end

    TriggerClientEvent('syniq_weed:placePot', source)
end)

-- ###### INTERVALS ###### --

local growth = Config.growth

SetInterval(function()
    for id, plant in pairs(Plants) do
        if table.type(plant.data.seedData) ~= 'empty' and plant.data.seedData.growth <= 99.0 then

            Plants[id].data.seedData.fertilizer -= growth.reduceFertilizer
            Plants[id].data.seedData.water -= growth.reduceWater
            Plants[id].data.seedData.health -= growth.reduceHealth

            if Plants[id].data.seedData.water > 0 and Plants[id].data.seedData.fertilizer > 0 then
                Plants[id].data.seedData.growth += growth.receiveGrowth
            end

            if Plants[id].data.seedData.growth > 100.0 then
                Plants[id].data.seedData.growth = 100.0
            end

            if Plants[id].data.seedData.fertilizer < 0.0 then
                Plants[id].data.seedData.fertilizer = 0.0
            end

            if Plants[id].data.seedData.health < 0.0 then
                Plants[id].data.seedData.health = 0.0
            end

            if Plants[id].data.seedData.water < 0.0 then
                Plants[id].data.seedData.water = 0.0
            end

            if plant.data.seedData.stage == 1 and Plants[id].data.seedData.growth > Config.seeds[plant.data.seedData.seed].stages[2].percent and Plants[id].data.seedData.health > 0 then
                if DoesEntityExist(Plants[id].entity) then
                    DeleteEntity(Plants[id].entity)
                    Plants[id].entity = nil
                    Plants[id].netId = nil
                    Plants[id].entity = CreateObjectNoOffset(Config.seeds[plant.data.seedData.seed].stages[2].prop, plant.data.coords.x, plant.data.coords.y, plant.data.coords.z, true, true, false)
                    FreezeEntityPosition(Plants[id].entity, true)
                    Wait(100)
                    Plants[id].netId = NetworkGetNetworkIdFromEntity(Plants[id].entity)
                    Plants[id].data.seedData.stage = 2
                end
            end
            
            if plant.data.seedData.stage == 2 and Plants[id].data.seedData.growth > Config.seeds[plant.data.seedData.seed].stages[3].percent and Plants[id].data.seedData.health > 0 then
                if DoesEntityExist(Plants[id].entity) then
                    DeleteEntity(Plants[id].entity)
                    Plants[id].entity = nil
                    Plants[id].netId = nil
                    Plants[id].entity = CreateObjectNoOffset(Config.seeds[plant.data.seedData.seed].stages[3].prop, plant.data.coords.x, plant.data.coords.y, plant.data.coords.z, true, true, false)
                    FreezeEntityPosition(Plants[id].entity, true)
                    Wait(100)
                    Plants[id].netId = NetworkGetNetworkIdFromEntity(Plants[id].entity)
                    Plants[id].data.seedData.stage = 3
                end
            end
        end
    end
    
    TriggerClientEvent('syniq_weed:updateClient', -1, Plants)
end, growth.update)

local function saveToDB(delete)
    local insertTable = {}
    if table.type(Plants) == 'empty' then return end

    for k,v in pairs(Plants) do
        insertTable[#insertTable + 1] = { query = 'UPDATE `weed_plants` SET `data` = ? WHERE `id` = ?', values = { json.encode(v.data, {sort_keys = true} ), k } }
        if delete and DoesEntityExist(Plants[k].entity) then
            DeleteEntity(Plants[k].entity)
        end
    end

    MySQL.transaction(insertTable)
end

SetInterval(function()
    saveToDB(false)
end, 600000)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        saveToDB(true)
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(60000)
            saveToDB(true)
        end)
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function(eventData)
    saveToDB(true)
end)

CreateThread(function()
    lib.versionCheck('syniq-fivem/syniq_weed')
end)
