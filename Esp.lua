local sharedKey = "__REVOLT_ESP_ACTIVE__"
if getgenv then
    getgenv()[sharedKey] = true
elseif shared then
    shared[sharedKey] = true
end

if (getgenv and getgenv()[sharedKey] ~= true) and (shared and shared[sharedKey] ~= true) then

end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer


local SHOW_PLAYERS = true
local SHOW_NPCS = true
local SHOW_ITEMS = true

local PLAYER_ENEMY_COLOR = Color3.fromRGB(255, 70, 70)
local PLAYER_TEAMMATE_COLOR = Color3.fromRGB(60, 220, 140)
local NPC_COLOR = Color3.fromRGB(255, 220, 90)
local ITEM_COLOR = Color3.fromRGB(120, 200, 255)

local FILL_TRANSPARENCY = 0.85
local OUTLINE_TRANSPARENCY = 0.15

local LABEL_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local LABEL_STROKE_COLOR = Color3.fromRGB(0, 0, 0)
local LABEL_STROKE = 2
local LABEL_FONT = Enum.Font.GothamSemibold
local LABEL_SIZE = 12


local tracked = {}
local connections = {}

local function safeDisconnect(conn)
    pcall(function()
        if conn and conn.Disconnect then conn:Disconnect() end
    end)
end

local function cleanupInstance(inst)
    local info = tracked[inst]
    if not info then return end
    pcall(function() if info.highlight then info.highlight:Destroy() end end)
    pcall(function() if info.billboard then info.billboard:Destroy() end end)
    if info.destroyConn then safeDisconnect(info.destroyConn) end
    tracked[inst] = nil
end

local function onAncestryChanged(inst)
    if not inst:IsDescendantOf(Workspace) then
        cleanupInstance(inst)
    end
end

local function createHighlight(adornee, color)
    local h = Instance.new("Highlight")
    h.Adornee = adornee
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = FILL_TRANSPARENCY
    h.OutlineTransparency = OUTLINE_TRANSPARENCY

    h.Parent = typeof(adornee) == "Instance" and adornee or Workspace
    return h
end

local function createBillboard(parent, text, color)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESPLabel"
    bb.Size = UDim2.new(0, 200, 0, 24)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.MaxDistance = 1e6
    bb.Adornee = parent
    bb.Parent = parent

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Font = LABEL_FONT
    tl.TextSize = LABEL_SIZE
    tl.TextColor3 = color or LABEL_TEXT_COLOR
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = LABEL_STROKE_COLOR
    tl.Text = text
    tl.Parent = bb

    return bb, tl
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team or LocalPlayer.TeamColor
    local theirTeam = player.Team or player.TeamColor
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    end
    return true
end

local function getRootPartFromModel(model)
    if not model then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end

    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            return d
        end
    end
    return nil
end

local function distanceTo(pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        return (pos - hrp.Position).Magnitude
    end
    return 0
end

local function trackPlayer(player)
    local function hookCharacter(char)
        if not SHOW_PLAYERS then return end
        if not char then return end
        local color = isEnemy(player) and PLAYER_ENEMY_COLOR or PLAYER_TEAMMATE_COLOR


        local hl = createHighlight(char, color)

        local bb, tl = createBillboard(char, player.Name, LABEL_TEXT_COLOR)
        tracked[char] = {
            kind = "player",
            highlight = hl,
            billboard = bb,
            label = tl,
            rootPart = getRootPartFromModel(char),
            destroyConn = char.AncestryChanged:Connect(onAncestryChanged),
        }
    end


    if player.Character then
        hookCharacter(player.Character)
    end


    table.insert(connections, player.CharacterAdded:Connect(function(char)
        hookCharacter(char)
    end))


    table.insert(connections, player.CharacterRemoving:Connect(function(char)
        cleanupInstance(char)
    end))
end

local function isPlayerCharacter(model)
    if not model or not model:IsA("Model") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function trackNPC(model)
    if not SHOW_NPCS then return end
    if not model or not model:IsA("Model") then return end
    if isPlayerCharacter(model) then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if tracked[model] then return end

    local hl = createHighlight(model, NPC_COLOR)
    local bb, tl = createBillboard(model, model.Name, LABEL_TEXT_COLOR)

    tracked[model] = {
        kind = "npc",
        highlight = hl,
        billboard = bb,
        label = tl,
        rootPart = getRootPartFromModel(model),
        destroyConn = model.AncestryChanged:Connect(onAncestryChanged),
    }
end

local function findToolHandle(tool)
    local handle = tool:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle end
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function isToolCarried(tool)
    local p = tool.Parent
    if not p then return false end
    if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then
        return true
    end
    if p:IsA("Backpack") then
        return true
    end
    return false
end

local function trackTool(tool)
    if not SHOW_ITEMS then return end
    if tracked[tool] then return end
    if isToolCarried(tool) then return end

    local handle = findToolHandle(tool)
    if not handle then return end

    local hl = createHighlight(handle, ITEM_COLOR)
    local bb, tl = createBillboard(handle, tool.Name, ITEM_COLOR)

    tracked[tool] = {
        kind = "item",
        highlight = hl,
        billboard = bb,
        label = tl,
        rootPart = handle,
        destroyConn = tool.AncestryChanged:Connect(onAncestryChanged),
    }
end


for _, p in ipairs(Players:GetPlayers()) do
    trackPlayer(p)
end

for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("Model") then
        trackNPC(d)
    elseif d:IsA("Tool") then
        trackTool(d)
    end
end


table.insert(connections, Players.PlayerAdded:Connect(trackPlayer))

table.insert(connections, Workspace.DescendantAdded:Connect(function(d)
    if d:IsA("Model") then

                trackNPC(d)
    elseif d:IsA("Tool") then
        trackTool(d)
    end
end))

table.insert(connections, Workspace.DescendantRemoving:Connect(function(d)
    cleanupInstance(d)
end))


table.insert(connections, RunService.Heartbeat:Connect(function()
    for inst, info in pairs(tracked) do
        if not inst or not inst.Parent then
            cleanupInstance(inst)
        else

                    if info.label and info.rootPart and info.rootPart.Parent then
                local pos = info.rootPart.Position
                local dist = distanceTo(pos)
                local baseName = ""

                if info.kind == "player" then
                    baseName = inst.Name
                elseif info.kind == "npc" then
                    baseName = inst.Name
                elseif info.kind == "item" then
                    baseName = inst.Name
                end

                info.label.Text = string.format("%s  [%.0f]", baseName, dist)
            end
        end
    end
end))

-- Safety: clean up tracked entries if this script is re-run (executor restart)
-- No toggle in this script by design. To turn off, rejoin or unload via executor.
