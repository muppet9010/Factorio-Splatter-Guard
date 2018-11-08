Track = {}

Track.IsTrackNearPosition = function(surface, position, range)
    if surface.count_entities_filtered{
        area = Utility.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"straight-rail", "curved-rail"},
        limit = 1
    } > 0 then
        return true
    else
        return false
    end
end

Track.GetTrackNearPositionAsArray = function(surface, position, range)
    return surface.find_entities_filtered{
        area = Utility.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"straight-rail", "curved-rail"}
    }
end