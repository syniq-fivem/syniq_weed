if GetResourceState('qbx_core') ~= 'started' then return end

AddEventHandler('qbx_core:client:playerLoaded', function()
    PlayerData = exports.qbx_core:GetPlayerData()
    PlayerLoaded = true
	SetUp()
end)

RegisterNetEvent('qbx_core:client:playerUnloaded', function()
    table.wipe(PlayerData)
    PlayerLoaded = false
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resource)
    if cache.resource == resource then
        Wait(1500)
        PlayerData = exports.qbx_core:GetPlayerData()
        PlayerLoaded = true
        SetUp()
    end
end)

function GetIdentifier()
    return PlayerData?.citizenid
end

function GetJob()
    return PlayerData?.job?.name
end
