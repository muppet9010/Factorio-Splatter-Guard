local Utils = require("utility/utils")
local Logging = require("utility/logging")
local Track = require("track")
local Train = {}


function Train.NewTrainsWithEntities()
	return {
		Train = nil, --LuaTrain
		EntitiesArr = {} --Array of LuaEntities of the supplied train entities
	}
end


function Train.IsATrainNearPlayer(player)
	local debugLogging = false
	Logging.Log(player.name .. " IsATrainNearPlayer", debugLogging)

    local rawTrainEntitiesArr = Train.GetTrainEntitiesNearPositionAsArray(player.surface, player.position, global.Mod.State.trainSearchSize)
    if rawTrainEntitiesArr == nil or #rawTrainEntitiesArr == 0 then
		Logging.Log("no train entities found near player", debugLogging)
        return false
    end
	Logging.Log(#rawTrainEntitiesArr .. " train entities found near player", debugLogging)
    local nearTrainsWithEntitiesDict = Train.GetTrainsWithEntitiesFromTrainEntitiesArrAsDictionary(rawTrainEntitiesArr)
	if debugLogging then Logging.Log(Utils.GetTableLength(nearTrainsWithEntitiesDict) .. " trains found for train entities", debugLogging) end

    local playerNearTrackArr = Track.GetTrackNearPositionAsArray(player.surface, player.position, global.Mod.State.playerSafeBox)
	Logging.Log(#playerNearTrackArr .. " track entities found near player", debugLogging)
	if debugLogging then
		for k, v in pairs(playerNearTrackArr) do
			Logging.Log("player near track " .. k .. " position: " .. Logging.PositionToString(v.position), debugLogging)
		end
	end

    for i, trainWithEntities in pairs(nearTrainsWithEntitiesDict) do
		Logging.Log("reviewing train id " .. i, debugLogging)
        if trainWithEntities.Train.speed ~= 0 then
            local trainsTrackArr = Train.GetTrackForTrainAsArray(trainWithEntities)
			if debugLogging then
				Logging.Log("train " .. i .. " has " .. #trainsTrackArr .. " track pieces for " .. #trainWithEntities.EntitiesArr .. " train entities", debugLogging)
				for k, v in pairs(trainsTrackArr) do
					Logging.Log("train " .. i .. " near track " .. k .. " position: " .. Logging.PositionToString(v.position), debugLogging)
				end
			end
            for j, trainTrack in pairs(trainsTrackArr) do
                for k, nearTrack in pairs(playerNearTrackArr) do
                    if nearTrack.position.x == trainTrack.position.x and nearTrack.position.y == trainTrack.position.y then
						Logging.Log("player near track that is near train", debugLogging)
                        return true
                    end
                end
            end
        end
    end
	Logging.Log("player not near track that is near train", debugLogging)
    return false
end


function Train.GetTrackForTrainAsArray(trainWithEntities)
    local trackArr = {}

	for i, trainEntity in pairs(trainWithEntities.EntitiesArr) do
		for _, trackEntity in pairs(Train.GetTrackForTrainEntityAsArray(trainEntity, true)) do
			table.insert(trackArr, trackEntity)
		end
		for _, trackEntity in pairs(Train.GetTrackForTrainEntityAsArray(trainEntity, false)) do
			table.insert(trackArr, trackEntity)
		end
	end

	return trackArr
end


function Train.GetTrackForTrainEntityAsArray(trainEntity, naturalOrientation)
	local debugLogging = false
	if debugLogging then Logging.Log("trainEntity position " .. Logging.PositionToString(trainEntity.position) .. " orientation: " .. trainEntity.orientation .. " naturalOrientation: " .. tostring(naturalOrientation), debugLogging) end
	local orientation = trainEntity.orientation
	if not naturalOrientation then
		orientation = orientation + 0.5
	end
	local deg = orientation * 360
	local rad = math.rad(deg)
	local trainEntityCollisionBoxLength = trainEntity.prototype.collision_box.left_top.y
	local xMultiplier = math.sin(rad)
	local yMultiplier = math.cos(rad)

	local searchPosition = {
		x = trainEntity.position.x + (xMultiplier * trainEntityCollisionBoxLength),
		y = trainEntity.position.y - (yMultiplier * trainEntityCollisionBoxLength)
	}
	Logging.Log("searchPosition " .. Logging.PositionToString(searchPosition), debugLogging)
	local searchArea = {
		left_top = {
			x = searchPosition.x - global.Mod.State.trainTrackSearchSize,
			y = searchPosition.y - global.Mod.State.trainTrackSearchSize
		},
		right_bottom = {
			x = searchPosition.x + global.Mod.State.trainTrackSearchSize,
			y = searchPosition.y + global.Mod.State.trainTrackSearchSize
		}
	}

	local searchedTracks = trainEntity.surface.find_entities_filtered{ area = searchArea, type = {"straight-rail", "curved-rail"}}
	if debugLogging then
		for k, v in pairs(searchedTracks) do
			Logging.Log("track position: " .. Logging.PositionToString(v.position), debugLogging)
		end
	end
	return searchedTracks
end


function Train.GetTrainEntitiesNearPositionAsArray(surface, position, range)
    return surface.find_entities_filtered{
        area = Utils.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"locomotive", "cargo-wagon", "fluid-wagon"}
    }
end


function Train.GetTrainsWithEntitiesFromTrainEntitiesArrAsDictionary(trainEntitiesArr)
    local trainsWithEntitiesDict = {}
    for i, trainEntity in pairs(trainEntitiesArr) do
		local train = trainEntity.train
		if trainsWithEntitiesDict[train.id] == nil then
			local trainsWithEntities = Train.NewTrainsWithEntities()
			table.insert(trainsWithEntities.EntitiesArr, trainEntity)
			trainsWithEntities.Train = train
			trainsWithEntitiesDict[train.id] = trainsWithEntities
		else
			table.insert(trainsWithEntitiesDict[train.id].EntitiesArr, trainEntity)
		end
	end
    return trainsWithEntitiesDict
end


function Train.IsEntityATrainType(entity)
	if entity == nil then return false end
	if entity.type == "locomotive" then return true end
	if entity.type == "cargo-wagon" then return true end
	if entity.type == "fluid-wagon" then return true end
	return false
end


return Train