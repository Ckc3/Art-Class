

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local move = {w=false,a=false,s=false,d=false,up=false,down=false}
local baseSpeed = 70

hum.AutoRotate = false

lp.CharacterAdded:Connect(function(c)
	char = c
	hum = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
	hum.AutoRotate = false
	hrp.AssemblyLinearVelocity = Vector3.zero
end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W then move.w = true
	elseif k == Enum.KeyCode.S then move.s = true
	elseif k == Enum.KeyCode.A then move.a = true
	elseif k == Enum.KeyCode.D then move.d = true
	elseif k == Enum.KeyCode.Space then move.up = true
	elseif k == Enum.KeyCode.LeftControl then move.down = true
	end
end)

UIS.InputEnded:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.W then move.w = false
	elseif k == Enum.KeyCode.S then move.s = false
	elseif k == Enum.KeyCode.A then move.a = false
	elseif k == Enum.KeyCode.D then move.d = false
	elseif k == Enum.KeyCode.Space then move.up = false
	elseif k == Enum.KeyCode.LeftControl then move.down = false
	end
end)

-- Apply velocity each frame to hover/fly
RunService.RenderStepped:Connect(function()
	if not hrp then return end

	local cam = workspace.CurrentCamera
	if not cam then return end

	local look = cam.CFrame.LookVector
	local right = cam.CFrame.RightVector

	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatRight = Vector3.new(right.X, 0, right.Z)

	local dir = Vector3.zero
	if move.w then dir += flatLook end
	if move.s then dir -= flatLook end
	if move.a then dir -= flatRight end
	if move.d then dir += flatRight end
	if move.up then dir += Vector3.new(0, 1, 0) end
	if move.down then dir += Vector3.new(0, -1, 0) end
	if dir.Magnitude > 0 then dir = dir.Unit end

	local speed = baseSpeed * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 1.8 or 1)
	local vel = dir * speed

	if not move.up and not move.down then
		vel = Vector3.new(vel.X, 0, vel.Z)
	end

	hrp.AssemblyLinearVelocity = vel
end)
