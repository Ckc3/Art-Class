local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local enabled = false
local holding = false
local connBegan, connEnded

local RENDER_BIND_ID = "RevoltAimbot"

local CONFIG = {
    MaxDistance = 600,          -- studs limit to consider a target
    LockPartName = "Head",     -- preferred aim part
    TeamCheck = false,          -- set true if you want to avoid teammates
    Smoothness = 0.25,          -- 0 = snap, 0.05..0.4 = smooth
    MaxFovPx = 600,             -- max pixels from crosshair to lock (2D screen distance)
}

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

-- Pick nearest target by on-screen distance to crosshair within distance + FOV gates
local function getNearest()
    local lp = LocalPlayer
    local cam = workspace.CurrentCamera
    if not lp or not cam then return nil end

    local myChar = lp.Character
    if not myChar then return nil end
    local hrp = myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local myPos = hrp.Position
    local screenCenter = cam and cam.ViewportSize and (cam.ViewportSize / 2) or Vector2.new(512, 300)

    local bestPart
    local bestScore -- lower is better (2D distance)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and isEnemy(plr) then
            local ch = plr.Character
            local aimPart = getAimPart(ch)
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local tHrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if aimPart and hum and hum.Health > 0 and tHrp then
                local dist3D = (tHrp.Position - myPos).Magnitude
                if dist3D <= CONFIG.MaxDistance then
                    local v, onScreen = cam:WorldToViewportPoint(aimPart.Position)
                    if onScreen and v.Z > 0 then
                        local pos2D = Vector2.new(v.X, v.Y)
                        local d2 = (pos2D - screenCenter).Magnitude
                        if d2 <= CONFIG.MaxFovPx and (not bestScore or d2 < bestScore) then
                            bestPart, bestScore = aimPart, d2
                        end
                    end
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

    -- Do not ignore GPE for RMB so UI captures don't block us
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

    -- Use BindToRenderStep so we can set priority after camera
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

return M
