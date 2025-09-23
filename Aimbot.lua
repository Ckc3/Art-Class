-- LocalScript for your own place only (training/debug)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local holding = false
local renderConn

local function getTargets()
    local list = {}
    local folder = workspace:FindFirstChild("Targets")
    if not folder then return list end
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Target" then
            table.insert(list, obj)
        end
    end
    return list
end

local function getNearestTarget()
    local camPos = Camera.CFrame.Position
    local best, bestDist = nil, math.huge
    for _, part in ipairs(getTargets()) do
        local d = (part.Position - camPos).Magnitude
        if d < bestDist then
            best, bestDist = part, d
        end
    end
    return best
end

local function step()
    if not holding then return end
    local target = getNearestTarget()
    if not target then return end

    local from = Camera.CFrame.Position
    local currentDir = Camera.CFrame.LookVector
    local desiredDir = (target.Position - from).Unit

    -- Smooth lock (0 = snap; 0.25 is mild smoothing)
    local lerped = currentDir:Lerp(desiredDir, 0.25)
    Camera.CFrame = CFrame.new(from, from + lerped)
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = true
        Camera.CameraType = Enum.CameraType.Scriptable
        if renderConn then renderConn:Disconnect() end
        renderConn = RunService.RenderStepped:Connect(step)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
        Camera.CameraType = Enum.CameraType.Custom
        if renderConn then renderConn:Disconnect() renderConn = nil end
    end
end)
