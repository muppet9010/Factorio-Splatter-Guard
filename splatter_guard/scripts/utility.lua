Utility = {}
Utility.debugLogging = {}
Utility.debugLogging["PlayerManager"] = false
Utility.debugLogging["IsATrainNearPlayer"] = false

Utility.DoBoundingBoxesOverlap = function(box1, box2)
    if box1.left_top.x <= box2.right_bottom.x or box1.right_bottom.x >= box1.left_top.x or box1.left_top.y <= box2.right_bottom.y or box1.right_bottom.y >= box1.left_top.y then
        return true
    else
        return false
    end
end

Utility.CalculateBoundingBoxFromPositionAndRange = function(position, range)
    return {
        left_top = {
            x = position.x - range,
            y = position.y - range,
        },
        right_bottom = {
            x = position.x + range,
            y = position.y + range,
        }
    }
end

Utility.DebugLogging = function(option, text)
	if Utility.debugLogging[option] then
		game.write_file("SplatterGuard_logOutput.txt", tostring(text) .. "\r\n", true)
	end
end

Utility.GetTableLength = function(table)
	local count = 0
	for k,v in pairs(table) do
		 count = count + 1
	end
	return count
end

Utility.PositionToString = function(position)
	return "(" .. position.x .. ", " .. position.y ..")"
end