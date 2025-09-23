
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StarterPack = game:GetService("StarterPack")

local LocalPlayer = Players.LocalPlayer


local function getCharacter()
    local c = LocalPlayer.Character
    if c and c.Parent then return c end
    return LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local c = getCharacter()
    return c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local c = getCharacter()
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart")
end

local function hasToolNamed(name)

    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.Name == name then return true end
    end
    local c = LocalPlayer.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t.Name == name then return true end
        end
    end
    return false
end

local function safeEquip(tool)
    local hum = getHumanoid()
    if hum then
        pcall(function() hum:EquipTool(tool) end)
    end
end

local function fireAnyPrompts(root)

    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                if typeof(fireproximityprompt) == "function" then
                    fireproximityprompt(d)
                else

                    d:InputHoldBegin()
                    task.wait(d.HoldDuration or 0.1)
                    d:InputHoldEnd()
                end
            end)
        end
    end
end

local function pickupByTouch(tool)

    local hrp = getHRP()
    local handle = tool and tool:FindFirstChild("Handle")
    if not (hrp and handle) then return false end

    local ok = false
    pcall(function()
        if typeof(firetouchinterest) == "function" then
            firetouchinterest(handle, hrp, 0)
            task.wait(0.05)
            firetouchinterest(handle, hrp, 1)
            ok = true
        end
    end)


    if ok then
        if tool.Parent == LocalPlayer.Backpack or tool.Parent == LocalPlayer.Character then
            return true
        end
    end
    return false
end

local function giveTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if tool.Parent == LocalPlayer.Backpack or tool.Parent == LocalPlayer.Character then return end
    if hasToolNamed(tool.Name) then return end


    fireAnyPrompts(tool)
    if hasToolNamed(tool.Name) or tool.Parent == LocalPlayer.Backpack or tool.Parent == LocalPlayer.Character then return end


    if tool:IsDescendantOf(Workspace) then
        if pickupByTouch(tool) then return end
    end


    local cloned = false
    local ok, err = pcall(function()
        local c = tool:Clone()
        c.Parent = LocalPlayer.Backpack
        cloned = true
    end)

    if not ok then
        warn("[Give-All-Items] Clone failed for", tool:GetFullName(), err)
    end


    if not cloned and tool.Parent ~= LocalPlayer.Backpack then
        pcall(function()
            tool.Parent = LocalPlayer.Backpack
        end)
    end
end

local function scanAndGive(container)
    for _, inst in ipairs(container:GetDescendants()) do
        if inst:IsA("Tool") then
            giveTool(inst)
            task.wait() 
        end
    end
end


scanAndGive(Workspace)
scanAndGive(ReplicatedStorage)
scanAndGive(Lighting)
scanAndGive(StarterPack)


for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
    if t:IsA("Tool") then

        pcall(function()
            safeEquip(t)
            task.wait(0.05)
            t.Parent = LocalPlayer.Backpack
        end)
    end
end


local watchSeconds = 10
local endTime = os.clock() + watchSeconds
local conns = {}

local function onDescAdded(d)
    if d:IsA("Tool") then
        giveTool(d)
    end
end

table.insert(conns, Workspace.DescendantAdded:Connect(onDescAdded))
table.insert(conns, ReplicatedStorage.DescendantAdded:Connect(onDescAdded))
table.insert(conns, Lighting.DescendantAdded:Connect(onDescAdded))


task.spawn(function()
    while os.clock() < endTime do task.wait(0.2) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end)

print("[Give-All-Items] Attempted to add all Tools to your Backpack. Results depend on game protections.")
