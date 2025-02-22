return {
    bridges = {
        {
            hash = `car_drawbridge`,
            normalState = vec3(353.3317, -2315.838, 13.75),
            openState = vec3(353.3317, -2315.838, 42.00),
            movementDuration = 1000,
            blockAreas = {
                {
                    coords = vec3(347.7381, -2273.5859, 10.1941), -- 353.3167, -2316.1406, 10.2630,
                    size = 10.0,
                },
                {
                    coords = vec3(358.786, -2352.276, 10.186),
                    size = 10.0,
                }
            },
        },
        {
            hash = `train_drawbridge`,
            normalState = vec3(219.5085, -2319.432, 13.25),
            openState = vec3(219.5085, -2319.432, 42.00),
            movementDuration = 1000,
        }
    },
    --- Enables players to hack the bridge
    --- You can chance the minigame in client/main.lua
    HackBridge = {
        enabled = true,
        coords = vec3(366.11, -2346.96, 10.5),
        size = vec3(0.5, 0.75, 2.0),
        rotation = 0.0,
        model = `prop_elecbox_01a`,
        cooldown = 60 * 60000, -- 60 minutes
        minigame = function ()
            return true
        end
    },
    barrierGates = {
        {
            model = `prop_bridge_barrier_gate_01x`,
            coords = vec3(364.69, -2343.68, 11.39),
            closed = vec3(0.0, 0.0, 0.0),
            open =  vec3(0.0, -90.0, 0.0),
        },
        {
            model = `prop_bridge_barrier_gate_01x`,
            coords = vec3(342.04, -2343.55, 11.46),
            closed = vec3(0.0, 0.0, 180.0),
            open =  vec3(0.0, 90.0, 0.0),
        },

        {
            model = `prop_bridge_barrier_gate_01x`,
            coords = vec3(364.71, -2288.3, 11.36),
            closed = vec3(0.0, 0.0, 0.0),
            open =  vec3(0.0, -90.0, 0.0),
        },
        {
            model = `prop_bridge_barrier_gate_01x`,
            coords = vec3(342.11, -2288.01, 11.30),
            closed = vec3(0.0, 0.0, 180.0),
            open =  vec3(0.0, 90.0, 0.0),
        }
    }
}
