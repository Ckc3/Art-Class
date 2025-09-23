-- Right-click hold aimbot for Roblox
-- Locks onto nearest alive player while RMB is held

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local holding = false

-- Config
local MaxDistance = 800          -- studs limit (3D distance)
local AimPartName = "Head"       -- preferred aim part ("Head", "UpperTorso", etc.)
local Smoothness = 0.25          -- 0 = snap, 0.05..0.4 = smooth

-- Simple notification helper
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = "Aimbot", Text = text, Duration = 3})
    end)
end

local function getAimPart(char)
    if not char then return nil end
    return char:FindFirstChild(AimPartName)
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
end

local function getNearest()
    local lp = LocalPlayer
    if not lp then return nil end

    local myChar = lp.Character
    if not myChar then return nil end
    local hrp = myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local myPos = hrp.Position
    local bestPart, bestDist

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local ch = plr.Character
            local aimPart = getAimPart(ch)
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local tHrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if aimPart and hum and hum.Health > 0 and tHrp then
                local dist3D = (tHrp.Position - myPos).Magnitude
                if dist3D <= MaxDistance and (not bestDist or dist3D < bestDist) then
                    bestPart, bestDist = aimPart, dist3D
                end
            end
        end
    end

    return bestPart
end

-- Input handling: hold RMB to aim, release to stop
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
    end
end)

-- Per-frame aiming while holding
local BIND_ID = "RightClickAimbot"
pcall(function() RunService:UnbindFromRenderStep(BIND_ID) end)
RunService:BindToRenderStep(BIND_ID, 301, function()
    if not holding then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local target = getNearest()
    if not target then return end

    local from = cam.CFrame.Position
    local desiredDir = (target.Position - from).Unit

    if Smoothness and Smoothness > 0 then
        local currentDir = cam.CFrame.LookVector
        local lerped = currentDir:Lerp(desiredDir, math.clamp(Smoothness, 0, 1))
        cam.CFrame = CFrame.new(from, from + lerped)
    else
        cam.CFrame = CFrame.new(from, target.Position)
    end
end)

notify("Aimbot loaded. Hold RMB to lock; release to unlock.")
