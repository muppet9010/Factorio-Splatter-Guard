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

Track.GetConnectedTrack = function(track, railDirection)
    local nextRail = nil
    local tracks = {}
    
    nextRail = track.get_connected_rail{rail_direction = railDirection, rail_connection_direction = defines.rail_connection_direction.straight}
    if nextRail ~= nil then
        table.insert(tracks, nextRail)
    end
    nextRail = track.get_connected_rail{rail_direction = railDirection, rail_connection_direction = defines.rail_connection_direction.right}
    if nextRail ~= nil then
        table.insert(tracks, nextRail)
    end
    nextRail = track.get_connected_rail{rail_direction = railDirection, rail_connection_direction = defines.rail_connection_direction.left}
    if nextRail ~= nil then
        table.insert(tracks, nextRail)
    end
    
    return tracks
end

Track.GetTrackNearPositionAsArray = function(surface, position, range)
    return surface.find_entities_filtered{
        area = Utility.CalculateBoundingBoxFromPositionAndRange(position, range),
        type = {"straight-rail", "curved-rail"}
    }
end