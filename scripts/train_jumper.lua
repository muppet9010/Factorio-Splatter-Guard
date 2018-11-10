TrainJumper = {}

TrainJumper.playersJumpedDict = {}
TrainJumper.playerSafeBox = 0.5
TrainJumper.trainSearchSize = 3
TrainJumper.trainTrackSearchSize = 0.75

TrainJumper.Manager = function()
    for i, player in pairs(game.connected_players) do
       TrainJumper.PlayerManager(player)
    end
    TrainJumper.JumpedPlayersManager()
end

TrainJumper.JumpedPlayersManager = function()
    for playerIndex, endTick in pairs(TrainJumper.playersJumpedDict) do
        if endTick >= game.tick then
            if game.players[playerIndex] ~= nil then
                game.players[playerIndex].walking_state = {false}
            else
                table.remove(TrainJumper.playersJumpedDict, playerIndex)
            end
        else
            table.remove(TrainJumper.playersJumpedDict, playerIndex)
        end
    end
end

TrainJumper.PlayerManager = function(player)
	Utility.DebugLogging("PlayerManager", player.name .. " PlayerManager")
    if player.character == nil then
		Utility.DebugLogging("PlayerManager", "no character")
		return
	end
    if player.vehicle ~= nil then
		Utility.DebugLogging("PlayerManager", "in vehicle")
		return
	end
    if not Track.IsTrackNearPosition(player.surface, player.position, TrainJumper.playerSafeBox) then
		Utility.DebugLogging("PlayerManager", "not near track")
        return
	end
    if not Train.IsATrainNearPlayer(player) then
		Utility.DebugLogging("PlayerManager", "not near train")
        return
    end
	Utility.DebugLogging("PlayerManager", "going to jump")
    TrainJumper.JumpPlayerToFreeSpot(player)
end

TrainJumper.JumpPlayerToFreeSpot = function(player)
	local oldPosition = player.position
    local newPosition = TrainJumper.FindNewPlayerPosition(player.surface, player.position, 1)
    if not player.teleport(newPosition, player.surface) then
        game.print("ERROR - failed to jump player '" .. player.name .. "' to position(" .. newPosition.x .. ", " .. newPosition.y .. ")")
    end
	player.surface.create_entity{ name = "teleported-smoke", position = oldPosition}
    TrainJumper.playersJumpedDict[player.index] = game.tick + 60
end

TrainJumper.FindNewPlayerPosition = function(surface, startingPosition, searchRange, positionsCheckedDict)
    if positionsCheckedDict == nil then positionsCheckedDict = {} end
    local validPositionsArr = {}
    for x = startingPosition.x - searchRange, startingPosition.x + searchRange, 0.1 do
        for y = startingPosition.y - searchRange, startingPosition.y + searchRange, 0.1 do
            if positionsCheckedDict[{x,y}] == nil then
                positionsCheckedDict[{x,y}] = "done"
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

TrainJumper.CheckJumpPosition = function(surface, position)
    if surface.count_entities_filtered{
        area = Utility.CalculateBoundingBoxFromPositionAndRange(position, TrainJumper.playerSafeBox)
    } > 0 then
        return false
    end
    if not surface.can_place_entity{
        name = "player",
        position = position
    } then
        return false
    end
    return true
end

TrainJumper.SetTrainAvoidEvents = function()
	if ModSettings == nil or ModSettings.trainAvoidMode == nil then return end --Catch OnLoad being called before ModChnaged on mod upgrade and skip it this time
	if ModSettings.trainAvoidMode == "Preemtive" then
		script.on_event(defines.events.on_tick, TrainJumper.Manager)
		script.on_event(defines.events.on_entity_damaged, TrainJumper.EntityDamaged)
	elseif ModSettings.trainAvoidMode == "Reactive Only" then
		script.on_event(defines.events.on_tick, TrainJumper.JumpedPlayersManager)
		script.on_event(defines.events.on_entity_damaged, TrainJumper.EntityDamaged)
	else
		script.on_event(defines.events.on_tick, nil)
		script.on_event(defines.events.on_entity_damaged, nil)
	end
end

TrainJumper.EntityDamaged = function(event)
	local entity = event.entity
	Utility.DebugLogging("EntityDamaged", entity.name .. " EntityDamaged")
	if entity.type ~= "player" then
		Utility.DebugLogging("EntityDamaged", "entity not character")
		return
	end
	if entity.player == nil then
		Utility.DebugLogging("EntityDamaged", "entity has no player")
		return
	end
	if not Train.IsEntityATrainType(event.cause) then
		Utility.DebugLogging("EntityDamaged", "cause not train")
		return
	end
	Utility.DebugLogging("EntityDamaged", "final_damage_amount: " .. event.final_damage_amount)
	Utility.DebugLogging("EntityDamaged", "starting entity health: " .. entity.health)
	entity.health = entity.health + event.final_damage_amount
	Utility.DebugLogging("EntityDamaged", "returned entity to health: " .. entity.health)
	Utility.DebugLogging("EntityDamaged", "going to jump")
    TrainJumper.JumpPlayerToFreeSpot(entity.player)
end