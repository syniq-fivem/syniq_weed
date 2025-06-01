if GetResourceState('ox_target') ~= 'started' or not Config.useTarget then return end

function AddEntity(netId, options)
    exports.ox_target:addEntity(netId, options)
end

function RemoveEntity(target, options)
    exports.ox_target:removeEntity(target, options)
end

function AddBox(coords, name, options)
    exports['ox_target']:addBoxZone({
        coords = coords,
        name = name,
        options = options
    })
end