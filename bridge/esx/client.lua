if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports.es_extended:getSharedObject()

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	PlayerLoaded = true
    SetUp()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    table.wipe(PlayerData)
    PlayerLoaded = false
end)

AddEventHandler('onResourceStart', function(resource)
    if cache.resource == resource then
        Wait(1500)
        PlayerData = ESX.GetPlayerData()
        PlayerLoaded = true
        SetUp()
    end
end)

function GetIdentifier()
    return PlayerData.identifier
end

function GetJob()
    return PlayerData.job.name
end