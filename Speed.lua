

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer


local MIN_SPEED = 16       
local MAX_SPEED = 200      
local DEFAULT_SPEED = 32   
local ENFORCE_INTERVAL = 0.25 


local currentSpeed = DEFAULT_SPEED
local humanoid: Humanoid? = nil
local enforcing = false


local function getHumanoid(): Humanoid?
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if not character then return nil end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then
		local ok, found = pcall(function() return character:WaitForChild("Humanoid", 5) end)
		if ok then hum = found :: Humanoid end
	end
	return hum
end


local function applySpeed()
	if humanoid then

    pcall(function()
			humanoid.WalkSpeed = currentSpeed
		end)
	end
end


local function startEnforcing()
	if enforcing then return end
	enforcing = true
	local last = 0
	RunService.Heartbeat:Connect(function(dt)
		last += dt
		if last >= ENFORCE_INTERVAL then
			last = 0

        if not humanoid or humanoid.Parent == nil then
				humanoid = getHumanoid()
			end
			applySpeed()
		end
	end)
end


local function create(className: string, props: {[string]: any}?, children: {Instance}?)
	local obj = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			(obj :: any)[k] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = obj
		end
	end
	return obj
end


local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("RevoltSpeedUI")
if old then old:Destroy() end


local screenGui = create("ScreenGui", {
	Name = "RevoltSpeedUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})


local panel = create("Frame", {
	Name = "SpeedPanel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 120), 
	Size = UDim2.new(0, 240, 0, 94),
	BackgroundColor3 = Color3.fromRGB(38, 40, 46),
	BackgroundTransparency = 0,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	create("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.88, Thickness = 1 }),
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(220,220,230)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.14),
			NumberSequenceKeypoint.new(1, 0.28)
		})
	}),
})

local titleBar = create("Frame", {
	Name = "TitleBar",
	BackgroundColor3 = Color3.fromRGB(30, 32, 36),
	BackgroundTransparency = 0,
	Size = UDim2.new(1, 0, 0, 28),
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	create("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.9, Thickness = 1 }),
})
titleBar.Parent = panel

local titleLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 0),
	Size = UDim2.new(0.7, 0, 1, 0),
	Font = Enum.Font.GothamSemibold,
	Text = "Speed Boost",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(235, 240, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
})
titleLabel.Parent = titleBar

local valueLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 0),
	Size = UDim2.new(0, 80, 1, 0),
	Font = Enum.Font.Gotham,
	Text = tostring(DEFAULT_SPEED),
	TextSize = 14,
	TextColor3 = Color3.fromRGB(170, 180, 200),
	TextXAlignment = Enum.TextXAlignment.Right,
})
valueLabel.Parent = titleBar


local body = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 36),
	Size = UDim2.new(1, -20, 1, -46),
})
body.Parent = panel

local sliderLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 18),
	Font = Enum.Font.Gotham,
	Text = string.format("Speed (%d - %d)", MIN_SPEED, MAX_SPEED),
	TextSize = 13,
	TextColor3 = Color3.fromRGB(170, 180, 200),
	TextXAlignment = Enum.TextXAlignment.Left,
})
sliderLabel.Parent = body

local bar = create("Frame", {
	Name = "Bar",
	Position = UDim2.new(0, 0, 0, 26),
	Size = UDim2.new(1, 0, 0, 6),
	BackgroundColor3 = Color3.fromRGB(44, 46, 54),
	BackgroundTransparency = 0,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 4) }),
	create("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.9, Thickness = 1 })
})
bar.Parent = body

local fill = create("Frame", {
	Name = "Fill",
	BackgroundColor3 = Color3.fromRGB(80, 120, 255),
	BackgroundTransparency = 0,
	Size = UDim2.new((DEFAULT_SPEED - MIN_SPEED)/(MAX_SPEED - MIN_SPEED), 0, 1, 0),
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 4) })
})
fill.Parent = bar

local handle = create("Frame", {
	Name = "Handle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new((DEFAULT_SPEED - MIN_SPEED)/(MAX_SPEED - MIN_SPEED), 0, 0.5, 0),
	Size = UDim2.new(0, 14, 0, 14),
	BackgroundColor3 = Color3.fromRGB(235, 240, 255),
	BackgroundTransparency = 0,
}, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) })
})
handle.Parent = bar


local dragging = false
local dragStart: Vector2? = nil
local startPos: UDim2? = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and dragStart and startPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)


local sliding = false

local function setSpeedFromAlpha(alpha: number)
	alpha = math.clamp(alpha, 0, 1)
	local val = MIN_SPEED + alpha * (MAX_SPEED - MIN_SPEED)

  currentSpeed = math.floor(val + 0.5)

  valueLabel.Text = tostring(currentSpeed)
	fill.Size = UDim2.new(alpha, 0, 1, 0)
	handle.Position = UDim2.new(alpha, 0, 0.5, 0)

  applySpeed()
end

local function getAlphaFromX(x: number)
	local absPos = bar.AbsolutePosition.X
	local width = bar.AbsoluteSize.X
	if width <= 0 then return 0 end
	return (x - absPos) / width
end

bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliding = true
		setSpeedFromAlpha(getAlphaFromX(input.Position.X))
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then sliding = false end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setSpeedFromAlpha(getAlphaFromX(input.Position.X))
	end
end)


screenGui.Parent = playerGui
panel.Parent = screenGui


humanoid = getHumanoid()
applySpeed()
startEnforcing()


LocalPlayer.CharacterAdded:Connect(function()
	humanoid = getHumanoid()
	applySpeed()
end)
