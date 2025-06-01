if GetResourceState('qb-target') ~= 'started' or not Config.useTarget then return end

function AddEntity(netId, options)
    local optionsNames = {}
    for i=1, #options do
        optionsNames[i] = options[i].name
        if options[i].onSelect then
            local cb = options[i].onSelect
            options[i].action = function(entity)
                cb({entity = entity})
            end
            options[i].onSelect = nil
        end
    end
    
    exports['qb-target']:AddTargetEntity(NetworkGetEntityFromNetworkId(netId), {options = options, distance = 2.5})
end

function RemoveEntity(target, options)
    exports['qb-target']:RemoveTargetEntity(target, options)
end

function AddBox(coords, name, options)
    local optionsNames = {}
    for i=1, #options do
        optionsNames[i] = options[i].name
        if options[i].onSelect then
            local cb = options[i].onSelect
            options[i].action = function(entity)
                cb({entity = entity})
            end
            options[i].onSelect = nil
        end
    end

    exports['qb-target']:AddBoxZone(name, vector3(coords.x, coords.y, coords.z), 1.5, 1.6, {
        name = name,
        heading = 0.0,
        debugPoly = false,
        minZ = coords.z - 2.0,
        maxZ = coords.z + 2.0,
    }, {
        options = options
    })
end