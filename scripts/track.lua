local Utils = require("utility/utils")
local Track = {}

function Track.IsTrackNearPosition(surface, position, range)
    if
        surface.count_entities_filtered {
            area = Utils.CalculateBoundingBoxFromPositionAndRange(position, range),
            type = {"straight-rail", "curved-rail"},
            limit = 1
        } > 0
     then
        return true
    else
        return false
    end
end

function Track.GetTrackNearPositionAsArray(surface, position, range)
    return surface.find_entities_filtered {
        area = Utils.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"straight-rail", "curved-rail"}
    }
end

return Track
