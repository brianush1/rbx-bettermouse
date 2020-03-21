local function Signal()
	local sig = {}
	
	local mSignaler = Instance.new("BindableEvent")
	
	local mArgData = nil
	local mArgDataCount = nil
	
	function sig:Fire(...)
		mArgData = {...}
		mArgDataCount = select("#", ...)
		mSignaler:Fire()
	end
	
	function sig:Connect(f)
		if not f then error("connect(nil)", 2) end
		return mSignaler.Event:Connect(function()
			f(unpack(mArgData, 1, mArgDataCount))
		end)
	end
	
	function sig:Wait()
		mSignaler.Event:Wait()
		assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		return unpack(mArgData, 1, mArgDataCount)
	end
	
	sig.fire = sig.Fire
	sig.connect = sig.Connect
	sig.wait = sig.Wait
	
	return sig
end

local mouseOverlay
local function initMouseOverlay(parent)
	if parent == nil then
		local gui = Instance.new("ScreenGui")
		gui.DisplayOrder = 2000
		gui.Parent = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
		parent = gui
	end
	
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
	
	local lastClick = 0
	item["MouseButton" .. button .. "Down"]:Connect(function(x, y)
		mouseOverlay.Visible = true
		isDown = true
		
		upConnection = mouseOverlay["MouseButton" .. button .. "Up"]:Connect(function(x, y)
			mouseOverlay.Visible = false
			upConnection:Disconnect()
			moveConnection:Disconnect()
			upConnection = nil
			moveConnection = nil
			isDown = false
			
			if events.Up then events.Up(x, y) end
			
			local pos = item.AbsolutePosition
			local size = item.AbsoluteSize
			if (x < pos.X
					or y < pos.Y
					or x >= (pos.X + size.X)
					or y >= (pos.Y + size.Y)) then
				if events.Leave then
					entered = false
					events.Leave(x, y)
				end
			else
				if events.Click then events.Click(x, y) end
				if tick() - lastClick <= 0.3 then
					if events.DoubleClick then events.DoubleClick(x, y) end
				end
				lastClick = tick()
			end
		end)
		
		moveConnection = mouseOverlay.MouseMoved:Connect(function(x, y)
			if events.Move then events.Move(x, y) end
		end)
		
		if events.Down then events.Down(x, y) end
	end)
	
	item.MouseEnter:Connect(function(x, y)
		if entered or isDown then return end
		if y == item.AbsolutePosition.Y + item.AbsoluteSize.Y then return end
		entered = true
		if events.Enter then events.Enter(x, y) end
	end)
	
	item.MouseMoved:Connect(function(x, y)
		if isDown then return end
		if y == item.AbsolutePosition.Y + item.AbsoluteSize.Y then
			if events.Leave and entered then
				events.Leave(x, y)
			end
			entered = false
		else
			if entered then return end
			entered = true
			if events.Enter then events.Enter(x, y) end
		end
	end)
	
	item.MouseLeave:Connect(function(x, y)
		if isDown then return end
		if events.Leave and entered then
			events.Leave(x, y)
		end
		entered = false
	end)
end

local eventCache = {}

local function getEvents(item)
	if eventCache[item] then
		return eventCache[item]
	end
	
	local result = {
		MouseButton1Click = Signal(),
		MouseButton1DoubleClick = Signal(),
		MouseButton1Down = Signal(),
		MouseButton1Up = Signal(),
		MouseEnter = Signal(),
		MouseMoved = Signal(),
		MouseLeave = Signal()
	}
	
	for key in pairs(result) do
		pcall(function() result["Raw" .. key] = item[key] end)
	end
	
	mouseEvents(item, 1, {
		Down = function(x, y)
			result.MouseButton1Down:Fire(x, y)
		end,
		Up = function(x, y)
			result.MouseButton1Up:Fire(x, y)
		end,
		Enter = function(x, y)
			result.MouseEnter:Fire(x, y)
		end,
		Leave = function(x, y)
			result.MouseLeave:Fire(x, y)
		end,
		Move = function(x, y)
			result.MouseMoved:Fire(x, y)
		end,
		Click = function(x, y)
			result.MouseButton1Click:Fire(x, y)
		end,
		DoubleClick = function(x, y)
			result.MouseButton1DoubleClick:Fire(x, y)
		end
	})
	
	eventCache[item] = result
	return result
end

local function bindToRoact(roactModule)
	local SingleEventManager = require(roactModule:WaitForChild("SingleEventManager"))
	
	function SingleEventManager:connectEvent(key, listener)
		if self._instance:IsA("GuiButton") then
			local mouseEvents = getEvents(self._instance)
			if mouseEvents[key] then
				self:_connect(key, mouseEvents[key], listener)
				return
			end
		end
		
		self:_connect(key, self._instance[key], listener)
	end
end

return { mouseEvents = mouseEvents, initMouseOverlay = initMouseOverlay, getEvents = getEvents, bindToRoact = bindToRoact }
