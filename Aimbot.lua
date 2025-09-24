
local INCLUDE_PLAYERS = true
local INCLUDE_NPCS = false             
local MAX_DISTANCE = 1500              
local REQUIRE_LINE_OF_SIGHT = false    
local SMOOTHNESS = 0.25               
local HEAD_OFFSET = Vector3.new(0, 0.1, 0)
local MAX_FOV_DEG = 20                 


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera


local function getCharacter(player)
    return player and player.Character or nil
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid") or nil
end

local function getHead(model)
    return model and model:FindFirstChild("Head") or nil
end

local function getRoot(model)
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

local function isPlayerCharacter(model)
    if not model or not model:IsA("Model") then return false end
    local hum = getHumanoid(model)
    if not hum then return false end
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function isAlive(model)
    local hum = getHumanoid(model)
    return hum and hum.Health > 0 and hum.Parent ~= nil
end

local function getLocalRoot()
    local char = getCharacter(LocalPlayer)
    return char and getRoot(char)
end

local function distance(a, b)
    return (a - b).Magnitude
end


local function hasLineOfSight(fromPos, toPart)
    if not toPart or not toPart:IsA("BasePart") then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local blacklist = {}

    local myChar = getCharacter(LocalPlayer)
    if myChar then table.insert(blacklist, myChar) end
    if toPart.Parent then table.insert(blacklist, toPart.Parent) end

    params.FilterDescendantsInstances = blacklist
    local result = Workspace:Raycast(fromPos, (toPart.Position - fromPos), params)
    return result == nil
end


local npcs = {}

local function tryAddNPC(model)
    if not INCLUDE_NPCS then return end
    if not model or not model:IsA("Model") then return end
    if isPlayerCharacter(model) then return end
    if getHumanoid(model) then
        npcs[model] = true
    end
end

local function removeNPC(model)
    if npcs[model] then npcs[model] = nil end
end

for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("Model") then
        tryAddNPC(d)
    end
end

local conns = {}
table.insert(conns, Workspace.DescendantAdded:Connect(function(d)
    if d:IsA("Model") then
        tryAddNPC(d)
    end
end))
table.insert(conns, Workspace.DescendantRemoving:Connect(function(d)
    if d:IsA("Model") then
        removeNPC(d)
    end
end))


local function validTargetModel(model)
    if not model or not model:IsA("Model") then return false end
    if not isAlive(model) then return false end
    local head = getHead(model)
    return head ~= nil
end


local function findNearestTarget()
    local myRoot = getLocalRoot()
    if not myRoot then return nil end

    local cam = CurrentCamera
    local camPos = cam.CFrame.Position
    local camLook = cam.CFrame.LookVector

    local bestModel = nil
    local bestAngle = math.huge

    local function consider(model)
        if not validTargetModel(model) then return end

        local head = getHead(model)
        local root = getRoot(model)
        if not head or not root then return end


		local d = distance(myRoot.Position, root.Position)
        if d > MAX_DISTANCE then return end


		local dir = (head.Position - camPos).Unit
        local cosTheta = math.clamp(dir:Dot(camLook), -1, 1)
        local angleDeg = math.deg(math.acos(cosTheta))

        if angleDeg <= MAX_FOV_DEG and (not REQUIRE_LINE_OF_SIGHT or hasLineOfSight(camPos, head)) then

			if angleDeg < bestAngle then
                bestModel = model
                bestAngle = angleDeg
            elseif angleDeg == bestAngle and bestModel ~= nil then
                local curRoot = getRoot(bestModel)
                if curRoot and d < distance(myRoot.Position, curRoot.Position) then
                    bestModel = model
                end
            end
        end
    end

    if INCLUDE_PLAYERS then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                consider(getCharacter(p)) 
            end
        end
    end

    if INCLUDE_NPCS then
        for model in pairs(npcs) do
            consider(model)
        end
    end

    return bestModel
end

local function isModelValid(model)
    return model and model.Parent and validTargetModel(model)
end


local locking = false
local currentTarget = nil
local prevCamType = nil
local prevCamSubject = nil
local renderConn = nil

local function unlock()
    locking = false
    currentTarget = nil
    if renderConn then renderConn:Disconnect() end
    renderConn = nil

    if prevCamType ~= nil then
        CurrentCamera.CameraType = prevCamType
        prevCamType = nil
    end
    if prevCamSubject ~= nil then
        CurrentCamera.CameraSubject = prevCamSubject
        prevCamSubject = nil
    end
end

local function updateAim()
    if not locking then return end

    if not isModelValid(currentTarget) then
        currentTarget = findNearestTarget()
        if not currentTarget then
            unlock()
            return
        end
    end

    local head = getHead(currentTarget)
    if not head then
        unlock()
        return
    end

    local cam = CurrentCamera
    local desired = CFrame.new(cam.CFrame.Position, head.Position + HEAD_OFFSET)
    cam.CFrame = cam.CFrame:Lerp(desired, SMOOTHNESS)
end

local function lockOn()
    currentTarget = findNearestTarget()
    if not currentTarget then return end
    locking = true

    prevCamType = CurrentCamera.CameraType
    prevCamSubject = CurrentCamera.CameraSubject
    CurrentCamera.CameraType = Enum.CameraType.Scriptable

    renderConn = RunService.RenderStepped:Connect(updateAim)
end


UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if locking then
            unlock()
        else
            lockOn()
        end
    end
end)


table.insert(conns, Players.PlayerRemoving:Connect(function()
    unlock()
end))
table.insert(conns, LocalPlayer.CharacterRemoving:Connect(function()
    unlock()
end))
