loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/GotoPunch/refs/heads/main/punch.lua'),true))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/emotes/refs/heads/main/tuffemotes.lua'),true))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/mutebutton/refs/heads/main/mutebutton.lua'),true))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Safe UI Parent 
local function getSafeParent()
    local success, parent = pcall(function() return game:GetService("CoreGui") end)
    if success and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local safeUIParent = getSafeParent()

-- Rayfield Initialization
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Velq Utility | Universal",
    LoadingTitle = "Initializing Velq...",
    LoadingSubtitle = "Universal Edition V42",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "VelqConfig",
        FileName = "VelqUniversalSave"
    },
    Discord = {
        Enabled = true,
        Invite = "TXGHHaYDdJ",
        RememberJoins = true 
    },
    KeySystem = false,
})

if LocalPlayer.Name == "HeavenlyReminiscence" then
    Rayfield:Notify({
        Title = "Welcome back, Master",
        Content = "<font color='yellow'>HeavenlyReminiscence</font> recognized. Velq Astral Online.",
        Duration = 5,
        Image = 4483362458,
    })
end

-- ==========================================
-- STATE VARIABLES
-- ==========================================
local uiVisible = true

-- Movement Hacks
local wsEnabled = false
local customWS = 16
local jpEnabled = false
local customJP = 50
local infJumpEnabled = false
local flyEnabled = false
local flySpeed = 50
local floatEnabled = false
local noclipEnabled = false
local playerSpinEnabled = false
local playerSpinSpeed = 15
local customGravity = workspace.Gravity
local gravityEnabled = false
local blinkEnabled = false
local blinkDistance = 50
local airWalkEnabled = false
local airWalkY = nil

-- Ghost Mode
local ghostModeEnabled = false
local ghostClone = nil

-- Advanced Teleport
local selectedTpPlayer = nil
local tpMode = "Behind"
local loopTpEnabled = false
local ctrlClickTpEnabled = false

-- Friends Sniper
local onlineFriends = {}
local selectedFriend = nil

-- BHOP Variables
local bhopEnabled = false
local bhopBaseSpeed = 16
local bhopSpeedCap = 40
local bhopDecelRate = 50
local bhopCurrSpeed = 16
local bhopSliding = false
local bhopLastHzSpeed = 0
local bhopLastDir = Vector3.new(0,0,0)
local bhopJumpConnection = nil

local jumpBoostWeights = {[2.3] = 30, [2.4] = 30, [2.5] = 30, [2.6] = 5, [2.7] = 5}
local weightedJumpBoosts = {}
for boost, weight in pairs(jumpBoostWeights) do
    for i=1, weight do table.insert(weightedJumpBoosts, boost) end
end

-- Water Walk Variables
local waterWalkEnabled = false
local waterPlatform = nil
local waterRaycastParams = RaycastParams.new()
waterRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
waterRaycastParams.IgnoreWater = false

-- Tall R15 Variables
local tallEnabled = false
local tallWalkTrack, tallIdleTrack
local tallAnimSet = {idle = "rbxassetid://87574253549013", walk = "rbxassetid://128769966446762"}
local origWS, origJP, origJH, origUJP = 16, 50, 7.2, true
local tallRunningConn = nil

-- Exploit Hacks
local godModeEnabled = false
local godModeConnection = nil
local antiVoidEnabled = false
local antiVoidCatchOffset = 20
local antiVoidTPHeight = 50

-- Combat Hacks
local aimbotEnabled = false
local aimbotSmoothness = 1
local hitboxExpanderEnabled = false
local hitboxSize = 2
local isHoldingRMB = false
local flingTargetPlayer = nil
local flingEnabled = false

-- Visuals & ESP
local espEnabled = false
local chamsEnabled = false
local tracersEnabled = false
local noFogBlurEnabled = false
local mapXrayEnabled = false
local originalPartTransparencies = {}
local espObjects = {} 
local tracerBeams = {}

-- Utilities
local timeCycleEnabled = false
local timeCycleSpeed = 1
local fullBrightEnabled = false
local antiAfkEnabled = false
local chatLoggerEnabled = false
local clickDeleteEnabled = false

-- Internal Variables
local floatBody = nil
local flyBV, flyBG
local inputW, inputA, inputS, inputD, inputSpace, inputCtrl = false, false, false, false, false, false

local airWalkPart = Instance.new("Part")
airWalkPart.Size = Vector3.new(10, 1, 10)
airWalkPart.Anchored = true
airWalkPart.Transparency = 0.5
airWalkPart.Color = Color3.fromRGB(138, 43, 226)
airWalkPart.Material = Enum.Material.ForceField
airWalkPart.CanCollide = true
airWalkPart.Name = "VelqAirWalk"

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================

local function hookChat(player)
    player.Chatted:Connect(function(msg)
        if chatLoggerEnabled then
            Rayfield:Notify({Title = player.DisplayName, Content = msg, Duration = 4})
        end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
Players.PlayerAdded:Connect(hookChat)

-- ESP & Chams & Tracers System
local function getTracerColor(plr)
    if plr.Team then return plr.TeamColor.Color end
    math.randomseed(plr.UserId % 100000)
    return Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
end

local function removeTracer(plr)
    if tracerBeams[plr] then
        if tracerBeams[plr].beam then tracerBeams[plr].beam:Destroy() end
        if tracerBeams[plr].a0 then tracerBeams[plr].a0:Destroy() end
        if tracerBeams[plr].a1 then tracerBeams[plr].a1:Destroy() end
        tracerBeams[plr] = nil
    end
end

local function addTracer(plr)
    if plr == LocalPlayer or tracerBeams[plr] then return end
    local lpChar = LocalPlayer.Character
    local lpRoot = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    local targetChar = plr.Character 
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if not (lpRoot and targetRoot) then return end

    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.new(0, -1, 0)
    a0.Parent = lpRoot

    local a1 = Instance.new("Attachment")
    a1.Parent = targetRoot

    local beam = Instance.new("Beam")
    beam.FaceCamera = true
    beam.Width0 = 0.05
    beam.Width1 = 0.15
    beam.Color = ColorSequence.new(getTracerColor(plr))
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 0.2) 
    })
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Parent = lpRoot

    tracerBeams[plr] = {beam = beam, a0 = a0, a1 = a1}
end

local function createESP(player)
    if player == LocalPlayer then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_ESP"
    billboard.Size = UDim2.new(0, 200, 0, 65)
    billboard.StudsOffset = Vector3.new(0, 3, 0) 
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = safeUIParent

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
    nameLabel.Font = Enum.Font.Code
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 14

    local healthLabel = Instance.new("TextLabel", billboard)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Size = UDim2.new(1, 0, 0.33, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.33, 0)
    healthLabel.Font = Enum.Font.Code
    healthLabel.Text = "HP: 100"
    healthLabel.TextColor3 = Color3.new(0, 1, 0)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextSize = 12
    
    local distLabel = Instance.new("TextLabel", billboard)
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0.33, 0)
    distLabel.Position = UDim2.new(0, 0, 0.66, 0)
    distLabel.Font = Enum.Font.Code
    distLabel.Text = "Dist: 0"
    distLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextSize = 12

    local cham = Instance.new("Highlight")
    cham.FillColor = Color3.fromRGB(255, 0, 0)
    cham.OutlineColor = Color3.fromRGB(255, 255, 255)
    cham.FillTransparency = 0.5
    cham.OutlineTransparency = 0
    cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    cham.Enabled = false
    cham.Parent = safeUIParent

    espObjects[player] = {Billboard = billboard, NameLabel = nameLabel, HealthLabel = healthLabel, DistLabel = distLabel, Cham = cham}
    if tracersEnabled then addTracer(player) end
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].Billboard:Destroy()
        espObjects[player].Cham:Destroy()
        espObjects[player] = nil
    end
    removeTracer(player)
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- Tall Animations
local function applyTallAnimations(char)
    local hum = char:WaitForChild("Humanoid")
    if origWS == 16 then
        origWS = hum.WalkSpeed
        origJP = hum.JumpPower
        origJH = hum.JumpHeight
        origUJP = hum.UseJumpPower
    end

    if tallWalkTrack then tallWalkTrack:Stop() end
    if tallIdleTrack then tallIdleTrack:Stop() end
    if tallRunningConn then tallRunningConn:Disconnect() end

    hum.WalkSpeed = 34
    hum.UseJumpPower = true
    hum.JumpPower = 75
    hum.JumpHeight = 7.2

    local walkAnim = Instance.new("Animation")
    walkAnim.AnimationId = tallAnimSet.walk
    tallWalkTrack = hum:LoadAnimation(walkAnim)
    tallWalkTrack.Looped = true

    local idleAnim = Instance.new("Animation")
    idleAnim.AnimationId = tallAnimSet.idle
    tallIdleTrack = hum:LoadAnimation(idleAnim)
    tallIdleTrack.Looped = true

    tallRunningConn = hum.Running:Connect(function(speedVal)
        if speedVal > 0 then
            tallIdleTrack:Stop()
            if not tallWalkTrack.IsPlaying then tallWalkTrack:Play() end
        else
            tallWalkTrack:Stop()
            if not tallIdleTrack.IsPlaying then tallIdleTrack:Play() end
        end
    end)
    tallIdleTrack:Play()
end

local function revertTallAnimations(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if tallWalkTrack then tallWalkTrack:Stop() tallWalkTrack = nil end
    if tallIdleTrack then tallIdleTrack:Stop() tallIdleTrack = nil end
    if tallRunningConn then tallRunningConn:Disconnect() tallRunningConn = nil end
    hum.WalkSpeed = origWS
    hum.JumpPower = origJP
    hum.JumpHeight = origJH
    hum.UseJumpPower = origUJP
end

-- BHOP Jump Hook
local function hookBhopJump(char)
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    if bhopJumpConnection then bhopJumpConnection:Disconnect() end
    bhopJumpConnection = hum.Jumping:Connect(function()
        if not bhopEnabled then return end
        local origProps = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        local chosenBoost = weightedJumpBoosts[math.random(1,#weightedJumpBoosts)]
        bhopCurrSpeed = math.min(bhopCurrSpeed + chosenBoost, bhopSpeedCap)
        hum.WalkSpeed = bhopCurrSpeed
        bhopSliding = false
        hrp.CustomPhysicalProperties = origProps

        local airAccel = 25
        local horizVel = hrp.Velocity * Vector3.new(1,0,1)
        if hum.MoveDirection.Magnitude > 0 then
            local wishDir = hum.MoveDirection.Unit
            local projSpeed = horizVel:Dot(wishDir)
            local addSpeed = airAccel - projSpeed
            if addSpeed > 0 then
                local accelSpeed = math.min(addSpeed, airAccel)
                horizVel = horizVel + wishDir * accelSpeed
            end
            hrp.Velocity = Vector3.new(horizVel.X, hrp.Velocity.Y, horizVel.Z)
        end
    end)
end

-- God Mode
local function applyGodMode(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 3)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        if godModeConnection then godModeConnection:Disconnect() end
        godModeConnection = RunService.Heartbeat:Connect(function()
            if humanoid and humanoid.Parent and humanoid.Health > 0 then
                humanoid.MaxHealth = math.huge
                humanoid.Health = math.huge
            end
        end)
    end
end

local function disableGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

-- Float & Fly
local function toggleFloat()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if floatEnabled and hrp then
        if not floatBody then
            floatBody = Instance.new("BodyVelocity")
            floatBody.Velocity = Vector3.new(0, 0, 0)
            floatBody.MaxForce = Vector3.new(0, math.huge, 0)
            floatBody.Parent = hrp
        end
    else
        if floatBody then floatBody:Destroy(); floatBody = nil end
    end
end

local function toggleFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyEnabled then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P = 9000
        flyBG.D = 500
        flyBG.CFrame = workspace.CurrentCamera.CFrame
        flyBG.Parent = hrp
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if ghostModeEnabled then ghostModeEnabled = false end -- Reset ghost mode on death
    if flyEnabled then toggleFly() end
    if floatEnabled then toggleFloat() end
    if godModeEnabled then applyGodMode(char) end
    if tallEnabled then applyTallAnimations(char) end
    if bhopEnabled then hookBhopJump(char) end
    if tracersEnabled then 
        for _, p in pairs(Players:GetPlayers()) do addTracer(p) end 
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK Logic
LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Aimbot Target Finder
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPlayer = p
                end
            end
        end
    end
    return closestPlayer
end

local function ServerHop()
    Rayfield:Notify({Title = "Server Hop", Content = "Searching for a new universe...", Duration = 3})
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in ipairs(servers.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            break
        end
    end
end

-- ==========================================
-- GUI CREATION
-- ==========================================

local LocalPlayerTab = Window:CreateTab("Player", 4483362875)
local CombatTab = Window:CreateTab("Combat", 4483345998)
local VisualsTab = Window:CreateTab("Visuals", 4483362875) 
local FriendsTab = Window:CreateTab("Friends", 4483362458)
local UtilsTab = Window:CreateTab("Utilities", 4483345998)

-- ==== ADVANCED TELEPORT SECTION ====
local AdvTpSection = LocalPlayerTab:CreateSection("Advanced Teleportation")

local tpDropdown = LocalPlayerTab:CreateDropdown({
    Name = "Select Player Target",
    Options = {"None"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "TpPlayerDropdown",
    Callback = function(Option)
        local targetName = Option[1]
        selectedTpPlayer = Players:FindFirstChild(targetName)
    end,
})

local function updateTpDropdown()
    local pNames = {"None"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(pNames, p.Name) end
    end
    tpDropdown:Refresh(pNames)
end
Players.PlayerAdded:Connect(updateTpDropdown)
Players.PlayerRemoving:Connect(updateTpDropdown)
updateTpDropdown()

LocalPlayerTab:CreateDropdown({
    Name = "Teleport Position",
    Options = {"Directly On Target", "Behind Target", "Above Target"},
    CurrentOption = {"Behind Target"},
    MultipleOptions = false,
    Flag = "TpModeDropdown",
    Callback = function(Option) tpMode = Option[1] end
})

LocalPlayerTab:CreateButton({
    Name = "Teleport Now",
    Callback = function()
        if selectedTpPlayer and selectedTpPlayer.Character and selectedTpPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHrp = selectedTpPlayer.Character.HumanoidRootPart
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                if tpMode == "Directly On Target" then myHrp.CFrame = targetHrp.CFrame
                elseif tpMode == "Behind Target" then myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 4)
                elseif tpMode == "Above Target" then myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 6, 0)
                end
                Rayfield:Notify({Title="Teleported", Content="Warped to " .. selectedTpPlayer.DisplayName, Duration=2})
            end
        else
            Rayfield:Notify({Title="Error", Content="Target not found or dead.", Duration=2})
        end
    end
})

LocalPlayerTab:CreateToggle({ Name = "Loop Teleport (Stick to Player)", CurrentValue = false, Flag = "LoopTpToggle", Callback = function(Value) loopTpEnabled = Value end})
LocalPlayerTab:CreateToggle({ Name = "Ctrl + Click Teleport (Map Traversal)", CurrentValue = false, Flag = "CtrlClickTpToggle", Callback = function(Value) ctrlClickTpEnabled = Value end})

-- ==== PLAYER MOVEMENT ====
local MovementSection = LocalPlayerTab:CreateSection("Movement & Modifiers")
LocalPlayerTab:CreateToggle({ Name = "Astral Projection (Ghost Mode)", CurrentValue = false, Flag = "GhostToggle", Callback = function(Value) 
    ghostModeEnabled = Value 
    local char = LocalPlayer.Character
    if not char then return end

    if Value then
        char.Archivable = true
        ghostClone = char:Clone()
        ghostClone.Name = LocalPlayer.Name .. "_FakeBody"
        
        for _, v in pairs(ghostClone:GetDescendants()) do
            if v:IsA("BasePart") then v.Anchored = true end
            if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
        end
        ghostClone.Parent = workspace

        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                if v.Name ~= "HumanoidRootPart" then v.Transparency = 0.5 end
            end
        end
        Rayfield:Notify({Title="Astral Projection", Content="Ghost mode active. Your physical body was left behind.", Duration=3})
    else
        if ghostClone then ghostClone:Destroy(); ghostClone = nil end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                if v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
            end
        end
        Rayfield:Notify({Title="Astral Returned", Content="Teleported physical body to ghost location.", Duration=3})
    end
end})

LocalPlayerTab:CreateToggle({ Name = "Bunny Hop (BHOP)", CurrentValue = false, Flag = "BhopToggle", Callback = function(Value) 
    bhopEnabled = Value 
    if Value and LocalPlayer.Character then hookBhopJump(LocalPlayer.Character) end
end})
LocalPlayerTab:CreateToggle({ Name = "Water Walk", CurrentValue = false, Flag = "WaterWalkToggle", Callback = function(Value) 
    waterWalkEnabled = Value 
    if not Value and waterPlatform then waterPlatform:Destroy(); waterPlatform = nil end
end})
LocalPlayerTab:CreateToggle({ Name = "Tall Animations (R15)", CurrentValue = false, Flag = "TallToggle", Callback = function(Value) 
    tallEnabled = Value
    if Value and LocalPlayer.Character then applyTallAnimations(LocalPlayer.Character)
    elseif LocalPlayer.Character then revertTallAnimations(LocalPlayer.Character) end
end})
LocalPlayerTab:CreateToggle({ Name = "Speed Hack", CurrentValue = false, Flag = "WSEnableToggle", Callback = function(Value) wsEnabled = Value end})
LocalPlayerTab:CreateSlider({ Name = "WalkSpeed", Range = {1, 500}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "WSSlider", Callback = function(Value) customWS = Value end})
LocalPlayerTab:CreateToggle({ Name = "High Jump", CurrentValue = false, Flag = "JPEnableToggle", Callback = function(Value) jpEnabled = Value end})
LocalPlayerTab:CreateSlider({ Name = "JumpPower", Range = {1, 500}, Increment = 1, Suffix = "Power", CurrentValue = 50, Flag = "JPSlider", Callback = function(Value) customJP = Value end})
LocalPlayerTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "InfJumpToggle", Callback = function(Value) infJumpEnabled = Value end})
LocalPlayerTab:CreateToggle({ Name = "Gravity Modifier", CurrentValue = false, Flag = "GravToggle", Callback = function(Value) gravityEnabled = Value if not Value then workspace.Gravity = 196.2 end end})
LocalPlayerTab:CreateSlider({ Name = "Gravity Level", Range = {0, 500}, Increment = 1, Suffix = "Force", CurrentValue = 196, Flag = "GravSlider", Callback = function(Value) customGravity = Value end})
LocalPlayerTab:CreateToggle({ Name = "Hover Fly Mode", CurrentValue = false, Flag = "FlyToggle", Callback = function(Value) flyEnabled = Value; toggleFly() end})
LocalPlayerTab:CreateSlider({ Name = "Fly Speed", Range = {10, 200}, Increment = 5, Suffix = "Speed", CurrentValue = 50, Flag = "FlySpeedSlider", Callback = function(Value) flySpeed = Value end})
LocalPlayerTab:CreateToggle({ Name = "Float Mode", CurrentValue = false, Flag = "FloatToggle", Callback = function(Value) floatEnabled = Value; toggleFloat() end})
LocalPlayerTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Flag = "NoclipToggle", Callback = function(Value) noclipEnabled = Value end})
LocalPlayerTab:CreateToggle({ Name = "Player Spin (Tornado)", CurrentValue = false, Flag = "SpinToggle", Callback = function(Value) playerSpinEnabled = Value end})
LocalPlayerTab:CreateSlider({ Name = "Spin Speed", Range = {1, 100}, Increment = 1, Suffix = "deg/f", CurrentValue = 15, Flag = "SpinSlider", Callback = function(Value) playerSpinSpeed = Value end})

local ExploitSection = LocalPlayerTab:CreateSection("Exploits")
LocalPlayerTab:CreateToggle({ Name = "God Mode (Infinite Health)", CurrentValue = false, Flag = "GodModeToggle", Callback = function(Value) 
    godModeEnabled = Value 
    if Value then applyGodMode(LocalPlayer.Character) else disableGodMode() end 
end})
LocalPlayerTab:CreateToggle({ Name = "Anti-Void Rescue (Auto-Catch)", CurrentValue = false, Flag = "AntiVoidToggle", Callback = function(Value) antiVoidEnabled = Value end})
LocalPlayerTab:CreateSlider({ Name = "Anti-Void Catch Threshold", Range = {0, 100}, Increment = 5, Suffix = "Studs", CurrentValue = 20, Flag = "AVOffsetSlider", Callback = function(Value) antiVoidCatchOffset = Value end})
LocalPlayerTab:CreateSlider({ Name = "Anti-Void Teleport Height", Range = {10, 500}, Increment = 10, Suffix = "Studs", CurrentValue = 50, Flag = "AVHeightSlider", Callback = function(Value) antiVoidTPHeight = Value end})
LocalPlayerTab:CreateToggle({ Name = "Air Walk (Jesus Platform)", CurrentValue = false, Flag = "AirWalkToggle", Callback = function(Value) airWalkEnabled = Value end})
LocalPlayerTab:CreateToggle({ Name = "Blink Dash [Press Q]", CurrentValue = false, Flag = "BlinkToggle", Callback = function(Value) blinkEnabled = Value end})
LocalPlayerTab:CreateSlider({ Name = "Blink Distance", Range = {10, 300}, Increment = 10, Suffix = "Studs", CurrentValue = 50, Flag = "BlinkSlider", Callback = function(Value) blinkDistance = Value end})
LocalPlayerTab:CreateButton({ Name = "Reset Character", Callback = function() if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end end})

-- ==== COMBAT TAB ====
CombatTab:CreateSection("Aimbot & Hitboxes")
CombatTab:CreateToggle({ Name = "Smart Aimbot [Hold Right Click]", CurrentValue = false, Flag = "AimbotToggle", Callback = function(Value) aimbotEnabled = Value end})
CombatTab:CreateSlider({ Name = "Aimbot Smoothness", Range = {0.1, 1}, Increment = 0.1, Suffix = "Lerp", CurrentValue = 1, Flag = "AimSmoothSlider", Callback = function(Value) aimbotSmoothness = Value end})
CombatTab:CreateToggle({ Name = "Hitbox Expander", CurrentValue = false, Flag = "HitboxToggle", Callback = function(Value) 
    hitboxExpanderEnabled = Value 
    if not Value then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                p.Character.HumanoidRootPart.Transparency = 1
            end
        end
    end
end})
CombatTab:CreateSlider({ Name = "Hitbox Size", Range = {2, 50}, Increment = 1, Suffix = "Studs", CurrentValue = 2, Flag = "HitboxSizeSlider", Callback = function(Value) hitboxSize = Value end})

CombatTab:CreateSection("Offensive Exploits")
local flingDropdown = CombatTab:CreateDropdown({
    Name = "Select Fling Target",
    Options = {"None"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "FlingPlayerDropdown",
    Callback = function(Option)
        local targetName = Option[1]
        flingTargetPlayer = Players:FindFirstChild(targetName)
    end,
})

local function updateFlingDropdown()
    local pNames = {"None"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(pNames, p.Name) end
    end
    flingDropdown:Refresh(pNames)
end
Players.PlayerAdded:Connect(updateFlingDropdown)
Players.PlayerRemoving:Connect(updateFlingDropdown)
updateFlingDropdown()

CombatTab:CreateToggle({ Name = "Activate Target Fling", CurrentValue = false, Flag = "FlingToggle", Callback = function(Value) 
    flingEnabled = Value 
    if Value and not flingTargetPlayer then
        Rayfield:Notify({Title="Warning", Content="Please select a target to fling.", Duration=2})
    end
    if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end})

-- ==== VISUALS TAB ====
local FPSLabel = VisualsTab:CreateLabel("FPS: 0")
local PingLabel = VisualsTab:CreateLabel("Ping: 0 ms")
VisualsTab:CreateToggle({ Name = "Player ESP (Name, HP, Dist)", CurrentValue = false, Flag = "ESPToggleMain", Callback = function(Value) espEnabled = Value end})
VisualsTab:CreateToggle({ Name = "Player Chams (Wallhack/X-Ray)", CurrentValue = false, Flag = "ChamsToggle", Callback = function(Value) 
    chamsEnabled = Value 
    for _, espData in pairs(espObjects) do
        if espData.Cham then espData.Cham.Enabled = chamsEnabled end
    end
end})
VisualsTab:CreateToggle({ Name = "Player Tracers (Beams)", CurrentValue = false, Flag = "TracersToggle", Callback = function(Value) 
    tracersEnabled = Value
    if Value then
        for _, p in pairs(Players:GetPlayers()) do addTracer(p) end
    else
        for _, p in pairs(Players:GetPlayers()) do removeTracer(p) end
    end
end})
VisualsTab:CreateToggle({ Name = "Map X-Ray (See through walls)", CurrentValue = false, Flag = "MapXrayToggle", Callback = function(Value) 
    mapXrayEnabled = Value
    if Value then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") and v.Name ~= "Terrain" then
                originalPartTransparencies[v] = v.Transparency
                v.Transparency = 0.5
            end
        end
    else
        for v, trans in pairs(originalPartTransparencies) do
            if v and v.Parent then v.Transparency = trans end
        end
        originalPartTransparencies = {}
    end
end})
VisualsTab:CreateToggle({ Name = "Clear Vision (No Fog/Blur)", CurrentValue = false, Flag = "NoFogToggle", Callback = function(Value) 
    noFogBlurEnabled = Value 
    if Value then
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") then v.Enabled = false end
        end
    else
        Lighting.FogEnd = 10000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") then v.Enabled = true end
        end
    end
end})

-- ==== FRIENDS TAB ====
local friendDrop = FriendsTab:CreateDropdown({
    Name = "Select Online Friend (In-Game)",
    Options = {"None"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "FriendDrop",
    Callback = function(Option) selectedFriend = Option[1] end,
})

FriendsTab:CreateButton({ Name = "Refresh Online Friends", Callback = function() 
    local success, page = pcall(function() return LocalPlayer:GetFriendsOnline(200) end)
    if success and page then
        local names = {}
        onlineFriends = {}
        for _, f in ipairs(page) do
            if f.LocationType == 4 then 
                table.insert(names, f.UserName)
                onlineFriends[f.UserName] = f
            end
        end
        if #names == 0 then table.insert(names, "No friends currently in-game") end
        friendDrop:Refresh(names)
        Rayfield:Notify({Title="Friends List", Content="Refreshed successfully.", Duration=2})
    else
        Rayfield:Notify({Title="Error", Content="Failed to fetch friends list.", Duration=2})
    end
end})

FriendsTab:CreateButton({ Name = "Join Selected Friend's Server", Callback = function() 
    if selectedFriend and onlineFriends[selectedFriend] then
        local f = onlineFriends[selectedFriend]
        Rayfield:Notify({Title="Teleporting", Content="Joining " .. selectedFriend .. "'s game...", Duration=3})
        TeleportService:TeleportToPlaceInstance(f.PlaceId, f.GameId, LocalPlayer)
    else
        Rayfield:Notify({Title="Error", Content="Select a valid friend first.", Duration=2})
    end
end})

-- ==== UTILITIES TAB ====
UtilsTab:CreateButton({ Name = "Unlock Max Camera Zoom", Callback = function() 
    LocalPlayer.CameraMaxZoomDistance = 100000
    Rayfield:Notify({Title="Unlocked", Content="You can now zoom out infinitely.", Duration=3})
end})
UtilsTab:CreateButton({ Name = "Give Universal BTools (Delete/Clone/Grab)", Callback = function() 
    for i = 1, 4 do
        local t = Instance.new("HopperBin")
        t.BinType = i
        t.Parent = LocalPlayer.Backpack
    end
    Rayfield:Notify({Title="BTools Granted", Content="Check your inventory.", Duration=3})
end})
UtilsTab:CreateToggle({ Name = "Click-Delete Part [Hold Left Alt + Click]", CurrentValue = false, Flag = "ClickDeleteToggle", Callback = function(Value) clickDeleteEnabled = Value end})
UtilsTab:CreateButton({ Name = "Load Dex Explorer", Callback = function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    Rayfield:Notify({Title="Dex Loaded", Content="Explorer has been injected.", Duration=3})
end})
UtilsTab:CreateToggle({ Name = "Anti-AFK (Prevent Idle Kick)", CurrentValue = false, Flag = "AntiAFKToggle", Callback = function(Value) antiAfkEnabled = Value end})
UtilsTab:CreateButton({ Name = "Copy Server JobId", Callback = function() setclipboard(game.JobId); Rayfield:Notify({Title="Copied", Content="JobId copied to clipboard", Duration=2}) end})
UtilsTab:CreateButton({ Name = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end})
UtilsTab:CreateButton({ Name = "Hop to New Server", Callback = function() ServerHop() end})
UtilsTab:CreateToggle({ Name = "FullBright (Remove Shadows)", CurrentValue = false, Flag = "FBToggle", Callback = function(Value) 
    fullBrightEnabled = Value 
    if Value then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoor
    end
end})
UtilsTab:CreateToggle({ Name = "Chat Logger Notifications", CurrentValue = false, Flag = "ChatLogToggle", Callback = function(Value) chatLoggerEnabled = Value end})
UtilsTab:CreateSlider({ Name = "Time of Day", Range = {0, 24}, Increment = 0.5, Suffix = "Hrs", CurrentValue = 14, Flag = "TimeSlider", Callback = function(Value) Lighting.ClockTime = Value end})
UtilsTab:CreateToggle({ Name = "Auto Time Cycle (Cinematic)", CurrentValue = false, Flag = "TimeCycleToggle", Callback = function(Value) timeCycleEnabled = Value end})
UtilsTab:CreateSlider({ Name = "Cycle Speed", Range = {0.1, 10}, Increment = 0.1, Suffix = "x", CurrentValue = 1, Flag = "TimeCycleSlider", Callback = function(Value) timeCycleSpeed = Value end})
UtilsTab:CreateSlider({ Name = "Field of View (FOV)", Range = {10, 120}, Increment = 1, Suffix = "FOV", CurrentValue = 70, Flag = "FOVSlider", Callback = function(Value) workspace.CurrentCamera.FieldOfView = Value end})

-- ==========================================
-- INPUT & CONTROLS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then inputW = true
    elseif input.KeyCode == Enum.KeyCode.A then inputA = true
    elseif input.KeyCode == Enum.KeyCode.S then inputS = true
    elseif input.KeyCode == Enum.KeyCode.D then inputD = true
    elseif input.KeyCode == Enum.KeyCode.Space then inputSpace = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl then inputCtrl = true end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHoldingRMB = true
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if ctrlClickTpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            if Mouse.Hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end

        if clickDeleteEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local target = Mouse.Target
            if target and not target.Parent:FindFirstChild("Humanoid") then
                target:Destroy()
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.Q and blinkEnabled then
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            myHRP.CFrame = myHRP.CFrame + (myHRP.CFrame.LookVector * blinkDistance)
        end
    end

    if input.KeyCode == Enum.KeyCode.K then
        local rootGuis = game:GetService("CoreGui"):GetDescendants()
        for _, gui in ipairs(rootGuis) do
            if gui:IsA("ScreenGui") and gui.Name == "Rayfield" then
                uiVisible = not uiVisible
                gui.Enabled = uiVisible
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.W then inputW = false
    elseif input.KeyCode == Enum.KeyCode.A then inputA = false
    elseif input.KeyCode == Enum.KeyCode.S then inputS = false
    elseif input.KeyCode == Enum.KeyCode.D then inputD = false
    elseif input.KeyCode == Enum.KeyCode.Space then inputSpace = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl then inputCtrl = false end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHoldingRMB = false
    end
end)

-- ==========================================
-- RUNSERVICE LOOPS
-- ==========================================

-- Noclip
RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Visuals Render Loop
local lastUpdate = tick()
local frames = 0
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local t = tick()
    if t - lastUpdate >= 0.5 then
        FPSLabel:Set("FPS: " .. math.floor(frames / (t - lastUpdate)))
        frames = 0
        lastUpdate = t
        
        local success, ping = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if success and ping then
            PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
        end
    end

    if noFogBlurEnabled then
        Lighting.FogEnd = 100000
    end

    -- Chams Update
    if chamsEnabled then
        for player, espData in pairs(espObjects) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                espData.Cham.Adornee = player.Character
                espData.Cham.Enabled = true
            else
                espData.Cham.Enabled = false
            end
        end
    else
        for _, espData in pairs(espObjects) do
            if espData.Cham then espData.Cham.Enabled = false end
        end
    end

    -- Aimbot Camera Interpolation
    if aimbotEnabled and isHoldingRMB then
        local target = getClosestPlayerToCursor()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPos = target.Character.Head.Position
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, aimbotSmoothness)
        end
    end
end)

-- Main Physics Loop
RunService.Heartbeat:Connect(function(dt)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")
    
    if timeCycleEnabled then Lighting.ClockTime = Lighting.ClockTime + (dt * timeCycleSpeed * 0.1) end
    if gravityEnabled then workspace.Gravity = customGravity end

    if myHum then
        if wsEnabled then myHum.WalkSpeed = customWS end
        if jpEnabled and not tallEnabled then myHum.JumpPower = customJP end 
    end

    -- Loop Teleport
    if loopTpEnabled and selectedTpPlayer and selectedTpPlayer.Character and selectedTpPlayer.Character:FindFirstChild("HumanoidRootPart") and myHRP then
        local targetHrp = selectedTpPlayer.Character.HumanoidRootPart
        if tpMode == "Directly On Target" then myHRP.CFrame = targetHrp.CFrame
        elseif tpMode == "Behind Target" then myHRP.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 4)
        elseif tpMode == "Above Target" then myHRP.CFrame = targetHrp.CFrame * CFrame.new(0, 6, 0)
        end
    end

    -- Fling Target Logic
    if flingEnabled and flingTargetPlayer and flingTargetPlayer.Character and flingTargetPlayer.Character:FindFirstChild("HumanoidRootPart") and myHRP and myHum then
        local tHrp = flingTargetPlayer.Character.HumanoidRootPart
        myHRP.CFrame = tHrp.CFrame
        myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        myHRP.AssemblyAngularVelocity = Vector3.new(100000, 100000, 100000)
        for _, part in pairs(myChar:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- BHOP Physics
    if bhopEnabled and myHRP and myHum then
        local origProps = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
        local slipProps = PhysicalProperties.new(0.7, 0.01, 0.5, 100, 1)
        local horizVel = myHRP.Velocity * Vector3.new(1,0,1)
        local hzSpeedNow = horizVel.Magnitude

        if hzSpeedNow < bhopLastHzSpeed * 0.5 and bhopLastHzSpeed > bhopBaseSpeed * 1.5 then
            bhopCurrSpeed = bhopBaseSpeed
            myHum.WalkSpeed = bhopBaseSpeed
            bhopSliding = false
            myHRP.CustomPhysicalProperties = origProps
        end
        bhopLastHzSpeed = hzSpeedNow

        if myHum.FloorMaterial == Enum.Material.Air and myHum.MoveDirection.Magnitude > 0 then
            local airAccel = 20
            local wishDir = myHum.MoveDirection.Unit
            local projSpeed = horizVel:Dot(wishDir)
            local addSpeed = airAccel - projSpeed
            if addSpeed > 0 then
                local accelSpeed = math.min(addSpeed, airAccel * dt)
                horizVel = horizVel + wishDir * accelSpeed
            end
            myHRP.Velocity = Vector3.new(horizVel.X, myHRP.Velocity.Y, horizVel.Z)
        end

        if myHum.MoveDirection.Magnitude > 0 then
            bhopLastDir = myHum.MoveDirection.Unit
            bhopSliding = false
            myHRP.CustomPhysicalProperties = origProps
        elseif myHum.MoveDirection.Magnitude == 0 and bhopCurrSpeed > bhopBaseSpeed then
            if not bhopSliding then
                bhopSliding = true
                myHRP.CustomPhysicalProperties = slipProps
                myHRP.Velocity = Vector3.new(bhopLastDir.X * bhopCurrSpeed, myHRP.Velocity.Y, bhopLastDir.Z * bhopCurrSpeed)
            end

            bhopCurrSpeed = math.max(bhopBaseSpeed, bhopCurrSpeed - bhopDecelRate * dt)
            myHum.WalkSpeed = bhopCurrSpeed

            local velHz = myHRP.Velocity * Vector3.new(1,0,1)
            if velHz.Magnitude > bhopBaseSpeed then
                myHRP.Velocity = Vector3.new(bhopLastDir.X * bhopCurrSpeed, myHRP.Velocity.Y, bhopLastDir.Z * bhopCurrSpeed)
            else
                bhopSliding = false
                myHRP.CustomPhysicalProperties = origProps
                myHum.WalkSpeed = bhopBaseSpeed
                bhopCurrSpeed = bhopBaseSpeed
            end
        else
            if not wsEnabled and not tallEnabled then myHum.WalkSpeed = bhopCurrSpeed end
        end
    end

    -- Hitbox Expander Logic
    if hitboxExpanderEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                p.Character.HumanoidRootPart.Transparency = 0.8
                p.Character.HumanoidRootPart.BrickColor = BrickColor.new("Bright red")
                p.Character.HumanoidRootPart.Material = Enum.Material.Neon
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end
    
    if playerSpinEnabled and myHRP and not flingEnabled then myHRP.CFrame = myHRP.CFrame * CFrame.Angles(0, math.rad(playerSpinSpeed), 0) end

    -- Air Walk Platform Logic
    if airWalkEnabled and myHRP then
        airWalkPart.Parent = workspace
        if airWalkY == nil then airWalkY = myHRP.Position.Y - 3.5 end
        if inputSpace then airWalkY = airWalkY + 0.5 end
        if inputCtrl then airWalkY = airWalkY - 0.5 end
        airWalkPart.CFrame = CFrame.new(myHRP.Position.X, airWalkY, myHRP.Position.Z)
    else
        airWalkPart.Parent = nil
        airWalkY = nil
    end

    -- Water Walk Logic
    if waterWalkEnabled and myHRP and myHum then
        waterRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        local feetPos = myHRP.Position - Vector3.new(0, 2.5, 0)
        local rayOrigin = feetPos + Vector3.new(0, 2, 0)
        local rayDirection = Vector3.new(0, -10, 0)
        local hit = workspace:Raycast(rayOrigin, rayDirection, waterRaycastParams)
        
        if hit and (hit.Material == Enum.Material.Water or (hit.Instance and hit.Instance.Name:lower():find("water"))) then
            local surfaceY = hit.Position.Y
            local feetDist = feetPos.Y - surfaceY
            
            if feetDist <= 3 and feetDist >= -1 then
                if not waterPlatform then
                    waterPlatform = Instance.new("Part")
                    waterPlatform.Name = "WaterPlatform"
                    waterPlatform.Size = Vector3.new(20, 0.2, 20)
                    waterPlatform.Anchored = true
                    waterPlatform.Transparency = 1
                    waterPlatform.Parent = workspace
                end
                waterPlatform.Position = Vector3.new(myHRP.Position.X, surfaceY + 1, myHRP.Position.Z)
                myHum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
            else
                if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
                myHum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            end
        else
            if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
            myHum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        end
    end

    -- Anti-Void Rescue
    if antiVoidEnabled and myHRP then
        local voidThreshold = workspace.FallenPartsDestroyHeight + antiVoidCatchOffset
        if myHRP.Position.Y < voidThreshold then
            myHRP.CFrame = CFrame.new(myHRP.Position.X, antiVoidTPHeight, myHRP.Position.Z)
            myHRP.Velocity = Vector3.new(0, 0, 0)
            if myHum then myHum:ChangeState(Enum.HumanoidStateType.Freefall) end
            Rayfield:Notify({Title = "Anti-Void Engaged", Content = "Rescued from the abyss.", Duration = 3})
        end
    end

    -- Fly Flight Engine
    if flyEnabled and flyBV and flyBG then
        local cam = workspace.CurrentCamera
        flyBG.CFrame = cam.CFrame
        local moveDir = Vector3.new(0, 0, 0)
        
        if inputW then moveDir = moveDir + cam.CFrame.LookVector end
        if inputS then moveDir = moveDir - cam.CFrame.LookVector end
        if inputA then moveDir = moveDir - cam.CFrame.RightVector end
        if inputD then moveDir = moveDir + cam.CFrame.RightVector end
        if inputSpace then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if inputCtrl then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        if moveDir.Magnitude > 0 then flyBV.Velocity = moveDir.Unit * flySpeed else flyBV.Velocity = Vector3.new(0, 0, 0) end
    end
    
    -- ESP Updates
    for player, esp in pairs(espObjects) do
        if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local char = player.Character
            local hum = char.Humanoid
            local targetHRP = char.HumanoidRootPart
            
            esp.Billboard.Adornee = targetHRP
            esp.Billboard.Enabled = true
            esp.NameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            esp.HealthLabel.Text = "HP: " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            
            if myHRP then
                local distance = (myHRP.Position - targetHRP.Position).Magnitude
                esp.DistLabel.Text = "Dist: " .. math.floor(distance) .. "s"
            end
            
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            esp.HealthLabel.TextColor3 = Color3.new(1 - healthPercent, healthPercent, 0)
        else
            esp.Billboard.Enabled = false
        end
    end
end)

Rayfield:LoadConfiguration()
