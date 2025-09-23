local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local enabled = false
local holding = false
local connStepped, connBegan, connEnded

local CONFIG = {
    MaxDistance = 250,         
    LockPartName = "Head",     
    TeamCheck = true,          
    Smoothness = 0.25,         
}

local function isEnemy(plr)
    if not CONFIG.TeamCheck then return true end
    local ok = pcall(function() return plr.Team, LocalPlayer.Team end)
    if not ok then return true end
    return plr.Team ~= LocalPlayer.Team
end

local function getNearest()
    local myChar = LocalPlayer and LocalPlayer.Character
    if not myChar then return end
    local hrp = myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myPos = hrp.Position
    local best, bestDist

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemy(plr) then
            local ch = plr.Character
            local part = ch and ch:FindFirstChild(CONFIG.LockPartName)
            local tHrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if part and tHrp and hum and hum.Health > 0 then
                local d = (tHrp.Position - myPos).Magnitude
                if d <= CONFIG.MaxDistance and (not bestDist or d < bestDist) then
                    best, bestDist = part, d
                end
            end
        end
    end
    return best
end

local function step()
    if not holding then return end
    local target = getNearest()
    if not target then return end

    local cam = Camera
    local from = cam.CFrame.Position
    local desired = (target.Position - from).Unit
    if CONFIG.Smoothness and CONFIG.Smoothness > 0 then
        local current = cam.CFrame.LookVector
        local lerped = current:Lerp(desired, math.clamp(CONFIG.Smoothness, 0, 1))
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

    connBegan = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            holding = true
        end
    end)

    connEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            holding = false
        end
    end)

    connStepped = RunService.RenderStepped:Connect(step)
end

function M.disable()
    if not enabled then return end
    enabled = false
    holding = false
    if connStepped then connStepped:Disconnect() connStepped = nil end
    if connBegan then connBegan:Disconnect() connBegan = nil end
    if connEnded then connEnded:Disconnect() connEnded = nil end
end

function M.isEnabled() return enabled end
return M
