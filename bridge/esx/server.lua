if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports.es_extended:getSharedObject()

function GetPlayer(source)
    return ESX.GetPlayerFromId(source)
end

function GetPlayerSource(Player)
    return Player.source
end

function GetPlayerId(Player)
    return Player.identifier
end

function CreateUsableItem(itemName, cb)
    ESX.RegisterUsableItem(itemName, function(source)
        local Player = ESX.GetPlayerFromId(source)
        if not Player.getInventoryItem(itemName) then return end
        
        return cb(source)
    end)
end

function RemoveItem(Player, itemName, amount)
    return Player.removeInventoryItem(itemName, amount)
end

function AddItem(Player, itemName, amount)
    return Player.addInventoryItem(itemName, amount)
end

function HasItem(Player, itemName, amount)
    local item = Player.getInventoryItem(itemName)

    if item then
        return item.count >= amount
    end

    return false
end

function GetItemCount(Player, itemName)
    local item = Player.getInventoryItem(itemName)

    if item then
        return item.count
    end

    return 0
end

function HasMoney(Player, amount)
    return Player.getMoney() >= amount
end

function RemoveMoney(Player, amount)
    return Player.removeMoney(amount)
end