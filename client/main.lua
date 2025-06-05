local Plants, Points, Targets = {}, {}, {}
local textUI, textUI2 = false, false
local menuID = nil
local Props = {
    water = 'prop_wateringcan',
    fertilizer = 'prop_oilcan_01a',
    shovel = 'prop_cs_trowel',
    spray = 'bkr_prop_weed_spray_01a',
    destroy = 'w_am_jerrycan',
}
local Particles = {
    fertilize = { 'core', 'ent_anim_pneumatic_drill'},
    water = { 'core', 'ent_sht_water' },
    destroy = { 'core', 'veh_petrol_leak_bike' },
    flame = { 'core', 'ent_ray_paleto_gas_flames' },
}
local Animations = {
    harvest = { 'base', 'amb@world_human_gardener_plant@male@base', 76 },
    spray = { 'weed_spraybottle_stand_spraying_02_inspector', 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', 1 },
    fertilize = { 'waterboard_loop_player', 'missfbi3_waterboard', 1 },
    water = { 'waterboard_loop_player', 'missfbi3_waterboard', 1 },
    destroy = { 'waterboard_loop_player', 'missfbi3_waterboard', 1 },
    carry = { 'idle', 'anim@heists@box_carry@', 49 },
}

lib.locale() -- Loading Locales

RegisterNetEvent('syniq_weed:placePot', function ()
    local model1 = lib.requestModel(`weed_empty_pot`)
    local offset = GetEntityCoords(cache.ped) + GetEntityForwardVector(cache.ped) * 2
    local obj = CreateObject(model1, offset.x, offset.y, offset.z, false, false, false)
    FreezeEntityPosition(obj, true)
    local gimzo_data = useGizmo(obj)

    if gimzo_data then
        local data = {
            id = GenerateId(),
            owner = GetIdentifier(),
            coords = gimzo_data.position,
            rotation = gimzo_data.rotation,
            seedData = {},
        }

        lib.callback('syniq_weed:insertPot', false, function ()
            DeleteEntity(obj)
        end, data)
    end
end)

local function GetClosestPlant(distance)
    local currentPlant
    local coords = GetEntityCoords(cache.ped)

    for id, v in pairs(Plants) do
        local disc = #(vec3(coords.x, coords.y, coords.z) - vec3(v.data.coords.x, v.data.coords.y, v.data.coords.z))
        
        if disc < (distance or 1.5) then
            currentPlant = Plants[id]
            break
        end
    end

    return currentPlant
end

local function SeedMenu(Plant)
    local seedsOptions = {}

    for k,v in pairs(Config.seeds) do
        local hasItem = lib.callback.await('syniq_weed:hasItem', false, k, 1)

        if hasItem then
            seedsOptions[#seedsOptions+1] = {
                title = v.label,
                icon = Config.imagePath:format(k),
                image = Config.imagePath:format(k),
                description = locale('seedMenu.putSeed'),
                onSelect = function ()
                    local hasItem = lib.callback.await('syniq_weed:hasItem', false, Config.items.shovel, 1)

                    if hasItem then
                        local object = CreateObj(Props.shovel, 0x6F06, vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0))
                        if not object then return end

                        if ProgressBar(locale('progress.placeSeed'), 5000, Animations.harvest[1], Animations.harvest[2], Animations.harvest[3]) then
                            ClearPedTasks(cache.ped)
                            DeleteEntity(object)
                            FreezeEntityPosition(cache.ped, false)
                            local data = {
                                id = Plant.data.id,
                                seed = k
                            }

                            TriggerServerEvent('syniq_weed:placeSeed', data)
                        end
                    else
                        Notification(locale('notify.error.title'), locale('notify.error.noShovel'), 5000, 'error')
                    end
                end
            }
        end
    end

    if #seedsOptions == 0 then
        seedsOptions[#seedsOptions+1] = {
            title = locale('seedMenu.noSeed'),
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'seed_menu',
        title = locale('seedMenu.title'),
        options = seedsOptions
    })
    
    lib.showContext('seed_menu')
end

local function PlantMenu(Plant)
    SendNUIMessage({ 
        action = 'openStatus',
        id = Plant.data.id,
        status = Plant.data.seedData,
        label = Config.seeds[Plant.data.seedData.seed].label,
    })
    SetNuiFocus(true, true)
    menuID = Plant.data.id
end

RegisterNUICallback('closeMenu', function (data, cb)
    SetNuiFocus(false, false)
    menuID = nil
end)

RegisterNUICallback('feedPlant', function (data, cb)
    SetNuiFocus(false, false)
    local pData = { type = data.type, id = data.id }

    lib.callback('syniq_weed:canFeedPlant', false, function (can)
        if not can then SetNuiFocus(true, true) return end

        local object, animation, effect
        if data.type == 'health' then
            object = CreateObj(Props.spray, 0x6F06, vector3(0.1, -0.05, -0.08), vector3(-50.0, -10.0, 20.0))
            animation = Animations.spray
        elseif data.type == 'fertilizer' then
            object = CreateObj(Props.fertilizer, 0x8CBD, vector3(0.1, -0.02, 0.35), vector3(0.0, 140.0, -140.0))
            animation = Animations.fertilize
            effect = Particles.fertilize
        elseif data.type == 'water' then
            object = CreateObj(Props.water, 0x8CBD, vector3(0.15, 0.0, 0.4), vector3(0.0, -180.0, -140.0))
            animation = Animations.water
            effect = Particles.water
        end
        if not object then return end

        if effect then PlayEffect(effect[1], effect[2], object, vec3(0.34, 0.0, 0.2), vec3(0.0, 0.0, 0.0), 5000) end
        
        if ProgressBar(locale('progress.sprayPlant'), 5000, animation[1], animation[2], animation[3]) then
            ClearPedTasks(cache.ped)
            DeleteEntity(object)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('syniq_weed:feedPlant', pData)
            SetNuiFocus(true, true)
            Wait(100)
            SendNUIMessage({ action = 'updateStatus', status = Plants[data.id].data.seedData})
        else
            ClearPedTasks(cache.ped)
            DeleteEntity(object)
            FreezeEntityPosition(cache.ped, false)
        end
    end, pData)
end)

RegisterNUICallback('harvestPlant', function (data, cb)
    local plant = Plants[data.id]?.data
    if not plant then return end

    if plant.seedData.growth >= 99.0 then
        SetNuiFocus(false, false)
        menuID = nil
        cb(true)
        local object = CreateObj(Props.shovel, 0x6F06, vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0))
        if not object then return end

        if ProgressBar(locale('progress.harvestPlant'), 10000, Animations.harvest[1], Animations.harvest[2], Animations.harvest[3]) then
            ClearPedTasks(cache.ped)
            DeleteEntity(object)
            FreezeEntityPosition(cache.ped, false)
            local pData = { id = data.id }
            TriggerServerEvent('syniq_weed:harvestPlant', pData)
        end
    else
        cb(false)
        Notification(locale('notify.error.title'), locale('notify.error.cantHarvest'), 5000, 'error')
    end
end)

RegisterNUICallback('carryPlant', function (data, cb)
    SetNuiFocus(false, false)
    menuID = nil

    local plant = Plants[data.id]
    if not plant then return end

    local entity = NetworkGetEntityFromNetworkId(plant.netId)
    if not entity then return end

    local offset = vec3(-0.06, 0.35, 0.05)
    local rotation = vec3(0, 0, 0)

    AttachEntityToEntity(entity, cache.ped, 0, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, true, 1, true)

    local function GetCoordsInFrontOfEntity(entity, distance)
        local entityCoords = GetEntityCoords(entity)
        local forwardVector = GetEntityForwardVector(entity)
        
        local targetCoords = vector3(
            entityCoords.x + forwardVector.x * distance,
            entityCoords.y + forwardVector.y * distance,
            entityCoords.z + forwardVector.z * distance
        )
    
        return targetCoords
    end

    TextUI(locale('textUI.carry'))
    textUI = true

    lib.requestAnimDict(Animations.carry[2])

    while true do
        Citizen.Wait(0)

        if not IsEntityPlayingAnim(cache.ped, Animations.carry[2], Animations.carry[1], Animations.carry[3]) then
            TaskPlayAnim(cache.ped, Animations.carry[2], Animations.carry[1], 8.0, -8.0, -1, Animations.carry[3], 0, false, false, false)
        end

        if IsControlJustPressed(0, 191) then
            HideTextUI()
            textUI = false
            local coords = GetCoordsInFrontOfEntity(cache.ped, 1.5)

            DetachEntity(entity, true, true)
            SetEntityCoords(entity, coords.x, coords.y, coords.z)
            PlaceObjectOnGroundProperly_2(entity)
            ClearPedTasks(cache.ped)

            local pData = { id = data.id, coords = GetEntityCoords(entity), enable = true }
            TriggerServerEvent('syniq_weed:saveCoords', pData)
            break
        end

        if IsControlJustPressed(0, 194) then
            DetachEntity(entity, true, true)
            SetEntityCoords(entity, plant.data.coords.x, plant.data.coords.y, plant.data.coords.z)
            HideTextUI()
            ClearPedTasks(cache.ped)
            textUI = false
            
            local pData = { id = data.id, coords = GetEntityCoords(entity), enable = false }
            TriggerServerEvent('syniq_weed:saveCoords', pData)
            break
        end
    end
end)

local function DestroyPlant(plant, cb)
    local entity = NetworkGetEntityFromNetworkId(plant.netId)
    if not entity then return end

    lib.callback('syniq_weed:checkDestroy', false, function (can)
        if not can then return end
        SetNuiFocus(false, false)
        menuID = nil

        local object = CreateObj(Props.destroy, 0x8CBD, vector3(0.15, 0.0, 0.25), vector3(0.0, -180.0, -140.0))
        if not object then return end

        cb(true)
        PlayEffect(Particles.destroy[1], Particles.destroy[2], object, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 5000, function()
            ClearPedTasks(cache.ped)
            DeleteEntity(object)
            FreezeEntityPosition(cache.ped, false)
        end)
        if ProgressBar(locale('progress.destroyPlant'), 5000, Animations.destroy[1], Animations.destroy[2], Animations.destroy[3]) then
            Wait(2000)
            PlayEffect(Particles.flame[1], Particles.flame[2], entity, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), 4000, function()
                Wait(200)
                local pData = { id = plant.data.id }
                TriggerServerEvent('syniq_weed:destroyPlant', pData)
            end)
        else
            ClearPedTasks(cache.ped)
            DeleteEntity(object)
            FreezeEntityPosition(cache.ped, false)
        end
    end, { id = plant.data.id })
end

RegisterNUICallback('destroyPlant', function (data, cb)

    local plant = Plants[data.id]
    if not plant then return end

    DestroyPlant(plant, cb)
end)

if not Config.useTarget then
    Citizen.CreateThread(function ()
        while true do
            local point = lib.points.getClosestPoint()

            if point then
                if point.currentDistance <= 2.5 and point.isClosest then
                    local currentPlant = GetClosestPlant()

                    if not textUI and currentPlant then
                        local text = (currentPlant.data.owner == GetIdentifier()) and locale('textUI.open') or (HasJob() and currentPlant.data.owner ~= GetIdentifier()) and locale('textUI.destroy')
                        TextUI(text)
                        textUI = true
                    end
                else
                    if textUI then
                        lib.hideTextUI()
                        textUI = false
                    end
                end
            else
                if textUI then
                    lib.hideTextUI()
                    textUI = false
                end
            end

            Citizen.Wait(250)
        end
    end)
end

local function nearbyPlant(point)
    if point.isClosest and point.currentDistance < 2.5 then
        local currentPlant = GetClosestPlant()
        if not currentPlant then return end

        if IsControlJustPressed(0, 38) and currentPlant.data.owner == GetIdentifier() then
            if not menuID then
                if table.type(currentPlant.data.seedData) == 'empty' then
                    SeedMenu(currentPlant)
                else
                    PlantMenu(currentPlant)
                end
            end
        end

        if IsControlJustPressed(0, 113) and HasJob() then
            DestroyPlant(currentPlant)
        end
    end
end

function SetUp()
    local fetchedPlants = lib.callback.await('syniq_weed:fetchPlants', false)

    if fetchedPlants then
        Plants = fetchedPlants
    end

    if not Config.useTarget then
        for k,v in pairs(Plants) do
            Points[k] = lib.points.new({
                coords = v.data.coords,
                distance = 15.0,
                plantId = k,
                data = v.data,
                nearby = nearbyPlant,
            })
        end
    else
        CreateTargetsPlant(Plants)
    end
end

RegisterNetEvent('syniq_weed:updateClient', function (plants)
    Plants = plants

    for k,v in pairs(plants) do
        if menuID and menuID == k then
            SendNUIMessage({
                action = 'updateStatus',
                status = v.data.seedData
            })
        end
    end

    if not Config.useTarget then
        for k,v in pairs(Points) do
            v:remove()
        end
        Points = {}

        for k,v in pairs(Plants) do
            Points[k] = lib.points.new({
                coords = v.data.coords,
                distance = 15.0,
                plantId = k,
                data = v.data,
                nearby = nearbyPlant,
            })
        end
    else
        CreateTargetsPlant(Plants)
    end
end)

function CreateTargetsPlant(Plants)
    for k,v in pairs(Targets) do
        RemoveEntity(v, { locale('target.openMenu'), locale('target.destroyPlant') })
    end
    Targets = {}

    for k,v in pairs(Plants) do
        Targets[k] = NetworkGetEntityFromNetworkId(v.netId)
        AddEntity(v.netId, {
            {
                icon = 'fa-solid fa-seedling',
                label = locale('target.openMenu'),
                onSelect = function(entity)
                    if not menuID then
                        if table.type(v.data.seedData) == 'empty' then
                            SeedMenu(v)
                        else
                            PlantMenu(v)
                        end
                    end
                end,
                canInteract = function(entity, distance, data)
                    return entity == NetworkGetEntityFromNetworkId(v.netId) and GetIdentifier() == v.data.owner
                end,
            },
            {
                icon = 'fa-solid fa-fire',
                label = locale('target.destroyPlant'),
                onSelect = function(data)
                    DestroyPlant(v)
                end,
                canInteract = function(entity, distance, data)
                    return entity == NetworkGetEntityFromNetworkId(v.netId) and HasJob() and GetIdentifier() ~= v.data.owner
                end,
            }
        })
    end
end

--########### SHOPS ###########--
if Config.shop and #Config.shop.locations > 0 then
    local Shops = {}
    local function OpenShop(data)
        local options = {}

        table.sort(data.items, function (a, b)
            return b.name > a.name
        end)

        for k,v in pairs(data.items) do
            options[#options+1] = {
                title = v.label,
                icon = Config.imagePath:format(v.name),
                image = Config.imagePath:format(v.name),
                description = locale('shopMenu.itemDesc'):format(v.price),
                onSelect = function ()
                    local input = lib.inputDialog(locale('shopMenu.amount'):format(v.label), {
                        {type = 'number', label = locale('shopMenu.enter'), icon = 'hashtag'},
                      })
 
                    if not input then return end

                    local confirm = lib.alertDialog({
                        header = locale('shopMenu.confirmation'),
                        content = locale('shopMenu.confirmMessage'):format(v.label, input[1], input[1]*v.price),
                        centered = true,
                        cancel = true
                    })

                    if confirm == 'confirm' then
                        local pData = {
                            item = v.name,
                            label = v.label,
                            amount = input[1],
                            price = input[1]*v.price
                        }
                        TriggerServerEvent('syniq_weed:purchaseItem', pData)
                    end
                end
            }
        end

        lib.registerContext({
            id = 'shopMenu',
            title = data.name,
            options = options
        })
    
        lib.showContext('shopMenu')
    end
    
    Citizen.CreateThread(function ()
        for k,v in pairs(Config.shop.locations) do
            if table.type(v.blip) ~= 'empty' then
                local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)

                SetBlipSprite (blip, v.blip.id)
                SetBlipDisplay(blip, v.blip.display)
                SetBlipScale  (blip, v.blip.scale)
                SetBlipColour (blip, v.blip.color)
                SetBlipAsShortRange(blip, true)
            
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(v.name)
                EndTextCommandSetBlipName(blip)
            end

            if not Config.useTarget then
                Shops[k] = lib.points.new({
                    coords = v.coords,
                    distance = 5.0,
                    nearby = function (point)
                        if point.isClosest and point.currentDistance < 2.5 then
                            if not textUI2 then
                                textUI2 = true
                                TextUI(locale('textUI.shop'))
                            end

                            if IsControlJustPressed(0, 38) then
                                OpenShop(v)
                            end
                        end
                    end,
                    onExit = function (point)
                        if textUI2 then
                            textUI2 = false
                            HideTextUI()
                        end
                    end
                })
            else
                AddBox(v.coords, 'shop'..k, {
                    {
                        icon = 'fa-solid fa-cart-shopping',
                        label = locale('target.openShop'),
                        onSelect = function(entity)
                            OpenShop(v)
                        end,
                    }
                })
            end
        end
    end)
end

RegisterNetEvent('syniq_weed:getClosestPlant', function ()
    local plant = GetClosestPlant(2.5)
    if not plant then Notification(locale('notify.error.title'), locale('notify.error.noPlantNearby'), 5000, 'error') return end

    lib.setClipboard(plant.data.id)
    Notification(locale('notify.success.title'), locale('notify.success.plantFound'), 5000, 'success')
end)

-- ###### FUNCTIONS ###### --

function GenerateId()
    local id = ""
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    while true do
        for i = 1, 6 do
            local rand = math.random(1, #charset)
            id = id .. charset:sub(rand, rand)
        end

        if not Plants['plant-'..id] then
            break
        end

        Wait(100)
    end

    return 'plant-' .. id
end

function HasJob()
    return Config.jobs[GetJob()] or false
end

function InPolyZone(entity)
    local eCoords = GetEntityCoords(entity)
    for k,v in pairs(Config.blacklistZones) do
        if #(eCoords - v.coords) < v.radius then
            return true
        end
    end

    return false
end

function CreateObj(hash, boneIndex, offset, rotation)
    local model = lib.requestModel(hash)
    if not model then return end

    local coords = GetEntityCoords(cache.ped)
    local object = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, false, false)
    local boneID = GetPedBoneIndex(cache.ped, boneIndex)
    FreezeEntityPosition(cache.ped, true)
    AttachEntityToEntity(object, cache.ped, boneID, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, true, 1, true)

    return object
end

function PlayEffect(dict, particleName, entity, off, rot, time, cb)
    CreateThread(function()
        local particle = lib.requestNamedPtfxAsset(dict)
        if not particle then return end
        
        UseParticleFxAssetNextCall(dict)
        local particleHandle = StartParticleFxLoopedOnEntity(particleName, entity, off.x, off.y, off.z, rot.x, rot.y, rot.z, 1.0)
        SetParticleFxLoopedColour(particleHandle, 0, 255, 0, 0)
        Wait(time)
        StopParticleFxLooped(particleHandle, false)
        if cb then cb() end
    end)
end


AddEventHandler('onResourceStop', function(name)
    if name == cache.resource then
        if textUI or textUI2 then
            HideTextUI()
        end
    end
end)
