local sharedConfig = require 'config.shared'
local math = lib.math
local bridgeEntities = {}
local speedZones = {}
local bridgeStates = {}

local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local DoesEntityExist = DoesEntityExist
local IsControlJustPressed = IsControlJustPressed
local SetEntityRotation = SetEntityRotation
local GetEntityRotation = GetEntityRotation

local function toggleBarriers(state)
    for i = 1, #sharedConfig.barrierGates do
        CreateThread(function()
            local barrier = sharedConfig.barrierGates[i]
            local entity = GetClosestObjectOfType(barrier.coords.x, barrier.coords.y, barrier.coords.z, 2.0, barrier.model, false, false, false)
            if entity ~= 0 then
                local current = GetEntityRotation(entity)
                local target = (state and barrier.open) or barrier.closed

                for interpolated in lib.math.lerp(current, target, 3000) do
                    SetEntityRotation(entity, interpolated.x, interpolated.y, interpolated.z, 1, true)
                end
            end
        end)
    end
end

local function toggleBlockAreas(index, state)
    if state then
        
        local blockAreas = sharedConfig.bridges[index].blockAreas
        if not blockAreas then return end

        speedZones[index] = speedZones[index] or {}
        for i = 1, #blockAreas do
            if not speedZones[index][i] then
                local data = blockAreas[i]
                speedZones[index][i] = AddRoadNodeSpeedZone(data.coords.x, data.coords.y, data.coords.z, data.size, 0.0, false)
            end
        end
    else
        if speedZones[index] then
            for i = #speedZones[index], 1, -1 do
                local zone = table.remove(speedZones[index], i)
                RemoveRoadNodeSpeedZone(zone)
            end
        end
    end
end

local function calculateTravelTime(currentCoords, targetCoords, index)
    print('caclulate time needed for bridge move', index)

    local bridge = sharedConfig.bridges[index]
    local totalTime = bridge.movementDuration
    local currentDistance = #(currentCoords - targetCoords)

    print('totalTime', totalTime)
    print('currentDistance', currentDistance)

    local totalDistance = #(bridge.normalState - bridge.openState)


    print('totalDistance', totalDistance)


    local mod = (totalDistance - currentDistance) / totalDistance
    print('mod', mod)

    print('result', math.floor(totalTime * mod))

    return totalTime - math.floor(totalTime * mod)
end

local function openBridge(index)
    local bridge = sharedConfig.bridges[index]
    local entity = bridgeEntities[index]

    if not DoesEntityExist(entity) then
        return
    end

    bridgeStates[index] = true

    local currentCoords = GetEntityCoords(entity)
    local timeNeeded = calculateTravelTime(currentCoords, bridge.openState, index)

    lib.print.info('time needed', timeNeeded)

    toggleBarriers(true)
    toggleBlockAreas(index, true)

    for interpolated in lib.math.lerp(GetEntityCoords(entity), bridge.openState, timeNeeded) do
        SetEntityCoordsNoOffset(entity, interpolated.x, interpolated.y, interpolated.z, false, false, false)
    end

    bridgeStates[index] = false
end

local function closeBridge(index)
    local bridge = sharedConfig.bridges[index]
    local entity = bridgeEntities[index]

    if not DoesEntityExist(entity) then return end

    local currentCoords = GetEntityCoords(entity)
    local timeNeeded = calculateTravelTime(currentCoords, bridge.normalState, index)

    bridgeStates[index] = true

    for interpolated in lib.math.lerp(currentCoords, bridge.normalState, timeNeeded) do
        SetEntityCoordsNoOffset(entity, interpolated.x, interpolated.y, interpolated.z, false, false, false)
    end

    toggleBarriers(false)
    toggleBlockAreas(index, false)
    bridgeStates[index] = false
end

local function spawnBridge(index)
    local bridge = sharedConfig.bridges[index]
    local model = bridge.hash
    lib.requestModel(model)
    local pos = GlobalState['bridges:coords:' .. index]
    local ent = CreateObjectNoOffset(model, pos.x, pos.y, pos.z, false, false, false)
    SetEntityLodDist(ent, 3000)
    FreezeEntityPosition(ent, true)
    bridgeEntities[index] = ent

    if GlobalState['bridges:state:' .. index] then
        openBridge(index)
    else
        closeBridge(index)
    end
end

local function destroyBridge(index)
    if DoesEntityExist(bridgeEntities[index]) then
        DeleteEntity(bridgeEntities[index])
    end
    toggleBarriers(false)
    toggleBlockAreas(index, false)
    bridgeEntities[index] = nil
    bridgeStates[index] = false
end

CreateThread(function()
    for i = 1, #sharedConfig.bridges do
        local coords = sharedConfig.bridges[i].normalState

        local point = lib.points.new({
            coords = coords,
            distance = 400,
        })

        function point:onEnter()
            spawnBridge(i)
        end

        function point:onExit()
            destroyBridge(i)
        end
    end
end)

CreateThread(function()
    for index = 1, #sharedConfig.bridges do
        AddStateBagChangeHandler('bridges:state:' .. index, nil, function(_, _, state)
            if not bridgeStates[index] then
                if state then
                    openBridge(index)
                else
                    closeBridge(index)
                end
            end
        end)
    end
end)

local function createInteraction()
    local state = GetResourceState('ox_target')
    local oxTarget = state == 'started' or state == 'starting'
    local config = sharedConfig.HackBridge
    if oxTarget then
        exports.ox_target:addBoxZone({
            coords = config.coords,
            size = config.size,
            rotation = config.rotation,
            options = {
                label = 'Hack Bridge Control',
                icon = 'fas fa-code-branch',
                distance = 2.5,
                canInteract = function()
                    return not GlobalState.pBrMeta.state
                end,
                onSelect = function()
                    if GlobalState.pBrCooldown then
                        lib.notify({
                            title = 'Port Bridge',
                            description = 'The bridge is currently on cooldown',
                            type = 'error'
                        })
                        return
                    end
                    if config.minigame() then
                        TriggerServerEvent('smoke_drawbridge:server:hackBridge')
                    end
                end
            }
        })
    else
        local interact = lib.points.new({
            coords = config.coords,
            distance = 1.5,
        })

        function interact:nearby()
            print('Nearby')
            lib.showTextUI('[E] - Hack Module')
            if IsControlJustPressed(0, 38) then
                if GlobalState.pBrCooldown then
                    lib.notify({
                        title = 'Port Bridge',
                        description = 'The bridge is currently on cooldown',
                        type = 'error'
                    })
                    return
                end
                if config.minigame() then
                    TriggerServerEvent('smoke_drawbridge:server:hackBridge')
                end
            end
        end

        function interact:onExit()
            lib.hideTextUI()
        end
    end
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(0) end
    Wait(5000) -- Wait for slow PCs
    if sharedConfig.HackBridge.enabled then
        createInteraction()
    end
end)
