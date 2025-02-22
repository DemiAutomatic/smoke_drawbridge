local sharedConfig = require 'config.shared'
local config = require 'config.server'
local math = lib.math
local bridgeTimers = {}

CreateThread(function()
    for i = 1, #sharedConfig.bridges do
        GlobalState['bridges:state:' .. i] = false
        GlobalState['bridges:coords:' .. i] = sharedConfig.bridges[i].normalState
    end
end)

local function calculateTravelTime(currentCoords, targetCoords, index)
    local bridge = sharedConfig.bridges[index]
    local totalTime = bridge.movementDuration
    local currentDistance = #(currentCoords - targetCoords)
    local totalDistance = #(bridge.normalState - bridge.openState)
    local mod = (totalDistance - currentDistance) / totalDistance

    return totalTime - math.floor(totalTime * mod)
end

local function toggleBridge(state, index)

    print('toggle bridge', index)

    CreateThread(function()
        local bridge = sharedConfig.bridges[index]
        local from = state and bridge.normalState or bridge.openState
        local to = state and bridge.openState or bridge.normalState
        local duration = calculateTravelTime(from, to, index)

        if bridgeTimers[index] then
            bridgeTimers[index]:forceEnd(false)
        end

        GlobalState['bridges:state:' .. index] = state

        CreateThread(function()
            for interp in math.lerp(from, to, duration) do
                GlobalState['bridges:coords:' .. index] = interp
            end

            bridgeTimers[index] = lib.timer(config.bridgeSettings.timeout, function()
                toggleBridge(false, index)
                bridgeTimers[index] = nil
            end, true)
        end)
    end)
end

-- ---@diagnostic disable-next-line: undefined-global
-- SetInterval(function()
--     if math.random(1, 100) <= config.bridgeSettings.chance then
--         for index = 1, #sharedConfig.bridges do
--             toggleBridge(true, index)
--         end
--     end
-- end, config.bridgeSettings.interval)

RegisterNetEvent('smoke_drawbridge:server:hackBridge', function()
    local coords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(coords - sharedConfig.HackBridge.coords)
    if distance > 3 then return end
    for index = 1, #sharedConfig.bridges do
        toggleBridge(true, index)
    end
end)

if config.enableCommands then
    lib.addCommand('portbridges', {
        help = 'Open or view status of bridge',
        params = {
            {
                name = 'state',
                type = 'string',
                help = 'open / status',
            }
        },
        restricted = 'group.admin'
    }, function(source, args)
        if args.state == 'open' then
            for index = 1, #sharedConfig.bridges do
                toggleBridge(true, index)
            end
        elseif args.state == 'close' then
            for index = 1, #sharedConfig.bridges do
                toggleBridge(false, index)
            end
        elseif args.state == 'status' then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Smoke Bridge',
                description = 'The bridge is currently ' .. (GlobalState.pBrMeta.state and 'open' or 'closed'),
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Smoke Bridge',
                description = 'Invalid state',
                type = 'error'
            })
        end
    end)
end

lib.versionCheck('BigSmoKe07/smoke_drawbridge')
-- Exports
exports('openPortBridges', openBridges)
