if GetResourceState('qbx_core') ~= 'started' then return end

function GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

function GetPlayerSource(Player)
    return Player.PlayerData.source
end

function GetPlayerId(Player)
    return Player.PlayerData.citizenid
end

function CreateUsableItem(itemName, cb)
    exports.qbx_core:CreateUseableItem(itemName, function(source, item)
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player.Functions.GetItemByName(itemName) then return end
        
        return cb(source)
    end)
end

function RemoveItem(Player, itemName, amount)
    return Player.Functions.RemoveItem(itemName, amount)
end

function AddItem(Player, itemName, amount)
    return Player.Functions.AddItem(itemName, amount)
end

function HasItem(Player, itemName, amount)
    local item = Player.Functions.GetItemByName(itemName)

    if item then
        return item.amount >= amount
    end

    return false
end

function GetItemCount(Player, itemName)
    local item = Player.Functions.GetItemByName(itemName)

    if item then
        return item.amount
    end

    return 0
end

function HasMoney(Player, amount)
    return Player.Functions.GetMoney('cash') >= amount
end

function RemoveMoney(Player, amount)
    return Player.Functions.RemoveMoney('cash', amount)
end
