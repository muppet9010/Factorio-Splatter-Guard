local Utils = require("utility/utils")
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

---@param event on_tick
function TrainJumper.Manager(event)
    TrainJumper.PlayerManager()
    TrainJumper.ManageJumpedPlayers(event)
end

--- Checks if each online player needs a Preemptive jump away from a train.
function TrainJumper.PlayerManager()
    for _, player in pairs(game.connected_players) do
        if player.character == nil then
            -- Player doesn't have a character so never needs to jump.
            return
        end
        if player.vehicle ~= nil then
            -- Player in vehicle so never needs to jump.
            return
        end

        -- Check if the player is not near a track or train.
        local player_surface, player_position = player.surface, player.position
        local railsNearPlayer =
            player_surface.count_entities_filtered {
            area = Utils.CalculateBoundingBoxFromPositionAndRange(player_position, global.Mod.State.playerSafeBox),
            type = {"straight-rail", "curved-rail"},
            limit = 1
        }
        if railsNearPlayer == 0 then
            return
        end
        if not Train.IsATrainNearPlayer(player_surface, player_position) then
            return
        end

        -- Check if a jetpack is in use by the player.
        if game.active_mods["jetpack"] ~= nil then
            local jetpacks = remote.call("jetpack", "get_jetpacks", {surface_index = player.surface.index})
            if jetpacks ~= nil then
                for _, jetpack in pairs(jetpacks) do
                    if jetpack.player_index == player.index then
                        return
                    end
                end
            end
        end

        -- Player needs to jump to safety.
        TrainJumper.JumpPlayerToFreeSpot(player)
    end
end

function TrainJumper.JumpPlayerToFreeSpot(player)
    local oldPosition = player.position
    local newPosition = TrainJumper.FindNewPlayerPosition(player.surface, player.position, 1, nil, player.character.name)
    if not player.teleport(newPosition, player.surface) then
        game.print("ERROR - failed to jump player '" .. player.name .. "' to position(" .. newPosition.x .. ", " .. newPosition.y .. ")")
    end
    player.surface.create_entity {name = "teleported-smoke", position = oldPosition}
    global.Mod.State.playersJumpedDict[player.index] = game.tick + 60
end

function TrainJumper.FindNewPlayerPosition(surface, startingPosition, searchRange, positionsCheckedDict, characterEntityName)
    if positionsCheckedDict == nil then
        positionsCheckedDict = {}
    end
    local validPositionsArr = {}
    for x = startingPosition.x - searchRange, startingPosition.x + searchRange, 0.1 do
        for y = startingPosition.y - searchRange, startingPosition.y + searchRange, 0.1 do
            if positionsCheckedDict[{x, y}] == nil then
                positionsCheckedDict[{x, y}] = "done"
                local positionToCheck = {x = x, y = y}
                if TrainJumper.CheckJumpPosition(surface, positionToCheck, characterEntityName) then
                    table.insert(validPositionsArr, positionToCheck)
                end
            end
        end
    end
    if #validPositionsArr > 0 then
        return validPositionsArr[math.random(#validPositionsArr)]
    else
        return TrainJumper.FindNewPlayerPosition(surface, startingPosition, searchRange * 2, positionsCheckedDict, characterEntityName)
    end
end

function TrainJumper.CheckJumpPosition(surface, position, characterEntityName)
    if surface.count_entities_filtered {area = Utils.CalculateBoundingBoxFromPositionAndRange(position, global.Mod.State.playerSafeBox)} > 0 then
        return false
    end
    if not surface.can_place_entity {name = characterEntityName, position = position} then
        return false
    end
    return true
end

---@param event on_tick
function TrainJumper.ManageJumpedPlayers(event)
    for playerIndex, endTick in pairs(global.Mod.State.playersJumpedDict) do
        if endTick >= event.tick then
            local player = game.get_player(playerIndex)
            if player ~= nil then
                -- Stop any movement by the player.
                player.walking_state = {walking = false, direction = 1}
            else
                -- Players disconnected.
                table.remove(global.Mod.State.playersJumpedDict, playerIndex)
            end
        else
            table.remove(global.Mod.State.playersJumpedDict, playerIndex)
        end
    end
end

function TrainJumper.SetTrainAvoidEvents()
    --Catch OnLoad being called before ModChanged on mod upgrade and skip it this time
    if global.Mod == nil or global.Mod.Settings == nil or global.Mod.Settings.trainAvoidMode == nil then
        return
    end
    if global.Mod.Settings.trainAvoidMode == "Preemptive" then
        script.on_event(defines.events.on_tick, TrainJumper.Manager)
        script.on_event(defines.events.on_entity_damaged, TrainJumper.EntityDamaged, {{filter = "type", type = "character"}})
    elseif global.Mod.Settings.trainAvoidMode == "Reactive Only" then
        script.on_event(defines.events.on_tick, TrainJumper.ManageJumpedPlayers)
        script.on_event(defines.events.on_entity_damaged, TrainJumper.EntityDamaged, {{filter = "type", type = "character"}})
    else
        script.on_event(defines.events.on_tick, nil)
        script.on_event(defines.events.on_entity_damaged, nil)
    end
end

---@param event on_entity_damaged
function TrainJumper.EntityDamaged(event)
    local entity = event.entity
    if event.cause == nil or Train.TrainEntityTypes[event.cause.type] == nil then
        return
    end
    local entity_player = entity.player
    if entity_player == nil then
        -- The jump logic expects a player, so ignore random "character" entities. Also means mods that use character entiteis won't be affected by this mod.
        return
    end
    entity.health = entity.health + event.final_damage_amount
    TrainJumper.JumpPlayerToFreeSpot(entity_player)
end

return TrainJumper
