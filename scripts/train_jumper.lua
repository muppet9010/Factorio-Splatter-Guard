local Utils = require("utility/utils")
local Logging = require("utility/logging")
local Track = require("track")
local Train = require("train")
local TrainJumper = {}

function TrainJumper.PopulateStateDefaults()
    local state = global.Mod.State
    if state.playersJumpedDict == nil then
        state.playersJumpedDict = {}
    end
    state.playerSafeBox = 0.5
    state.trainSearchSize = 3
    state.trainTrackSearchSize = 0.75
end

function TrainJumper.Manager()
    for i, player in pairs(game.connected_players) do
        TrainJumper.PlayerManager(player)
    end
    TrainJumper.JumpedPlayersManager()
end

function TrainJumper.JumpedPlayersManager()
    for playerIndex, endTick in pairs(global.Mod.State.playersJumpedDict) do
        if endTick >= game.tick then
            local player = game.get_player(playerIndex)
            if player ~= nil then
                player.walking_state = {walking = false, direction = 1}
            else
                table.remove(global.Mod.State.playersJumpedDict, playerIndex)
            end
        else
            table.remove(global.Mod.State.playersJumpedDict, playerIndex)
        end
    end
end

function TrainJumper.PlayerManager(player)
    local Log = false
    Logging.Log(player.name .. " PlayerManager", Log)
    if player.character == nil then
        Logging.Log("no character", Log)
        return
    end
    if player.vehicle ~= nil then
        Logging.Log("in vehicle", Log)
        return
    end
    if not Track.IsTrackNearPosition(player.surface, player.position, global.Mod.State.playerSafeBox) then
        Logging.Log("not near track", Log)
        return
    end
    if not Train.IsATrainNearPlayer(player) then
        Logging.Log("not near train", Log)
        return
    end
    Logging.Log("going to jump", Log)
    TrainJumper.JumpPlayerToFreeSpot(player)
end

function TrainJumper.JumpPlayerToFreeSpot(player)
    local oldPosition = player.position
    local newPosition = TrainJumper.FindNewPlayerPosition(player.surface, player.position, 1)
    if not player.teleport(newPosition, player.surface) then
        game.print("ERROR - failed to jump player '" .. player.name .. "' to position(" .. newPosition.x .. ", " .. newPosition.y .. ")")
    end
    player.surface.create_entity {name = "teleported-smoke", position = oldPosition}
    global.Mod.State.playersJumpedDict[player.index] = game.tick + 60
end

function TrainJumper.FindNewPlayerPosition(surface, startingPosition, searchRange, positionsCheckedDict)
    if positionsCheckedDict == nil then
        positionsCheckedDict = {}
    end
    local validPositionsArr = {}
    for x = startingPosition.x - searchRange, startingPosition.x + searchRange, 0.1 do
        for y = startingPosition.y - searchRange, startingPosition.y + searchRange, 0.1 do
            if positionsCheckedDict[{x, y}] == nil then
                positionsCheckedDict[{x, y}] = "done"
                local positionToCheck = {x = x, y = y}
                if TrainJumper.CheckJumpPosition(surface, positionToCheck) then
                    table.insert(validPositionsArr, positionToCheck)
                end
            end
        end
    end
    if #validPositionsArr > 0 then
        return validPositionsArr[math.random(#validPositionsArr)]
    else
        return TrainJumper.FindNewPlayerPosition(surface, startingPosition, searchRange * 2, positionsCheckedDict)
    end
end

function TrainJumper.CheckJumpPosition(surface, position)
    if
        surface.count_entities_filtered {
            area = Utils.CalculateBoundingBoxFromPositionAndRange(position, global.Mod.State.playerSafeBox)
        } > 0
     then
        return false
    end
    if
        not surface.can_place_entity {
            name = "character",
            position = position
        }
     then
        return false
    end
    return true
end

function TrainJumper.SetTrainAvoidEvents()
    --Catch OnLoad being called before ModChanged on mod upgrade and skip it this time
    if global.Mod == nil or global.Mod.Settings == nil or global.Mod.Settings.trainAvoidMode == nil then
        return
    end
    if global.Mod.Settings.trainAvoidMode == "Preemtive" then
        script.on_event(defines.events.on_tick, TrainJumper.Manager)
        script.on_event(defines.events.on_entity_damaged, TrainJumper.EntityDamaged)
    elseif global.Mod.Settings.trainAvoidMode == "Reactive Only" then
        script.on_event(defines.events.on_tick, TrainJumper.JumpedPlayersManager)
        script.on_event(defines.events.on_entity_damaged, TrainJumper.EntityDamaged)
    else
        script.on_event(defines.events.on_tick, nil)
        script.on_event(defines.events.on_entity_damaged, nil)
    end
end

function TrainJumper.EntityDamaged(event)
    local debugLogging = false
    local entity = event.entity
    Logging.Log(entity.name .. " EntityDamaged", debugLogging)
    if entity.type ~= "character" then
        Logging.Log("entity not character", debugLogging)
        return
    end
    if entity.player == nil then
        Logging.Log("entity has no player", debugLogging)
        return
    end
    if not Train.IsEntityATrainType(event.cause) then
        Logging.Log("cause not train", debugLogging)
        return
    end
    Logging.Log("final_damage_amount: " .. event.final_damage_amount, debugLogging)
    Logging.Log("starting entity health: " .. entity.health, debugLogging)
    entity.health = entity.health + event.final_damage_amount
    Logging.Log("returned entity to health: " .. entity.health, debugLogging)
    Logging.Log("going to jump", debugLogging)
    TrainJumper.JumpPlayerToFreeSpot(entity.player)
end

return TrainJumper
