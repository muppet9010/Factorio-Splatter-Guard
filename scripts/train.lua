local Utils = require("utility/utils")
local Train = {}

function Train.NewTrainsWithEntities()
    return {
        Train = nil, --LuaTrain
        EntitiesArr = {} --Array of LuaEntities of the supplied train entities
    }
end

---@param player_surface LuaSurface
---@param player_position MapPosition
function Train.IsATrainNearPlayer(player_surface, player_position)
    local rawTrainEntitiesArr = Train.GetTrainEntitiesNearPositionAsArray(player_surface, player_position, global.Mod.State.trainSearchSize)
    if rawTrainEntitiesArr == nil or #rawTrainEntitiesArr == 0 then
        return false
    end
    local nearTrainsWithEntitiesDict = Train.GetTrainsWithEntitiesFromTrainEntitiesArrAsDictionary(rawTrainEntitiesArr)

    local playerNearTrackArr =
        player_surface.find_entities_filtered {
        area = Utils.CalculateBoundingBoxFromPositionAndRange(player_position, global.Mod.State.playerSafeBox),
        type = {"straight-rail", "curved-rail"}
    }

    for _, trainWithEntities in pairs(nearTrainsWithEntitiesDict) do
        if trainWithEntities.Train.speed ~= 0 then
            local trainsTrackArr = Train.GetTrackForTrainAsArray(trainWithEntities)
            for _, trainTrack in pairs(trainsTrackArr) do
                local trainTrack_position = trainTrack.position
                for _, nearTrack in pairs(playerNearTrackArr) do
                    local nearTrack_position = nearTrack.position
                    if nearTrack_position.x == trainTrack_position.x and nearTrack_position.y == trainTrack_position.y then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function Train.GetTrackForTrainAsArray(trainWithEntities)
    local trackArr = {}

    for _, trainEntity in pairs(trainWithEntities.EntitiesArr) do
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

    local searchedTracks = trainEntity.surface.find_entities_filtered {area = searchArea, type = {"straight-rail", "curved-rail"}}
    return searchedTracks
end

function Train.GetTrainEntitiesNearPositionAsArray(surface, position, range)
    return surface.find_entities_filtered {
        area = Utils.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}
    }
end

function Train.GetTrainsWithEntitiesFromTrainEntitiesArrAsDictionary(trainEntitiesArr)
    local trainsWithEntitiesDict = {}
    for i, trainEntity in pairs(trainEntitiesArr) do
        local train = trainEntity.train
        local train_id = train.id
        if trainsWithEntitiesDict[train_id] == nil then
            local trainsWithEntities = Train.NewTrainsWithEntities()
            table.insert(trainsWithEntities.EntitiesArr, trainEntity)
            trainsWithEntities.Train = train
            trainsWithEntitiesDict[train_id] = trainsWithEntities
        else
            table.insert(trainsWithEntitiesDict[train_id].EntitiesArr, trainEntity)
        end
    end
    return trainsWithEntitiesDict
end

Train.TrainEntityTypes = {
    locomotive = "locomotive",
    ["cargo-wagon"] = "cargo-wagon",
    ["fluid-wagon"] = "fluid-wagon",
    ["artillery-wagon"] = "artillery-wagon"
}

return Train
