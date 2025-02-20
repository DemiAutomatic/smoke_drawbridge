local minutes = 60 * 1000

return {
    bridgeSettings = {
        movementDuration = 10 * minutes, -- Duration for bridge movement
        timeout = 1 * minutes,          -- Time to wait before automatically closing the bridge
        interval = 60 * minutes,           -- Open bridge every x minutes
        chance = 20,                      -- Chance to open the bridge every interval (100)
        cooldown = 20 * minutes,           -- Cooldown for opening the bridge   
    },
    enableCommands = true,               --  /drawbridges
}
