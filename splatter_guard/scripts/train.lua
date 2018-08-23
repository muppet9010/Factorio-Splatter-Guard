Train = {}

Train.IsATrainNearPlayer = function(player)
	Utility.DebugLogging("IsATrainNearPlayer", player.name .. " IsATrainNearPlayer")
    local trainEntitiesArr = Train.GetTrainEntitiesNearPositionAsArray(player.surface, player.position, TrainJumper.trainSearchSize)
    if trainEntitiesArr == nil or #trainEntitiesArr == 0 then
		Utility.DebugLogging("IsATrainNearPlayer", "no train entities found near player")
        return false
    end
	Utility.DebugLogging("IsATrainNearPlayer", #trainEntitiesArr .. " train entities found near player")
    local trainsDict = Train.GetTrainsFromTrainEntitiesAsDictionary(trainEntitiesArr)
	if Utility.debugLogging["IsATrainNearPlayer"] then Utility.DebugLogging("IsATrainNearPlayer", Utility.GetTableLength(trainsDict) .. " trains found for train entities") end
    local playerNearTrackArr = Track.GetTrackNearPositionAsArray(player.surface, player.position, TrainJumper.playerSafeBox)
	Utility.DebugLogging("IsATrainNearPlayer", #playerNearTrackArr .. " track entities found near player")
	if Utility.debugLogging["IsATrainNearPlayer"] then
		for k, v in pairs(playerNearTrackArr) do
			Utility.DebugLogging("IsATrainNearPlayer", "player near track " .. k .. " position: " .. Utility.PositionToString(v.position))
		end
	end
    for i, train in pairs(trainsDict) do
		Utility.DebugLogging("IsATrainNearPlayer", "reviewing train id " .. i)
        if train.speed ~= 0 then
            local trainsTrackArr = Train.GetTrackForTrainAsArray(train)
			Utility.DebugLogging("IsATrainNearPlayer", "train " .. i .. " has " .. #trainsTrackArr .. " track pieces")
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

Train.GetTrackForTrainAsArray = function(train)
    local trackArr = {}
    local trackStart = nil
    
	if train.speed > 0 then
		trackStart = train.front_rail
	else
		trackStart = train.back_rail
	end
	
    table.insert(trackArr, trackStart)
    for i, track in pairs(Track.GetConnectedTrack(trackStart, defines.rail_direction.front)) do
        table.insert(trackArr, track)
    end
    for i, track in pairs(Track.GetConnectedTrack(trackStart, defines.rail_direction.back)) do
        table.insert(trackArr, track)
    end
	
	return trackArr
end

Train.GetTrainEntitiesNearPositionAsArray = function(surface, position, range)
    return surface.find_entities_filtered{
        area = Utility.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"locomotive", "cargo-wagon", "fluid-wagon"}
    }
end

Train.GetTrainsFromTrainEntitiesAsDictionary = function(trainEntitiesArr)
    local trainsDict = {}
    for i, trainEntity in pairs(trainEntitiesArr) do
        local train = trainEntity.train
		if trainsDict[train.id] == nil then
			trainsDict[train.id] = train
		end
	end
    return trainsDict
end