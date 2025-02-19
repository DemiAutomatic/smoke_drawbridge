local sharedConfig = require 'config.shared'

local bridgeData = { speedZones = {} }

function math.round(n)
    return math.floor(n + 0.5)
end

local function rotateGate(entity, initialRotation, targetRotation)
    local startY = math.round(initialRotation.y)
    local endY = math.round(targetRotation.y)
    local step = initialRotation.y < targetRotation.y and 1 or -1
    for currentY = startY, endY, step do
        SetEntityRotation(entity, initialRotation.x, currentY, initialRotation.z, 1, true)
        Wait(10)
    end
end

local function updateBarrierGateRotation(isOpen)
    CreateThread(function()
        for _, gate in ipairs(sharedConfig.barrierGates) do
            local entity = GetClosestObjectOfType(gate.coords.x, gate.coords.y, gate.coords.z, 2.0,
                gate.model, false, false, false)
            if entity then
                local currentRotation = GetEntityRotation(entity)
                if #(currentRotation - gate.normalRot) >= 1 then
                    SetEntityRotation(entity, gate.normalRot.x, gate.normalRot.y, gate.normalRot.z, 1, true)
                end
                local targetRotationY = isOpen and gate.maxRotationY or gate.minRotationY
                local targetRotation = vector3(currentRotation.x, currentRotation.y + targetRotationY, currentRotation.z)
                rotateGate(entity, currentRotation, targetRotation)
            end
        end
    end)
end

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("bridgesOpen", nil, function(_, _, isBridgeOpen)
    for id, blockingData in ipairs(sharedConfig.blockArea) do
        if isBridgeOpen then
            bridgeData.speedZones[id] = AddRoadNodeSpeedZone(
                blockingData.coords.x,
                blockingData.coords.y,
                blockingData.coords.z,
                blockingData.size,
                0.0, false)
        else
            if bridgeData.speedZones[id] then
                RemoveRoadNodeSpeedZone(bridgeData.speedZones[id])
                bridgeData.speedZones[id] = nil
            end
        end
    end
    updateBarrierGateRotation(isBridgeOpen)
end)

---Minigame check
---@return boolean
local function minigameCheck()
    return true
end

CreateThread(function()
    if not sharedConfig.HackBridge.enabled then return end
    exports.ox_target:addBoxZone({
        coords = sharedConfig.HackBridge.coords,
        size = sharedConfig.HackBridge.size,
        rotation = sharedConfig.HackBridge.rotation,
        options = {
            label = 'Hack Bridge Control',
            icon = 'fas fa-code-branch',
            distance = 2.5,
            canInteract = function()
                return not GlobalState.bridgesOpen
            end,
            onSelect = function()
                if minigameCheck() then
                    TriggerServerEvent('smoke_drawbridge:server:hackBridge')
                end
            end
        }
    })

end)
