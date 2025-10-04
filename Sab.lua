
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")


local function create(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    for _, child in ipairs(children or {}) do child.Parent = obj end
    return obj
end


local colors = {
    window = Color3.fromRGB(25, 27, 31),
    topbar = Color3.fromRGB(20, 22, 26),
    text = Color3.fromRGB(235, 240, 255),
    muted = Color3.fromRGB(170, 180, 200),
    stroke = Color3.fromRGB(255, 255, 255),
    button = Color3.fromRGB(35, 37, 41)
}


local screenGui = create("ScreenGui", {
    Name = "StealABrainRotGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local mainFrame = create("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.3, 0.4),
    BackgroundColor3 = colors.window,
    BackgroundTransparency = 0,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 12) }),
    create("UIStroke", {
        Color = colors.stroke,
        Transparency = 0.86,
        Thickness = 1.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
})


local topBar = create("Frame", {
    Name = "TopBar",
    BackgroundColor3 = colors.topbar,
    Size = UDim2.new(1, 0, 0, 40)
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 12) }),
    create("UIStroke", { Color = colors.stroke, Transparency = 0.9, Thickness = 1 })
})
topBar.Parent = mainFrame

local title = create("TextLabel", {
    Name = "Title",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 0),
    Size = UDim2.new(1, -28, 1, 0),
    Font = Enum.Font.GothamSemibold,
    Text = "Steal a Brain Rot",
    TextSize = 16,
    TextColor3 = colors.text,
    TextXAlignment = Enum.TextXAlignment.Center
})
title.Parent = topBar


local content = create("Frame", {
    Position = UDim2.new(0, 0, 0, 40),
    Size = UDim2.new(1, 0, 1, -40),
    BackgroundTransparency = 1
}, {
    create("UIListLayout", {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }),
    create("UIPadding", { PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15) })
})
content.Parent = mainFrame


local noclipBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = colors.button,
    Text = "Enable Go Through Walls (Noclip)",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = colors.text,
    AutoButtonColor = true
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = colors.stroke, Transparency = 0.85, Thickness = 1 })
})
noclipBtn.Parent = content

local laserBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = colors.button,
    Text = "Bypass Lasers",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = colors.text,
    AutoButtonColor = true
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = colors.stroke, Transparency = 0.85, Thickness = 1 })
})
laserBtn.Parent = content


local function mountTopMost(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    local parented = false
    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if hui then gui.Parent = hui; parented = true end
        end
    end)
    if not parented then
        pcall(function()
            gui.Parent = game:GetService("CoreGui")
            parented = true
        end)
    end
    if not parented then
        gui.Parent = playerGui
    end
end

mountTopMost(screenGui)
mainFrame.Parent = screenGui


do
    local dragging = false
    local dragInput, dragStart, startPos

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end

    local function onInputChanged(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end

    local function onGlobalInputChanged(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end

    topBar.InputBegan:Connect(onInputBegan)
    topBar.InputChanged:Connect(onInputChanged)
    UserInputService.InputChanged:Connect(onGlobalInputChanged)
end


local noclipEnabled = false
local bodyVelocity

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "Disable Go Through Walls (Noclip)" or "Enable Go Through Walls (Noclip)"
    noclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 150, 0) or colors.button

    if noclipEnabled then
        if not LocalPlayer.Character then return end
        Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        Humanoid.PlatformStand = true
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart

        while noclipEnabled and LocalPlayer.Character and Humanoid do
            task.wait()
            if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
            local moveDirection = Humanoid.MoveDirection
            bodyVelocity.Velocity = moveDirection * 50  -- Adjust speed as needed
        end
    else
        if bodyVelocity then bodyVelocity:Destroy() end
        if Humanoid then Humanoid.PlatformStand = false end
    end
end)


local lasersBypassed = false

laserBtn.MouseButton1Click:Connect(function()
    lasersBypassed = not lasersBypassed
    laserBtn.Text = lasersBypassed and "Disable Bypass Lasers" or "Bypass Lasers"
    laserBtn.BackgroundColor3 = lasersBypassed and Color3.fromRGB(0, 150, 0) or colors.button

    if lasersBypassed then

        local workspace = game:GetService("Workspace")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (string.find(obj.Name:lower(), "laser") or obj.Name == "Laser") then
                obj.CanCollide = false
                obj.Transparency = 0.5  
            end
        end


        task.spawn(function()
            while lasersBypassed do
                task.wait(1)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (string.find(obj.Name:lower(), "laser") or obj.Name == "Laser") and obj.CanCollide then
                        obj.CanCollide = false
                        obj.Transparency = 0.5
                    end
                end
            end
        end)
    else

        local workspace = game:GetService("Workspace")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (string.find(obj.Name:lower(), "laser") or obj.Name == "Laser") then
                obj.CanCollide = true
                obj.Transparency = 0  -- Reset
            end
        end
    end
end)


LocalPlayer.CharacterAdded:Connect(function(character)
    if noclipEnabled then
        task.wait(1)  
        Humanoid = character:FindFirstChild("Humanoid")
        if Humanoid then
            Humanoid.PlatformStand = true
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyVelocity.Parent = character.HumanoidRootPart
        end
    end
end)
