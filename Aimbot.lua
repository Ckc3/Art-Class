

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera


local MAX_RANGE = 250            
local SMOOTH_ALPHA = 0.25        
local RETARGET_INTERVAL = 0.15   
local AIM_PART_NAME = "Head"     


local aiming = false
local targetPlayer: Player? = nil
local targetPart: BasePart? = nil
local renderConn: RBXScriptConnection? = nil
local retargetAccum = 0

local prevCamType: Enum.CameraType? = nil
local prevCamSubject: Instance? = nil
local camOffsetWorld = Vector3.new(0, 8, -16) 


local function getCharacterParts(player: Player)
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local head = character:FindFirstChild(AIM_PART_NAME) :: BasePart?
    if humanoid and humanoid.Health > 0 and hrp then
        return character, humanoid, hrp, head
    end
    return nil
end

local function isEnemy(player: Player)
    if player == LocalPlayer then return false end

  local lpTeam = LocalPlayer.Team or LocalPlayer.TeamColor
    local opTeam = player.Team or player.TeamColor
    if lpTeam ~= nil and opTeam ~= nil then
        return lpTeam ~= opTeam
    end

  return true
end

local function getNearestEnemy(origin: Vector3)
    local bestDist = math.huge
    local bestPlayer: Player? = nil
    local bestPart: BasePart? = nil

    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local c, hum, hrp, head = getCharacterParts(p)
            if c and hum and hrp then
                local aimPart = head or hrp
                local d = (aimPart.Position - origin).Magnitude
                if d < bestDist and d <= MAX_RANGE then
                    bestDist = d
                    bestPlayer = p
                    bestPart = aimPart
                end
            end
        end
    end

    return bestPlayer, bestPart
end

local function validTarget(p: Player?, part: BasePart?)
    if not p or not part then return false end
    local c, hum, hrp, _ = getCharacterParts(p)
    if not (c and hum and hrp) then return false end

  local localChar = LocalPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not localHRP then return false end
    return (part.Position - localHRP.Position).Magnitude <= MAX_RANGE
end


local function startAiming()
    if aiming then return end

    local c, hum, hrp, _ = getCharacterParts(LocalPlayer)
    if not (c and hum and hrp) then return end

    aiming = true
    retargetAccum = 0


  prevCamType = camera.CameraType
    prevCamSubject = camera.CameraSubject


  camera.CameraType = Enum.CameraType.Scriptable


  local currentPos = camera.CFrame.Position
    camOffsetWorld = currentPos - hrp.Position
    if camOffsetWorld.Magnitude < 1 then
        camOffsetWorld = Vector3.new(0, 8, -16)
    end


  targetPlayer, targetPart = getNearestEnemy(hrp.Position)


  renderConn = RunService.RenderStepped:Connect(function(dt)
        if not aiming then return end

        local lc, lhum, lhrp, _ = getCharacterParts(LocalPlayer)
        if not (lc and lhum and lhrp) then return end


      retargetAccum += dt
        if (not validTarget(targetPlayer, targetPart)) or (retargetAccum >= RETARGET_INTERVAL) then
            targetPlayer, targetPart = getNearestEnemy(lhrp.Position)
            retargetAccum = 0
        end


      local desiredPos = lhrp.Position + camOffsetWorld
        local desiredCF
        if targetPart then
            local targetPos = targetPart.Position
            desiredCF = CFrame.new(desiredPos, targetPos)
        else

        desiredCF = CFrame.new(desiredPos, desiredPos + lhrp.CFrame.LookVector)
        end


      camera.CFrame = camera.CFrame:Lerp(desiredCF, SMOOTH_ALPHA)
    end)
end

local function stopAiming()
    if not aiming then return end
    aiming = false

    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end

    targetPlayer = nil
    targetPart = nil


  if prevCamType then
        camera.CameraType = prevCamType
    else
        camera.CameraType = Enum.CameraType.Custom
    end
    if prevCamSubject then
        camera.CameraSubject = prevCamSubject
    end
end


UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        startAiming()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        stopAiming()
    end
end)


LocalPlayer.CharacterAdded:Connect(function()
    if aiming then
        stopAiming()
    end
end)
