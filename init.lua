local mouseOverlay
local function initMouseOverlay(parent)
	mouseOverlay = Instance.new("ImageButton")
	mouseOverlay.Size = UDim2.new(1, 0, 1, 0)
	mouseOverlay.BackgroundTransparency = 1
	mouseOverlay.Visible = false
	mouseOverlay.ZIndex = 2000
	mouseOverlay.Parent = parent
end

local function mouseEvents(item, button, events)
	local upConnection, moveConnection
	
	local entered = false
	local isDown = false
	
	item["MouseButton" .. button .. "Down"]:Connect(function()
		mouseOverlay.Visible = true
		isDown = true
		
		upConnection = mouseOverlay["MouseButton" .. button .. "Up"]:Connect(function(x, y)
			mouseOverlay.Visible = false
			upConnection:Disconnect()
			moveConnection:Disconnect()
			upConnection = nil
			moveConnection = nil
			isDown = false
			
			if events.Up then events.Up() end
			
			local pos = item.AbsolutePosition
			local size = item.AbsoluteSize
			if (x < pos.X
					or y < pos.Y
					or x >= (pos.X + size.X)
					or y >= (pos.Y + size.Y)) then
				if events.Leave then
					entered = false
					events.Leave()
				end
			else
				if events.Click then events.Click() end
			end
		end)
		
		moveConnection = mouseOverlay.MouseMoved:Connect(function()
			if events.Move then events.Move() end
		end)
		
		if events.Down then events.Down() end
	end)
	
	item["MouseEnter"]:Connect(function()
		if entered or isDown then return end
		entered = true
		if events.Enter then events.Enter() end
	end)
	
	item["MouseLeave"]:Connect(function()
		if isDown then return end
		if events.Leave and entered then
			events.Leave()
		end
		entered = false
	end)
end

return { mouseEvents = mouseEvents, initMouseOverlay = initMouseOverlay }
