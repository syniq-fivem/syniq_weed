if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerLoaded = true
	SetUp()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    table.wipe(PlayerData)
    PlayerLoaded = false
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resource)
    if cache.resource == resource then
        Wait(1500)
        PlayerData = QBCore.Functions.GetPlayerData()
        PlayerLoaded = true
        SetUp()
    end
end)

function GetIdentifier()
    return PlayerData.citizenid
end

function GetJob()
    return PlayerData.job.name
end