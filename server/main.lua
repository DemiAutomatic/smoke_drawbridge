local sharedConfig = require 'config.shared'
local config = require 'config.server'

local bridgeEntities = {}

local function lerpVec(a, b, t)
    return vec3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

local function moveEntity(entity, initialPosition, targetPosition, duration)
    CreateThread(function()
        local startTime = GetGameTimer()
        while true do
            local elapsedTime = GetGameTimer() - startTime
            local t = math.clamp(elapsedTime / duration, 0.0, 1.0)
            local currentPosition = lerpVec(initialPosition, targetPosition, t)
            SetEntityCoords(entity, currentPosition.x, currentPosition.y, currentPosition.z, true, true, true, false)
            if t >= 1.0 then break end
            Wait(0)
        end
    end)
end

--- Toggles the state of drawbridges.
--- @param isOpening boolean If true, the bridges open; otherwise, they return to their normal state.
--- @param duration number The time (in seconds) it takes for each bridge to transition from one state to another.
local function toggleBridges(isOpening, duration)
    for _, bridge in ipairs(bridgeEntities) do
        local fromState = isOpening and bridge.normalState or bridge.openState
        local toState = isOpening and bridge.openState or bridge.normalState
        moveEntity(bridge.ent, fromState, toState, duration)
    end
end

--- Opens the drawbridges if they are currently closed.
local function openBridges()
    if GlobalState.bridgesOpen then return end
    GlobalState.bridgesOpen = true
    toggleBridges(true, config.bridgeSettings.movementDuration)
    SetTimeout(config.bridgeSettings.movementDuration + config.bridgeSettings.timeout, function()
        toggleBridges(false, config.bridgeSettings.movementDuration)
        Wait(config.bridgeSettings.movementDuration)
        GlobalState.bridgesOpen = false
    end)
end
exports('openBridges', openBridges)



lib.callback.register('smoke_drawbridge:requestBridgeIds', function()
    local bridgeIds = {}
    for _, bridge in ipairs(bridgeEntities) do
        bridgeIds[#bridgeIds + 1] = bridge.netId
    end
    return bridgeIds
end)

RegisterNetEvent('smoke_drawbridge:server:hackBridge', function()
    if GlobalState.bridgesOpen then return end
    local coords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(coords - sharedConfig.HackBridge.coords)
    if not distance <= 2.5 then return end
    openBridges()
end)

CreateThread(function()
    Wait(5000) -- Make sure streams are loaded
    for id, bridge in ipairs(sharedConfig.bridges) do
        local ent = CreateObjectNoOffset(bridge.hash, bridge.normalState.x, bridge.normalState.y,
            bridge.normalState.z, false, false, false)
        FreezeEntityPosition(ent, true)
        local netId = NetworkGetNetworkIdFromEntity(ent)
        bridgeEntities[id] = {
            ent = ent,
            netId = netId,
            normalState = bridge.normalState,
            openState = bridge.openState
        }
    end
    GlobalState.bridgesOpen = false
end)

if config.enableCommands then
    RegisterCommand('drawbridges', function()
        openBridges()
    end, true)
end

---@diagnostic disable-next-line: undefined-global
SetInterval(function()
    if not GlobalState.bridgesOpen and math.random(1, 100) <= config.bridgeSettings.chance then
        openBridges()
    end
end, config.bridgeSettings.interval)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, bridge in ipairs(bridgeEntities) do
            DeleteEntity(bridge.ent)
        end
    end
end)
