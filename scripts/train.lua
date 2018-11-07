Train = {}
Train.NewTrainsWithEntities = function()
	return {
		Train = nil, --LuaTrain
		EntitiesArr = {} --Array of LuaEntities of the supplied train entities
	}
end

Train.IsATrainNearPlayer = function(player)
	Utility.DebugLogging("IsATrainNearPlayer", player.name .. " IsATrainNearPlayer")
	
    local rawTrainEntitiesArr = Train.GetTrainEntitiesNearPositionAsArray(player.surface, player.position, TrainJumper.trainSearchSize)
    if rawTrainEntitiesArr == nil or #rawTrainEntitiesArr == 0 then
		Utility.DebugLogging("IsATrainNearPlayer", "no train entities found near player")
        return false
    end
	Utility.DebugLogging("IsATrainNearPlayer", #rawTrainEntitiesArr .. " train entities found near player")
    local nearTrainsWithEntitiesDict = Train.GetTrainsWithEntitiesFromTrainEntitiesArrAsDictionary(rawTrainEntitiesArr)
	if Utility.debugLogging["IsATrainNearPlayer"] then Utility.DebugLogging("IsATrainNearPlayer", Utility.GetTableLength(nearTrainsWithEntitiesDict) .. " trains found for train entities") end
	
    local playerNearTrackArr = Track.GetTrackNearPositionAsArray(player.surface, player.position, TrainJumper.playerSafeBox)
	Utility.DebugLogging("IsATrainNearPlayer", #playerNearTrackArr .. " track entities found near player")
	if Utility.debugLogging["IsATrainNearPlayer"] then
		for k, v in pairs(playerNearTrackArr) do
			Utility.DebugLogging("IsATrainNearPlayer", "player near track " .. k .. " position: " .. Utility.PositionToString(v.position))
		end
	end
	
    for i, trainWithEntities in pairs(nearTrainsWithEntitiesDict) do
		Utility.DebugLogging("IsATrainNearPlayer", "reviewing train id " .. i)
        if trainWithEntities.Train.speed ~= 0 then			
            local trainsTrackArr = Train.GetTrackForTrainAsArray(trainWithEntities)
			Utility.DebugLogging("IsATrainNearPlayer", "train " .. i .. " has " .. #trainsTrackArr .. " track pieces for " .. #trainWithEntities.EntitiesArr .. " train entities")
			if Utility.debugLogging["IsATrainNearPlayer"] then
				for k, v in pairs(trainsTrackArr) do
					Utility.DebugLogging("IsATrainNearPlayer", "train " .. i .. " near track " .. k .. " position: " .. Utility.PositionToString(v.position))
				end
			end
            for j, trainTrack in pairs(trainsTrackArr) do
                for k, nearTrack in pairs(playerNearTrackArr) do
                    if nearTrack.position.x == trainTrack.position.x and nearTrack.position.y == trainTrack.position.y then
						Utility.DebugLogging("IsATrainNearPlayer", "player near track that is near train")
                        return true
                    end
                end
            end
        end
    end
	Utility.DebugLogging("IsATrainNearPlayer", "player not near track that is near train")
    return false
end

Train.GetTrackForTrainAsArray = function(trainWithEntities)
    local trackArr = {}
	
	for i, trainEntity in pairs(trainWithEntities.EntitiesArr) do
		for i, trackEntity in pairs(Train.GetTrackForTrainEntityAsArray(trainEntity, true)) do
			table.insert(trackArr, trackEntity)
		end
		for i, trackEntity in pairs(Train.GetTrackForTrainEntityAsArray(trainEntity, false)) do
			table.insert(trackArr, trackEntity)
		end
	end
	
	return trackArr
end

Train.GetTrackForTrainEntityAsArray = function(trainEntity, naturalOrientation)
	Utility.DebugLogging("GetTrackForTrainEntityAsArray", "trainEntity position " .. Utility.PositionToString(trainEntity.position) .. " orientation: " .. trainEntity.orientation .. " naturalOrientation: " .. tostring(naturalOrientation))
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
	Utility.DebugLogging("GetTrackForTrainEntityAsArray", "searchPosition " .. Utility.PositionToString(searchPosition))
	local searchArea = {
		left_top = {
			x = searchPosition.x - TrainJumper.trainTrackSearchSize,
			y = searchPosition.y - TrainJumper.trainTrackSearchSize
		},
		right_bottom = {
			x = searchPosition.x + TrainJumper.trainTrackSearchSize,
			y = searchPosition.y + TrainJumper.trainTrackSearchSize
		}
	}
	
	local searchedTracks = trainEntity.surface.find_entities_filtered{ area = searchArea, type = {"straight-rail", "curved-rail"}}
	if Utility.debugLogging["GetTrackForTrainEntityAsArray"] then
		for k, v in pairs(searchedTracks) do
			Utility.DebugLogging("GetTrackForTrainEntityAsArray", "track position: " .. Utility.PositionToString(v.position))
		end
	end
	return searchedTracks
end

Train.GetTrainEntitiesNearPositionAsArray = function(surface, position, range)
    return surface.find_entities_filtered{
        area = Utility.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"locomotive", "cargo-wagon", "fluid-wagon"}
    }
end

Train.GetTrainsWithEntitiesFromTrainEntitiesArrAsDictionary = function(trainEntitiesArr)
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