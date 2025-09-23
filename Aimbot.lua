local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local enabled = false
local holding = false
local connBegan, connEnded

local RENDER_BIND_ID = "RevoltAimbot"

local CONFIG = {
    MaxDistance = 800,          -- studs limit to consider a target (3D, no visibility requirement)
    LockPartName = "Head",     -- preferred aim part
    TeamCheck = false,          -- set true if you want to avoid teammates
    Smoothness = 0.25,          -- 0 = snap, 0.05..0.4 = smooth
}

-- Simple notification helper (works with SetCore, falls back to a tiny toast)
local function notify(text)
    local ok = pcall(function()
        StarterGui:SetCore("SendNotification", {Title = "Revolt", Text = text, Duration = 3})
    end)
    if ok then return end

    -- Fallback toast
    local parent = nil
    pcall(function() parent = gethui and gethui() end)
    if not parent then
        local okcg, cg = pcall(function() return game:GetService("CoreGui") end)
        parent = (okcg and cg) or nil
    end
    if not parent then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "RevoltToast"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 1000
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
    lbl.BackgroundTransparency = 0.2
    lbl.TextColor3 = Color3.fromRGB(235, 238, 242)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 16
    lbl.Text = tostring(text)
    lbl.AnchorPoint = Vector2.new(0.5, 0)
    lbl.Position = UDim2.fromScale(0.5, 0.04)
    lbl.Size = UDim2.new(0, 280, 0, 36)
    lbl.Parent = sg
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = lbl

    task.delay(2.8, function()
        if sg then sg:Destroy() end
    end)
end

-- Safer enemy check: if team data is missing, treat as enemy
local function isEnemy(plr)
    if not CONFIG.TeamCheck then return true end
    local myTeam, theirTeam
    pcall(function() myTeam = LocalPlayer and LocalPlayer.Team end)
    pcall(function() theirTeam = plr and plr.Team end)
    if myTeam == nil or theirTeam == nil then
        return true
    end
    return myTeam ~= theirTeam
end

-- Choose a valid aim part with fallbacks for games that rename/don't have Head
local function getAimPart(char)
    if not char then return nil end
    return char:FindFirstChild(CONFIG.LockPartName)
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
end

-- Pick nearest by 3D distance only (no on-screen requirement)
local function getNearest()
    local lp = LocalPlayer
    if not lp then return nil end

    local myChar = lp.Character
    if not myChar then return nil end
    local hrp = myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local myPos = hrp.Position

    local bestPart
    local bestDist

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and isEnemy(plr) then
            local ch = plr.Character
            local aimPart = getAimPart(ch)
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local tHrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if aimPart and hum and hum.Health > 0 and tHrp then
                local dist3D = (tHrp.Position - myPos).Magnitude
                if dist3D <= CONFIG.MaxDistance and (not bestDist or dist3D < bestDist) then
                    bestPart, bestDist = aimPart, dist3D
                end
            end
        end
    end

    return bestPart
end

-- Per-frame steering
local function step()
    if not enabled or not holding then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local target = getNearest()
    if not target then return end

    local from = cam.CFrame.Position
    local desiredDir = (target.Position - from).Unit
    local smooth = tonumber(CONFIG.Smoothness) or 0

    if smooth > 0 then
        local currentDir = cam.CFrame.LookVector
        local lerped = currentDir:Lerp(desiredDir, math.clamp(smooth, 0, 1))
        cam.CFrame = CFrame.new(from, from + lerped)
    else
        cam.CFrame = CFrame.new(from, target.Position)
    end
end

local M = {}

function M.enable()
    if enabled then return end
    enabled = true
    holding = false

    connBegan = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            holding = true
        end
    end)

    connEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            holding = false
        end
    end)

    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_BIND_ID)
    end)
    RunService:BindToRenderStep(RENDER_BIND_ID, 301, step) -- run after default camera updates
end

function M.disable()
    if not enabled then return end
    enabled = false
    holding = false

    if connBegan then connBegan:Disconnect() connBegan = nil end
    if connEnded then connEnded:Disconnect() connEnded = nil end
    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_BIND_ID)
    end)
end

function M.isEnabled()
    return enabled
end

-- Show load confirmation as soon as module runs
notify("Aimbot loaded: true")

return M
