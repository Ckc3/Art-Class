

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


local function create(className: string, props: {[string]: any}?, children: {Instance}?)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		(obj :: any)[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	return obj
end

local colors = {
	bg = Color3.fromRGB(32, 34, 40),
	top = Color3.fromRGB(28, 30, 36),
	text = Color3.fromRGB(235, 240, 255),
	muted = Color3.fromRGB(170, 180, 200),
	accent = Color3.fromRGB(90, 170, 255),
	stroke = Color3.fromRGB(255, 255, 255),
}

local screenGui = create("ScreenGui", {
	Name = "RevoltGUIOpener",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})
screenGui.Parent = PlayerGui

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(0.985, 0.06),
	Size = UDim2.fromOffset(380, 280),
	BackgroundColor3 = colors.bg,
	BackgroundTransparency = 0.05,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	create("UIStroke", { Color = colors.stroke, Transparency = 0.85, Thickness = 1 }),
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(220,220,230)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.10),
			NumberSequenceKeypoint.new(1, 0.22)
		}),
	}),
})
panel.Parent = screenGui

local topBar = create("Frame", {
	BackgroundColor3 = colors.top,
	Size = UDim2.new(1, 0, 0, 36),
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	create("UIStroke", { Color = colors.stroke, Transparency = 0.9, Thickness = 1 }),
})
topBar.Parent = panel

local title = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 0),
	Size = UDim2.new(1, -20, 1, 0),
	Font = Enum.Font.GothamSemibold,
	Text = "Revolt • Opened GUIs",
	TextSize = 16,
	TextColor3 = colors.text,
	TextXAlignment = Enum.TextXAlignment.Left,
})
title.Parent = topBar

local info = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 36),
	Size = UDim2.new(1, -20, 0, 22),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = colors.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Scanning client-accessible services for GUI objects...",
})
info.Parent = panel

local list = create("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 60),
	Size = UDim2.new(1, -20, 1, -70),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 6,
	BorderSizePixel = 0,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
list.Parent = panel

local function addLine(text: string, color: Color3?)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color or colors.text,
		Text = text,
	})
	label.Parent = list

    task.defer(function()
		local layout = list:FindFirstChildOfClass("UIListLayout")
		if layout then
			list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
		end
	end)
end


local SERVICE_NAMES = {
	workspace = "Workspace",
	Workspace = "Workspace",
}

local function serviceRootFor(inst: Instance): Instance?

    local roots = {StarterGui, ReplicatedStorage, ReplicatedFirst, Lighting, workspace, PlayerGui}
	for _, s in ipairs(roots) do
		if inst:IsDescendantOf(s) then return s end
	end
	return nil
end

local function pathOf(inst: Instance): string
	local parts = {}
	local root = serviceRootFor(inst)
	local cursor: Instance? = inst
	while cursor and cursor ~= root do
		table.insert(parts, 1, cursor.Name)
		cursor = cursor.Parent
	end
	local serviceName = root and (SERVICE_NAMES[root.Name] or root.Name) or "<Unknown>"
	return serviceName .. ":" .. table.concat(parts, "/")
end


local openedCount, enabledWorldCount, failedCount = 0, 0, 0
local MAX_TO_OPEN = 200 

local function safeEnableScreenGui(gui: ScreenGui)
	local ok, err = pcall(function()
		gui.Enabled = true
	end)
	return ok, err
end

local function openScreenGui(src: ScreenGui)

    if src:IsDescendantOf(PlayerGui) then
		local ok, err = safeEnableScreenGui(src)
		if ok then openedCount += 1 else failedCount += 1 end
		return ok, err, "enabled"
	end

    local ok, res = pcall(function()
		local clone = src:Clone()
		clone.ResetOnSpawn = false

        if PlayerGui:FindFirstChild(clone.Name) then
			clone.Name = clone.Name .. "_Copy"
		end
		clone.Parent = PlayerGui
		clone.Enabled = true
	end)
	if ok then openedCount += 1 else failedCount += 1 end
	return ok, res, "cloned"
end

local function enableWorldGui(gui: BillboardGui | SurfaceGui)
	local ok, err = pcall(function()
		(gui :: any).Enabled = true
	end)
	if ok then enabledWorldCount += 1 else failedCount += 1 end
	return ok, err
end


local scanRoots = {
	StarterGui,
	ReplicatedStorage,
	ReplicatedFirst,
	Lighting,
	workspace,
	PlayerGui,
}

local collected: {Instance} = {}
for _, root in ipairs(scanRoots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("ScreenGui") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			table.insert(collected, d)
		end
	end
end


local seen = {}
local unique: {Instance} = {}
for _, inst in ipairs(collected) do
	if not seen[inst] then
		seen[inst] = true
		table.insert(unique, inst)
	end
end


addLine(string.format("Found %d GUI objects (Screen/Billboard/Surface)", #unique), colors.muted)

local processed = 0
for _, inst in ipairs(unique) do
	if processed >= MAX_TO_OPEN then
		addLine("Stop: safety cap reached (" .. tostring(MAX_TO_OPEN) .. ")", Color3.fromRGB(255, 200, 120))
		break
	end
	processed += 1

	if inst:IsDescendantOf(screenGui) then

        continue
	end

	local path = pathOf(inst)
	if inst:IsA("ScreenGui") then
		local ok, err, mode = openScreenGui(inst)
		if ok then
			addLine("[ScreenGui " .. (mode or "?") .. "] " .. path, colors.text)
		else
			addLine("[ScreenGui failed] " .. path .. " — " .. tostring(err), Color3.fromRGB(255, 130, 130))
		end
	elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then

        local ok, err = enableWorldGui(inst :: any)
		if ok then
			addLine("[WorldGui enabled] " .. path, colors.text)
		else
			addLine("[WorldGui failed] " .. path .. " — " .. tostring(err), Color3.fromRGB(255, 130, 130))
		end
	end
end


addLine(" ")
addLine(string.format("Summary: opened %d, enabled world %d, failed %d", openedCount, enabledWorldCount, failedCount), colors.accent)


TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Position = UDim2.fromScale(0.985, 0.06),
	Size = UDim2.fromOffset(380, 280)
}):Play()
