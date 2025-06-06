Config = {
    locales = 'en',
    
    items = {
        pot = 'pot',
        shovel = 'shovel',
        fertilizer = 'fertilizer',
        water = 'distilledwater',
        spray = 'herbicide',
        canister = 'canister',
    },
    imagePath = 'nui://your_inventory/html/images/%s.png',
    jobs = {
        ['police'] = true,
    },
    maxPlants = 5,
    useTarget = false,

    commands = {
        ['getId'] = {
            enable = true,
            command = 'getid',
            help = 'Get ID of closest plant',
            permission = 'group.admin',
        },
        ['tpPlant'] = {
            enable = true,
            command = 'tpplant',
            help = 'Teleport to plant',
            permission = 'group.admin',
            params = {
                {
                    name = 'id',
                    type = 'string',
                    help = 'Plant id'
                }
            }
        },
        ['deletePlant'] = {
            enable = true,
            command = 'deleteplant',
            help = 'Delete plant',
            permission = 'group.admin',
            params = {
                {
                    name = 'id',
                    type = 'string',
                    help = 'Plant id'
                }
            }
        },
    },

    seeds = {
        ['weed_seed'] = {
            item = 'weed_leaf', -- item name ( reward item when you harvest tree )
            label = 'Weed', -- label that will be displayed in info menu
            reward = { min = 2, max = 10 }, -- dependence on health of plant
            stages = {
                [1] = { prop = `bkr_prop_weed_01_small_01c`, percent = 15 },
                [2] = { prop = `bkr_prop_weed_med_01a`, percent = 40 },
                [3] = { prop = `bkr_prop_weed_lrg_01a`, percent = 70 }
            },
        },
    },

    blacklistZones = { -- zones where player can't place a plant pot
        { coords = vector3(430.077, -1012.518, 30.705), radius = 50.0 }
    },

    shop = { -- shop where player can purchase items for weed
        locations = {
            {
                coords = vec3(-943.0979, -1075.4811, 2.7453),
                name = 'Weed Shop',
                blip = { -- if u want to disable blip put {}
                    id = 496,
                    color = 2,
                    scale = 1.0,
                    display = 4
                },
                items = {
                    { label = 'Canister', name = 'canister', price = 40 },
                    { label = 'Distilled water', name = 'distilledwater', price = 20 },
                    { label = 'Fertilizer', name = 'fertilizer', price = 50 },
                    { label = 'Herbicide', name = 'herbicide', price = 30 },
                    { label = 'Pot', name = 'pot', price = 10 },
                    { label = 'Shovel', name = 'shovel', price = 25 },           
                    { label = 'Weed Seed', name = 'weed_seed', price = 15 },
                },
            }
        }
    },

    growth = { -- update growth of plant
        update = 30000, -- Time for which the interval will be updated ( 30s = 30000ms )

        reduceFertilizer = 1.5, -- The amount of fertilizer a plant will lose every 30 seconds ( update = 30000)
        reduceWater = 1.5, -- The amount of water a plant will lose every 30 seconds ( update = 30000)
        reduceHealth = 1.0, -- The amount of health a plant will lose every 30 seconds ( update = 30000)
        receiveGrowth = 2.0, -- The percentage that a plant will grow in 30 seconds ( update = 30000)

        giveFertilizer = 10.0, -- % that the plant will gain when fed
        giveWater = 10.0, -- % that the plant will gain when you water it
        giveHealth = 10.0, -- % that the plant will receive when sprayed
    },
}
