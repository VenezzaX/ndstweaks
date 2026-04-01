loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/GotoPunch/refs/heads/main/punch.lua'),true))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/emotes/refs/heads/main/tuffemotes.lua'),true))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

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
    Name = "God Parts V32 | The Overlord",
    LoadingTitle = "Initializing God Parts...",
    LoadingSubtitle = "Injecting Overlord Protocols...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GodPartsConfig",
        FileName = "GodPartsSave"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true 
    },
    KeySystem = false,
})

if LocalPlayer.Name == "HeavenlyReminiscence" then
    Rayfield:Notify({
        Title = "Welcome back, Master",
        Content = "<font color='rgb(255, 255, 0)'>HeavenlyReminiscence</font> recognized. All systems online.",
        Duration = 5,
        Image = 4483362458,
    })
end

-- State Variables
local radius = 30 
local elevation = 0 
local rotationSpeed = 10
local attractionStrength = 1500 
local partsEnabled = false
local showOwnership = false
local showTrails = false
local espEnabled = false
local uiVisible = true
local antiClipEnabled = true

-- Automation & Aesthetics
local autoAbsorbEnabled = false
local autoAbsorbRadius = 50
local forceNeon = false
local rainbowMode = false
local showSparks = false

-- TK & Target Variables
local carryEnabled = false
local carriedPart = nil
local carryDistance = 20
local hoveredPart = nil
local throwPower = 500
local lockedPlayer = nil

-- Local Player Hacks
local flyEnabled = false
local flySpeed = 50
local noclipEnabled = false
local godModeEnabled = false
local godModeConnection = nil
local flyBV, flyBG
local inputW, inputA, inputS, inputD, inputSpace, inputCtrl = false, false, false, false, false, false

local targetMode = "Player" 
local currentShape = "Ophanim" 
local currentPattern = "Spin"
local motionMode = "Fluid" 
local fireMode = "Burst" 

local isHoldingF = false
local lastBurstTime = 0
local burstCooldown = 3
local minigunRate = 0.05 
local lastMinigunShot = 0
local minigunIndex = 1

local parts = {}
local partFireData = {}
local selectionBoxes = {}
local trailsMap = {}
local sparksMap = {}
local espObjects = {} 
local centipedePath = {}
local pathRecordDist = 1.5

local shapesList = {"Ophanim", "Giant Sword", "Jellyfish", "Meteor", "Halo", "Aura", "Vortex", "Shield", "Crown", "Swords", "Rings", "Satellites", "Dragon", "Claw", "Punch", "Plane", "Wings", "Atom", "Centipede", "Circle", "Triangle", "Square", "Pentagram", "Hexagon", "Star", "3D Sphere", "3D Cube", "Tornado", "DNA", "Galaxy", "Black Hole"}
local patternsList = {"Spin", "Wave", "Worm", "Pulse", "Swarm"}
local weaponsList = {"Burst", "Minigun", "Nova", "Rain", "Orbit Toss", "Orbital Laser", "Sawblade"}

local function checkOwner(part)
    if not part or not part.Parent then return false end
    if type(isnetworkowner) == "function" then
        local success, isOwner = pcall(isnetworkowner, part)
        return success and isOwner
    else
        return part.ReceiveAge == 0
    end
end

local targetHighlight = Instance.new("Highlight")
targetHighlight.FillColor = Color3.fromRGB(255, 255, 0)
targetHighlight.OutlineColor = Color3.fromRGB(255, 100, 0)
targetHighlight.FillTransparency = 0.5
targetHighlight.Enabled = false
targetHighlight.Parent = safeUIParent

local carryBillboard = Instance.new("BillboardGui")
carryBillboard.Size = UDim2.new(0, 100, 0, 30)
carryBillboard.StudsOffset = Vector3.new(0, 2, 0)
carryBillboard.AlwaysOnTop = true
carryBillboard.Enabled = false
carryBillboard.Parent = safeUIParent
local carryText = Instance.new("TextLabel", carryBillboard)
carryText.Size = UDim2.new(1, 0, 1, 0)
carryText.BackgroundTransparency = 1
carryText.Text = "HOLDING"
carryText.TextColor3 = Color3.fromRGB(255, 50, 50)
carryText.TextStrokeTransparency = 0
carryText.Font = Enum.Font.GothamBlack
carryText.TextSize = 16

local tkAtt0 = Instance.new("Attachment")
local tkAtt1 = Instance.new("Attachment")
local tkBeam = Instance.new("Beam")
tkBeam.Color = ColorSequence.new(Color3.fromRGB(138, 43, 226))
tkBeam.Width0 = 0.1
tkBeam.Width1 = 0.4
tkBeam.FaceCamera = true
tkBeam.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.5),
    NumberSequenceKeypoint.new(1, 0)
})
tkBeam.Enabled = false

-- ==== NETWORK BYPASS ====
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {}
    }
    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            Part.CanCollide = false
            Part.CanQuery = false 
        end
    end
    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = workspace
        RunService.Heartbeat:Connect(function()
            pcall(function() sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge) end)
        end)
    end
    EnablePartControl()
end

local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then return false end
        Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        Part.CanCollide = false
        Part.CanQuery = false 
        return true
    end
    return false
end

local function addPart(part)
    if RetainPart(part) and not table.find(parts, part) then 
        table.insert(parts, part) 
        
        local antiGrav = Instance.new("BodyForce")
        antiGrav.Name = "GodPartsAntiGrav"
        antiGrav.Force = Vector3.new(0, part:GetMass() * workspace.Gravity, 0)
        antiGrav.Parent = part
        
        local box = Instance.new("SelectionBox")
        box.Adornee = part
        box.LineThickness = 0.05
        box.SurfaceTransparency = 0.8
        box.Visible = showOwnership
        box.Parent = part
        selectionBoxes[part] = box
        
        local a0 = Instance.new("Attachment", part)
        local a1 = Instance.new("Attachment", part)
        a0.Position = Vector3.new(0, 0.5, 0)
        a1.Position = Vector3.new(0, -0.5, 0)
        local trail = Instance.new("Trail", part)
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 255))
        })
        trail.Lifetime = 0.5
        trail.Enabled = showTrails
        trailsMap[part] = {a0, a1, trail}

        local sparks = Instance.new("ParticleEmitter", part)
        sparks.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0)})
        sparks.Texture = "rbxassetid://243660364"
        sparks.Rate = 5
        sparks.Lifetime = NumberRange.new(0.5, 1)
        sparks.Speed = NumberRange.new(5, 10)
        sparks.Enabled = showSparks
        sparksMap[part] = sparks
        
        if forceNeon then part.Material = Enum.Material.Neon end
    end
end

local function releaseTK()
    if carriedPart then
        local bp = carriedPart:FindFirstChild("TK_BP")
        if bp then bp:Destroy() end
        local bg = carriedPart:FindFirstChild("TK_BG")
        if bg then bg:Destroy() end
        carriedPart = nil
        carryBillboard.Enabled = false
        tkBeam.Enabled = false
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then table.remove(parts, index) end
    partFireData[part] = nil 
    if carriedPart == part then releaseTK() end
    
    if part and part.Parent then
        local antiGrav = part:FindFirstChild("GodPartsAntiGrav")
        if antiGrav then antiGrav:Destroy() end
    end
    
    if selectionBoxes[part] then selectionBoxes[part]:Destroy(); selectionBoxes[part] = nil end
    if trailsMap[part] then trailsMap[part][1]:Destroy(); trailsMap[part][2]:Destroy(); trailsMap[part][3]:Destroy(); trailsMap[part] = nil end
    if sparksMap[part] then sparksMap[part]:Destroy(); sparksMap[part] = nil end
end

for _, part in pairs(workspace:GetDescendants()) do addPart(part) end
workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

-- ==== AUTO-ASSIMILATION LOOP ====
task.spawn(function()
    while task.wait(0.5) do
        if autoAbsorbEnabled and partsEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local params = OverlapParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                
                local nearbyParts = workspace:GetPartBoundsInRadius(hrp.Position, autoAbsorbRadius, params)
                for _, part in ipairs(nearbyParts) do
                    if part:IsA("BasePart") and not part.Anchored and not table.find(parts, part) and not part.Parent:FindFirstChild("Humanoid") then
                        if checkOwner(part) then
                            addPart(part)
                        end
                    end
                end
            end
        end
    end
end)

local function createESP(player)
    if player == LocalPlayer then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_ESP"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0) 
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = safeUIParent

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = billboard
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Font = Enum.Font.Code
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 14

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Parent = billboard
    healthLabel.BackgroundTransparency = 1
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.Font = Enum.Font.Code
    healthLabel.Text = "HP: 100"
    healthLabel.TextColor3 = Color3.new(0, 1, 0)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextSize = 12

    espObjects[player] = {Billboard = billboard, NameLabel = nameLabel, HealthLabel = healthLabel}
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].Billboard:Destroy()
        espObjects[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- ==== GOD MODE & LOCAL PLAYER LOGIC ====
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

local function toggleFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyEnabled then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 9000
        flyBG.D = 500
        flyBG.CFrame = workspace.CurrentCamera.CFrame
        flyBG.Parent = hrp
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

-- Persistent Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- Wait for character to fully load into workspace
    if flyEnabled then toggleFly() end
    if godModeEnabled then applyGodMode(char) end
end)

-- Click-to-TP Tool Generator
local function giveTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "Click TP"
    tool.RequiresHandle = false
    tool.ToolTip = "Click anywhere to teleport"
    
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Mouse.Hit then
            -- Teleport 3 studs above the click so you don't get stuck in the floor
            hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end)
    
    tool.Parent = LocalPlayer.Backpack
    
    -- Add to StarterGear so it stays when you die
    local starterGear = LocalPlayer:FindFirstChild("StarterGear")
    if starterGear then
        tool:Clone().Parent = starterGear
    end
    Rayfield:Notify({Title = "Tool Granted", Content = "Click TP Tool added to inventory.", Duration = 3})
end

-- ==== RAYFIELD TABS ====
local MainTab = Window:CreateTab("God Parts", 4483362458) 
local WeaponsTab = Window:CreateTab("Weapons", 4483362458)
local TKTab = Window:CreateTab("Telekinesis", 4483345998) 
local LocalPlayerTab = Window:CreateTab("Local Player", 4483362875)
local AutoTab = Window:CreateTab("Automation", 4483345998)
local AesthTab = Window:CreateTab("Aesthetics", 4483362875)
local SettingsTab = Window:CreateTab("Adjustments", 4483345998) 
local VisualsTab = Window:CreateTab("Visuals & Info", 4483362875) 

local PartCountLabel = VisualsTab:CreateLabel("Parts Controlled: 0")
local CooldownLabel = WeaponsTab:CreateLabel("Weapon Status: Ready")
local TargetLabel = MainTab:CreateLabel("Target: Player (Self)")
local TKStatusLabel = TKTab:CreateLabel("Telekinesis: Disabled")

-- Main Tab Controls
MainTab:CreateToggle({ Name = "Enable God Parts (Swarm)", CurrentValue = false, Flag = "PowerToggle", Callback = function(Value) partsEnabled = Value end})
MainTab:CreateDropdown({ Name = "Shape Configuration", Options = shapesList, CurrentOption = {"Ophanim"}, MultipleOptions = false, Flag = "ShapeDropdown", Callback = function(Option) currentShape = Option[1] if currentShape == "Centipede" or currentShape == "Dragon" then centipedePath = {} end end})
MainTab:CreateDropdown({ Name = "Target Mode", Options = {"Player", "Mouse", "Lock-On"}, CurrentOption = {"Player"}, MultipleOptions = false, Flag = "TargetDropdown", Callback = function(Option) 
    targetMode = Option[1] 
    if targetMode == "Lock-On" then TargetLabel:Set("Target: [Press E to Lock-On]") elseif targetMode == "Player" then TargetLabel:Set("Target: Player (Self)") else TargetLabel:Set("Target: Mouse Cursor") end
end})
MainTab:CreateDropdown({ Name = "Movement Pattern", Options = patternsList, CurrentOption = {"Spin"}, MultipleOptions = false, Flag = "PatternDropdown", Callback = function(Option) currentPattern = Option[1] end})

-- Weapons Tab
WeaponsTab:CreateDropdown({ Name = "Weapon Mode [Press/Hold F]", Options = weaponsList, CurrentOption = {"Burst"}, MultipleOptions = false, Flag = "WeaponDropdown", Callback = function(Option) fireMode = Option[1] end})

-- TK Tab Controls
TKTab:CreateToggle({ Name = "Enable Telekinesis", CurrentValue = false, Flag = "CarryToggle", Callback = function(Value) carryEnabled = Value; if not Value then releaseTK(); targetHighlight.Enabled = false end end})
TKTab:CreateLabel("Left Click: Grab/Hold | Right Click: Throw")
TKTab:CreateLabel("Scroll Wheel: Push/Pull")
TKTab:CreateSlider({ Name = "Throw Power", Range = {50, 2000}, Increment = 10, Suffix = "Force", CurrentValue = 500, Flag = "ThrowPowerSlider", Callback = function(Value) throwPower = Value end})

-- Local Player Tab Controls
LocalPlayerTab:CreateToggle({ Name = "God Mode (Infinite Health)", CurrentValue = false, Flag = "GodModeToggle", Callback = function(Value) 
    godModeEnabled = Value 
    if Value then applyGodMode(LocalPlayer.Character) else disableGodMode() end 
end})
LocalPlayerTab:CreateToggle({ Name = "Hover Fly Mode", CurrentValue = false, Flag = "FlyToggle", Callback = function(Value) flyEnabled = Value; toggleFly() end})
LocalPlayerTab:CreateSlider({ Name = "Fly Speed", Range = {10, 200}, Increment = 5, Suffix = "Speed", CurrentValue = 50, Flag = "FlySpeedSlider", Callback = function(Value) flySpeed = Value end})
LocalPlayerTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Flag = "NoclipToggle", Callback = function(Value) noclipEnabled = Value end})
LocalPlayerTab:CreateButton({ Name = "Give Click-to-TP Tool", Callback = function() giveTPTool() end})

local tpDropdown = LocalPlayerTab:CreateDropdown({
    Name = "Teleport to Player",
    Options = {"Select Player"},
    CurrentOption = {"Select Player"},
    MultipleOptions = false,
    Flag = "TPDropdown",
    Callback = function(Option)
        local targetName = Option[1]
        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                Rayfield:Notify({Title = "Teleported", Content = "Moved to " .. targetName, Duration = 2})
            end
        end
    end,
})

local function updateTPDropdown()
    local pNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(pNames, p.Name) end
    end
    tpDropdown:Refresh(pNames)
end
Players.PlayerAdded:Connect(updateTPDropdown)
Players.PlayerRemoving:Connect(updateTPDropdown)
updateTPDropdown()

-- Automation Tab
AutoTab:CreateToggle({ Name = "Auto-Absorb Nearby Parts", CurrentValue = false, Flag = "AutoAbsorb", Callback = function(Value) autoAbsorbEnabled = Value end})
AutoTab:CreateSlider({ Name = "Absorb Radius", Range = {10, 500}, Increment = 5, Suffix = "Studs", CurrentValue = 50, Flag = "AbsorbRad", Callback = function(Value) autoAbsorbRadius = Value end})

-- Aesthetics Tab
AesthTab:CreateToggle({ Name = "Force Neon Material", CurrentValue = false, Flag = "ForceNeon", Callback = function(Value) 
    forceNeon = Value 
    if not Value then for _, p in pairs(parts) do if p.Parent then p.Material = Enum.Material.Plastic end end end
end})
AesthTab:CreateToggle({ Name = "RGB Rainbow Mode", CurrentValue = false, Flag = "RainbowMode", Callback = function(Value) rainbowMode = Value end})
AesthTab:CreateToggle({ Name = "Energy Sparks", CurrentValue = false, Flag = "SparksMode", Callback = function(Value) 
    showSparks = Value 
    for _, s in pairs(sparksMap) do s.Enabled = showSparks end
end})

-- Settings Tab Controls
SettingsTab:CreateSlider({ Name = "Formation Radius", Range = {5, 300}, Increment = 1, Suffix = "Studs", CurrentValue = 30, Flag = "RadiusSlider", Callback = function(Value) radius = Value end})
SettingsTab:CreateSlider({ Name = "Elevation Offset", Range = {-50, 200}, Increment = 1, Suffix = "Studs", CurrentValue = 0, Flag = "ElevSlider", Callback = function(Value) elevation = Value end})
SettingsTab:CreateSlider({ Name = "Rotation Speed", Range = {1, 50}, Increment = 1, Suffix = "Speed", CurrentValue = 10, Flag = "SpeedSlider", Callback = function(Value) rotationSpeed = Value end})
SettingsTab:CreateDropdown({ Name = "Physics Motion", Options = {"Fluid", "Snap", "Ricochet"}, CurrentOption = {"Fluid"}, MultipleOptions = false, Flag = "MotionDropdown", Callback = function(Option) motionMode = Option[1] end})
SettingsTab:CreateToggle({ Name = "Anti-Ground Clip (Prevents voiding)", CurrentValue = true, Flag = "AntiClipToggle", Callback = function(Value) antiClipEnabled = Value end})
SettingsTab:CreateButton({ Name = "Release Swarm (Drop All Parts)", Callback = function() for i = #parts, 1, -1 do local p = parts[i]; if p then p.CanQuery = true; removePart(p) end end; parts = {}; Rayfield:Notify({Title = "Swarm Released", Content = "All parts dropped.", Duration = 3}) end})
SettingsTab:CreateLabel("Press [K] to Hide/Show GUI completely")

-- Visuals Tab Controls
VisualsTab:CreateToggle({ Name = "Player ESP (Name & Health)", CurrentValue = false, Flag = "ESPToggleMain", Callback = function(Value) espEnabled = Value end})
VisualsTab:CreateToggle({ Name = "Enable Visual Trails", CurrentValue = false, Flag = "TrailsToggle", Callback = function(Value) showTrails = Value; for _, tData in pairs(trailsMap) do tData[3].Enabled = showTrails end end})
VisualsTab:CreateToggle({ Name = "Ownership ESP (Green = Yours)", CurrentValue = false, Flag = "PartESPToggle", Callback = function(Value) showOwnership = Value; for _, box in pairs(selectionBoxes) do box.Visible = showOwnership end end})

-- ==== INPUT & CONTROLS ====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then inputW = true
    elseif input.KeyCode == Enum.KeyCode.A then inputA = true
    elseif input.KeyCode == Enum.KeyCode.S then inputS = true
    elseif input.KeyCode == Enum.KeyCode.D then inputD = true
    elseif input.KeyCode == Enum.KeyCode.Space then inputSpace = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl then inputCtrl = true end

    if input.KeyCode == Enum.KeyCode.K then
        local rootGuis = game:GetService("CoreGui"):GetDescendants()
        for _, gui in ipairs(rootGuis) do
            if gui:IsA("ScreenGui") and gui.Name == "Rayfield" then
                uiVisible = not uiVisible
                gui.Enabled = uiVisible
            end
        end
    end
    
    if input.KeyCode == Enum.KeyCode.E and targetMode == "Lock-On" then
        local t = Mouse.Target
        if t and t.Parent and t.Parent:FindFirstChild("Humanoid") then
            local plyr = Players:GetPlayerFromCharacter(t.Parent)
            if plyr then
                lockedPlayer = plyr
                TargetLabel:Set("Target: Locked onto " .. plyr.DisplayName)
                Rayfield:Notify({Title = "Target Locked", Content = "Swarm attacking " .. plyr.DisplayName, Duration = 2})
            end
        end
    end
    
    if partsEnabled and input.KeyCode == Enum.KeyCode.F then
        isHoldingF = true
        local currentTick = tick()
        
        if fireMode == "Burst" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local tHit = Mouse.Hit.Position
                for _, p in ipairs(parts) do
                    if p ~= carriedPart then
                        partFireData[p] = {endTime = currentTick + 1.5, targetVec = tHit + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))}
                    end
                end
            end
        elseif fireMode == "Nova" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local center = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()
                for _, p in ipairs(parts) do
                    if p ~= carriedPart then
                        local outwardDir = (p.Position - center).Unit
                        if outwardDir.Magnitude == 0 then outwardDir = Vector3.new(0,1,0) end
                        partFireData[p] = {endTime = currentTick + 1.5, targetVec = p.Position + outwardDir * (radius * 5)}
                    end
                end
            end
        elseif fireMode == "Orbit Toss" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local tHit = Mouse.Hit.Position
                local numParts = #parts
                for i, p in ipairs(parts) do
                    if p ~= carriedPart then
                        local angle = (i / numParts) * math.pi * 2
                        local orbitPos = tHit + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
                        partFireData[p] = {endTime = currentTick + 2, targetVec = orbitPos}
                    end
                end
            end
        elseif fireMode == "Sawblade" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local tHit = Mouse.Hit.Position
                local numParts = #parts
                for i, p in ipairs(parts) do
                    if p ~= carriedPart then
                        partFireData[p] = {endTime = currentTick + 2, targetVec = tHit, isSawblade = true, index = i, total = numParts}
                    end
                end
            end
        elseif fireMode == "Orbital Laser" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local center = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()
                local tHit = Mouse.Hit.Position
                local numParts = #parts
                for i, p in ipairs(parts) do
                    if p ~= carriedPart then
                        partFireData[p] = {endTime = currentTick + 2, targetVec = tHit, isLaser = true, startPos = center, index = i, total = numParts}
                    end
                end
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

    if input.KeyCode == Enum.KeyCode.F then isHoldingF = false end
end)

Mouse.Button1Down:Connect(function()
    if not carryEnabled then return end
    if hoveredPart and checkOwner(hoveredPart) then
        RetainPart(hoveredPart) 
        carriedPart = hoveredPart
        carryDistance = (workspace.CurrentCamera.CFrame.Position - carriedPart.Position).Magnitude
        
        local bp = Instance.new("BodyPosition")
        bp.Name = "TK_BP"
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.P = 20000
        bp.D = 1000
        bp.Parent = carriedPart
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "TK_BG"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 20000
        bg.D = 1000
        bg.Parent = carriedPart
    end
end)

Mouse.Button1Up:Connect(function() releaseTK() end)

Mouse.Button2Down:Connect(function()
    if not carryEnabled or not carriedPart then return end
    local partToThrow = carriedPart
    local throwDir = Mouse.UnitRay.Direction
    releaseTK()
    partToThrow.Velocity = throwDir * throwPower
end)

Mouse.WheelForward:Connect(function() if carriedPart then carryDistance = math.min(1000, carryDistance + 20) end end)
Mouse.WheelBackward:Connect(function() if carriedPart then carryDistance = math.max(10, carryDistance - 20) end end)

local function getFloorY(pos)
    local rayOrigin = pos + Vector3.new(0, 50, 0)
    local rayDirection = Vector3.new(0, -100, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filterList = {LocalPlayer.Character}
    for _, p in ipairs(parts) do table.insert(filterList, p) end
    if carriedPart then table.insert(filterList, carriedPart) end
    rayParams.FilterDescendantsInstances = filterList
    
    local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    if result then return result.Position.Y end
    return -workspace.FallenPartsDestroyHeight
end

-- Noclip Execution
RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- ==== MAIN PHYSICS LOOP ====
RunService.Heartbeat:Connect(function()
    local currentTick = tick()
    
    -- Memory Leak Prevention
    for i = #parts, 1, -1 do
        local p = parts[i]
        if not p or not p.Parent or not p:IsDescendantOf(workspace) then
            removePart(p)
        end
    end
    
    -- Fly Physics Logic
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
        
        if moveDir.Magnitude > 0 then
            flyBV.Velocity = moveDir.Unit * flySpeed
        else
            flyBV.Velocity = Vector3.new(0, 0, 0)
        end
    end

    if rainbowMode then
        local hue = (currentTick % 5) / 5
        local rgb = Color3.fromHSV(hue, 1, 1)
        for _, p in pairs(parts) do
            if p and p.Parent then
                p.Color = rgb
                if forceNeon then p.Material = Enum.Material.Neon end
                if sparksMap[p] then sparksMap[p].Color = ColorSequence.new(rgb) end
            end
        end
    elseif forceNeon then
        for _, p in pairs(parts) do 
            if p and p.Parent then p.Material = Enum.Material.Neon end 
        end
    end
    
    for player, esp in pairs(espObjects) do
        if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local char = player.Character
            local hum = char.Humanoid
            esp.Billboard.Adornee = char.HumanoidRootPart
            esp.Billboard.Enabled = true
            esp.NameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            local hp = math.floor(hum.Health)
            local maxHp = math.floor(hum.MaxHealth)
            esp.HealthLabel.Text = "HP: " .. hp .. " / " .. maxHp
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            esp.HealthLabel.TextColor3 = Color3.new(1 - healthPercent, healthPercent, 0)
        else
            esp.Billboard.Enabled = false
        end
    end

    PartCountLabel:Set("Parts Controlled: " .. #parts)

    hoveredPart = nil
    if carryEnabled and not carriedPart then
        local target = Mouse.Target
        if target and not target.Anchored and target:IsA("BasePart") and not target.Parent:FindFirstChild("Humanoid") and checkOwner(target) then
            hoveredPart = target
        elseif #parts > 0 then
            local closestPart = nil
            local closestDist = 20 
            local mousePos = Mouse.Hit.Position
            for _, p in ipairs(parts) do
                if p and p.Parent then
                    local dist = (p.Position - mousePos).Magnitude
                    if dist < closestDist and checkOwner(p) then
                        closestDist = dist
                        closestPart = p
                    end
                end
            end
            hoveredPart = closestPart
        end
    end

    if hoveredPart and carryEnabled and not carriedPart then
        targetHighlight.Adornee = hoveredPart
        targetHighlight.Enabled = true
    else
        targetHighlight.Enabled = false
    end

    if carriedPart and carriedPart.Parent then
        if not checkOwner(carriedPart) then
            releaseTK()
        else
            carryBillboard.Adornee = carriedPart
            carryBillboard.Enabled = true
            TKStatusLabel:Set("Telekinesis: Holding Part (" .. math.floor(carryDistance) .. "s)")
            
            local cam = workspace.CurrentCamera
            local holdPos = cam.CFrame.Position + (Mouse.UnitRay.Direction * carryDistance)
            
            if antiClipEnabled then
                local fY = getFloorY(holdPos)
                holdPos = Vector3.new(holdPos.X, math.max(holdPos.Y, fY + (carriedPart.Size.Y/2)), holdPos.Z)
            end
            
            local bp = carriedPart:FindFirstChild("TK_BP")
            local bg = carriedPart:FindFirstChild("TK_BG")
            if bp then bp.Position = holdPos end
            if bg then bg.CFrame = cam.CFrame end 
            
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                tkAtt0.Parent = char.HumanoidRootPart
                tkAtt1.Parent = carriedPart
                tkBeam.Attachment0 = tkAtt0
                tkBeam.Attachment1 = tkAtt1
                tkBeam.Parent = carriedPart
                tkBeam.Enabled = true
            end
        end
    else
        TKStatusLabel:Set(carryEnabled and (hoveredPart and "Telekinesis: Aiming at Part" or "Telekinesis: Idle") or "Telekinesis: Disabled")
        tkBeam.Enabled = false
    end

    if not partsEnabled then return end

    if fireMode == "Burst" or fireMode == "Nova" or fireMode == "Orbit Toss" or fireMode == "Orbital Laser" or fireMode == "Sawblade" then
        local timeSinceBurst = currentTick - lastBurstTime
        if timeSinceBurst >= burstCooldown then
            CooldownLabel:Set("Weapon Status: READY [Press F]")
        else
            CooldownLabel:Set(string.format("Weapon Status: COOLDOWN (%.1fs)", burstCooldown - timeSinceBurst))
        end
    else
        CooldownLabel:Set(isHoldingF and "Weapon Status: FIRING!" or "Weapon Status: READY [Hold F]")
    end

    if (fireMode == "Minigun" or fireMode == "Rain") and isHoldingF then
        if currentTick - lastMinigunShot >= minigunRate then
            lastMinigunShot = currentTick
            if #parts > 0 then
                minigunIndex = (minigunIndex % #parts) + 1
                local partToFire = parts[minigunIndex]
                if partToFire and partToFire.Parent and partToFire ~= carriedPart then
                    if fireMode == "Rain" then
                        local dropPos = Mouse.Hit.Position + Vector3.new(math.random(-15, 15), 100, math.random(-15, 15))
                        partToFire.CFrame = CFrame.new(dropPos)
                        partFireData[partToFire] = {endTime = currentTick + 2, targetVec = Mouse.Hit.Position}
                    else
                        partFireData[partToFire] = {endTime = currentTick + 1.5, targetVec = Mouse.Hit.Position + Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))}
                    end
                end
            end
        end
    end

    local center = Vector3.new()
    local playerLookDir = Vector3.new(0,0,1)
    
    if targetMode == "Mouse" then
        center = Mouse.Hit.Position + Vector3.new(0, elevation, 0)
    elseif targetMode == "Lock-On" and lockedPlayer and lockedPlayer.Character and lockedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        center = lockedPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, elevation - 3, 0)
        playerLookDir = lockedPlayer.Character.HumanoidRootPart.CFrame.LookVector
    else
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            center = hrp.Position + Vector3.new(0, elevation - 3, 0)
            playerLookDir = hrp.CFrame.LookVector
        else return end
    end

    local floorY = -workspace.FallenPartsDestroyHeight
    if antiClipEnabled then floorY = getFloorY(center) end

    local totalParts = #parts
    local timeOffset = currentTick * (rotationSpeed / 5)
    local activeRadius = radius

    if currentPattern == "Pulse" then activeRadius = radius * (1 + 0.3 * math.sin(currentTick * rotationSpeed * 0.5)) end
    local activeY = center.Y
    if currentPattern == "Wave" then activeY = center.Y + (10 * math.sin(currentTick * rotationSpeed * 0.5)) end

    local getJitter = function()
        if currentPattern == "Swarm" then return Vector3.new(math.random(-100,100), math.random(-100,100), math.random(-100,100)) * 0.01 * (activeRadius * 0.2) end
        return Vector3.new()
    end

    if currentShape == "Centipede" or currentShape == "Dragon" then
        local headTarget = center + Vector3.new(
            math.sin(currentTick * 0.6) * activeRadius * 1.5 + math.cos(currentTick * 0.25) * activeRadius * 0.5,
            math.sin(currentTick * 0.8) * activeRadius * 0.5,
            math.cos(currentTick * 0.5) * activeRadius * 1.5 + math.sin(currentTick * 0.35) * activeRadius * 0.5
        )
        if #centipedePath == 0 or (centipedePath[1] - headTarget).Magnitude > pathRecordDist then
            table.insert(centipedePath, 1, headTarget)
            local maxLen = math.max(10, totalParts) 
            if #centipedePath > maxLen then table.remove(centipedePath) end
        end
    end
    
    for i, part in ipairs(parts) do
        if part.Parent and not part.Anchored and part ~= carriedPart then
            
            if showOwnership and selectionBoxes[part] then
                local isOwner = checkOwner(part)
                selectionBoxes[part].SurfaceColor3 = isOwner and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                selectionBoxes[part].Color3 = isOwner and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            end

            local targetPos
            local isFired = false
            
            if partFireData[part] then
                if currentTick < partFireData[part].endTime then
                    targetPos = partFireData[part].targetVec
                    
                    if partFireData[part].isSawblade then
                        local tHit = partFireData[part].targetVec
                        local idx = partFireData[part].index
                        local tot = partFireData[part].total
                        local angle = (idx / tot) * math.pi * 2 + (currentTick * rotationSpeed * 3)
                        targetPos = tHit + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
                    elseif partFireData[part].isLaser then
                        local tHit = partFireData[part].targetVec
                        local sPos = partFireData[part].startPos
                        local idx = partFireData[part].index
                        local tot = partFireData[part].total
                        local dir = (tHit - sPos)
                        if dir.Magnitude > 0 then dir = dir.Unit else dir = Vector3.new(0,1,0) end
                        local dist = (tHit - sPos).Magnitude
                        targetPos = sPos + dir * ((idx / tot) * dist)
                    elseif fireMode == "Orbit Toss" then
                        local timeLeft = partFireData[part].endTime - currentTick
                        if timeLeft < 0.5 then
                            targetPos = Mouse.Hit.Position
                        else
                            local angle = (i / #parts) * math.pi * 2 + (currentTick * rotationSpeed)
                            targetPos = partFireData[part].targetVec + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
                        end
                    end
                    isFired = true
                else
                    partFireData[part] = nil 
                end
            end
            
            if not isFired then
                -- APOCALYPSE SHAPES
                if currentShape == "Ophanim" then
                    local ring1Parts = math.ceil(totalParts / 4)
                    local ring2Parts = ring1Parts
                    local ring3Parts = ring1Parts
                    
                    if i <= ring1Parts then
                        local theta = (i / ring1Parts) * math.pi * 2 + (currentTick * rotationSpeed * 0.5)
                        targetPos = center + (CFrame.Angles(currentTick * 2, 0, 0) * Vector3.new(0, math.cos(theta)*activeRadius, math.sin(theta)*activeRadius))
                    elseif i <= ring1Parts + ring2Parts then
                        local theta = ((i - ring1Parts) / ring2Parts) * math.pi * 2 + (currentTick * rotationSpeed * 0.5)
                        targetPos = center + (CFrame.Angles(0, currentTick * 2, 0) * Vector3.new(math.cos(theta)*activeRadius, 0, math.sin(theta)*activeRadius))
                    elseif i <= ring1Parts + ring2Parts + ring3Parts then
                        local theta = ((i - (ring1Parts*2)) / ring3Parts) * math.pi * 2 + (currentTick * rotationSpeed * 0.5)
                        targetPos = center + (CFrame.Angles(0, 0, currentTick * 2) * Vector3.new(math.cos(theta)*activeRadius, math.sin(theta)*activeRadius, 0))
                    else
                        local jitter = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10)) * 0.05 * activeRadius
                        targetPos = center + jitter
                    end

                elseif currentShape == "Giant Sword" then
                    local bladeCount = math.floor(totalParts * 0.8)
                    local guardCount = math.floor(totalParts * 0.1)
                    local hiltCount = totalParts - bladeCount - guardCount
                    
                    local swordCenter = center - playerLookDir * (activeRadius * 0.5) + Vector3.new(0, activeRadius, 0)
                    local up = Vector3.new(0,1,0)
                    local right = Vector3.new(0,1,0):Cross(playerLookDir).Unit
                    
                    if i <= bladeCount then
                        local p = i / bladeCount
                        targetPos = swordCenter + up * (p * activeRadius * 3)
                    elseif i <= bladeCount + guardCount then
                        local p = (i - bladeCount) / guardCount
                        targetPos = swordCenter + right * ((p - 0.5) * activeRadius * 1.5)
                    else
                        local p = (i - bladeCount - guardCount) / hiltCount
                        targetPos = swordCenter - up * (p * activeRadius * 0.8)
                    end

                elseif currentShape == "Jellyfish" then
                    local domeCount = math.floor(totalParts * 0.4)
                    local tentacleCount = totalParts - domeCount
                    local numTentacles = 6
                    
                    if i <= domeCount then
                        local phi = math.pi * (3 - math.sqrt(5))
                        local y = (i / domeCount) 
                        local r = math.sqrt(1 - y * y)
                        local theta = phi * i + timeOffset
                        targetPos = center + Vector3.new(math.cos(theta)*r, y, math.sin(theta)*r) * activeRadius + Vector3.new(0, activeRadius * 0.5, 0)
                    else
                        local tI = i - domeCount
                        local tentacleId = tI % numTentacles
                        local tParts = math.ceil(tentacleCount / numTentacles)
                        local pProgress = (math.floor(tI / numTentacles)) / math.max(1, tParts)
                        
                        local tAngle = (tentacleId / numTentacles) * math.pi * 2 + (currentTick * rotationSpeed * 0.2)
                        local startPos = center + Vector3.new(math.cos(tAngle), 0, math.sin(tAngle)) * (activeRadius * 0.8) + Vector3.new(0, activeRadius * 0.5, 0)
                        
                        local waveX = math.sin(pProgress * math.pi * 2 + currentTick * rotationSpeed) * (activeRadius * 0.2)
                        local waveZ = math.cos(pProgress * math.pi * 2 + currentTick * rotationSpeed) * (activeRadius * 0.2)
                        
                        targetPos = startPos - Vector3.new(waveX, pProgress * activeRadius * 2, waveZ)
                    end

                elseif currentShape == "Meteor" then
                    local mCenter = center + playerLookDir * (activeRadius * 0.8)
                    local phi = math.pi * (3 - math.sqrt(5))
                    local y = totalParts > 1 and (1 - ((i - 1) / (totalParts - 1)) * 2) or 0
                    local r = math.sqrt(1 - y * y)
                    local theta = phi * i + (currentTick * rotationSpeed * 2)
                    local mRadius = activeRadius * 0.3
                    targetPos = mCenter + Vector3.new(math.cos(theta) * r, y, math.sin(theta) * r) * mRadius

                elseif currentShape == "Halo" then
                    local angle = (i / totalParts) * math.pi * 2 + timeOffset
                    local basePos = Vector3.new(math.cos(angle) * activeRadius, 0, math.sin(angle) * activeRadius)
                    targetPos = center + Vector3.new(0, activeRadius * 0.8, 0) + (CFrame.Angles(math.rad(15), 0, math.rad(-15)) * basePos)

                elseif currentShape == "Aura" then
                    local phi = math.pi * (3 - math.sqrt(5))
                    local y = totalParts > 1 and (1 - ((i - 1) / (totalParts - 1)) * 2) or 0
                    local r = math.sqrt(1 - y * y)
                    local theta = phi * i + (currentTick * rotationSpeed * 2) 
                    local sRad = activeRadius * 0.2 
                    local chaoticJitter = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10)) * 0.05
                    targetPos = center + Vector3.new(math.cos(theta) * r, y, math.sin(theta) * r) * sRad + chaoticJitter

                elseif currentShape == "Vortex" then
                    local yOff = (i / totalParts) * (activeRadius * 2)
                    local r = (yOff / (activeRadius * 2)) * activeRadius * 1.5
                    local theta = (yOff * 0.2) + timeOffset
                    targetPos = center + Vector3.new(math.cos(theta) * r, (activeRadius * 2) - yOff, math.sin(theta) * r) 

                elseif currentShape == "Shield" then
                    local phi = math.pi * (3 - math.sqrt(5))
                    local y = totalParts > 1 and (1 - ((i - 1) / (totalParts - 1)) * 2) or 0
                    local r = math.sqrt(1 - y * y)
                    local theta = phi * i + (currentTick * rotationSpeed) 
                    local sRad = activeRadius * 0.4
                    targetPos = center + Vector3.new(math.cos(theta) * r, y, math.sin(theta) * r) * sRad + Vector3.new(0, 3, 0)

                elseif currentShape == "Crown" then
                    local angle = (i / totalParts) * math.pi * 2 + timeOffset
                    local r = activeRadius * 0.6
                    local spike = math.abs(math.sin(angle * 5)) * (activeRadius * 0.5) 
                    targetPos = center + Vector3.new(math.cos(angle) * r, 5 + spike, math.sin(angle) * r)
                    
                elseif currentShape == "Swords" then
                    local numSwords = 4
                    local swordId = i % numSwords
                    local sParts = math.ceil(totalParts / numSwords)
                    local pProgress = (math.floor(i / numSwords)) / math.max(1, sParts) 
                    local rightVec = Vector3.new(0,1,0):Cross(playerLookDir).Unit
                    local upVec = Vector3.new(0,1,0)
                    local spread = (swordId - (numSwords/2) + 0.5) * (activeRadius * 0.5)
                    local hiltPos = center - playerLookDir * (activeRadius * 0.5) + rightVec * spread + upVec * 2
                    local bladeDir = (upVec * 2 + playerLookDir + rightVec * (spread * 0.05)).Unit
                    targetPos = hiltPos + bladeDir * (pProgress * activeRadius * 2)

                elseif currentShape == "Wings" then
                    local side = (i % 2 == 0) and 1 or -1
                    local wI = math.ceil(i / 2)
                    local halfParts = math.max(1, math.floor(totalParts / 2))
                    local p = wI / halfParts 
                    local rightVector = Vector3.new(0,1,0):Cross(playerLookDir).Unit
                    local wingSpread = rightVector * side * (p * activeRadius * 1.5)
                    local wingBack = -playerLookDir * (activeRadius * 0.2 + p * activeRadius * 0.5)
                    local wingFlap = math.sin(currentTick * rotationSpeed * 0.5 + (p * math.pi)) * (activeRadius * 0.3 * p)
                    local wingCurve = Vector3.new(0, (1 - p) * (activeRadius * 0.5) + wingFlap, 0)
                    targetPos = center + wingSpread + wingBack + wingCurve
                    
                elseif currentShape == "Dragon" then
                    local headCount = math.max(1, math.floor(totalParts * 0.1))
                    local spineCount = math.floor(totalParts * 0.5)
                    local wingCount = totalParts - headCount - spineCount
                    
                    if i <= headCount then
                        local headPos = centipedePath[1] or center
                        targetPos = headPos + Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1)) * (activeRadius * 0.2)
                    elseif i <= headCount + spineCount then
                        local sI = i - headCount
                        local pathLen = #centipedePath
                        local pIndex = math.max(1, math.floor((sI / spineCount) * pathLen))
                        targetPos = centipedePath[pIndex] or center
                    else
                        local wI = i - headCount - spineCount
                        local pathLen = #centipedePath
                        local anchorIndex = math.max(1, math.floor(pathLen * 0.2))
                        local midPos = centipedePath[anchorIndex] or center
                        local nextPos = centipedePath[anchorIndex + 1] or midPos
                        local dir = (midPos - nextPos)
                        if dir.Magnitude < 0.001 then dir = Vector3.new(0,0,1) end
                        dir = dir.Unit
                        local right = Vector3.new(0,1,0):Cross(dir).Unit
                        local up = dir:Cross(right).Unit
                        local side = (wI % 2 == 0) and 1 or -1
                        local p = math.ceil(wI / 2) / math.max(1, math.floor(wingCount / 2))
                        local wLen = right * side * (p * activeRadius * 1.5)
                        local flap = math.sin(currentTick * rotationSpeed + p * 2) * (p * activeRadius * 0.8)
                        targetPos = midPos + wLen + up * flap - dir * (p * activeRadius * 0.5)
                    end

                elseif currentShape == "Rings" then
                    local ringGroup = i % 3
                    local ringParts = math.ceil(totalParts / 3)
                    local theta = (i / ringParts) * math.pi * 2 + (currentTick * rotationSpeed * 0.5)
                    local baseVec = Vector3.new(math.cos(theta)*activeRadius, math.sin(theta)*activeRadius, 0)
                    if ringGroup == 0 then targetPos = center + (CFrame.Angles(math.rad(45), currentTick, 0) * baseVec)
                    elseif ringGroup == 1 then targetPos = center + (CFrame.Angles(0, math.rad(45) + currentTick, 0) * baseVec)
                    else targetPos = center + (CFrame.Angles(0, 0, math.rad(45) + currentTick) * baseVec) end
                    targetPos = targetPos + Vector3.new(0, 3, 0)

                elseif currentShape == "Satellites" then
                    local numMoons = 4
                    local moonId = i % numMoons
                    local moonTheta = (moonId / numMoons) * math.pi * 2 + (currentTick * rotationSpeed * 0.3)
                    local moonCenter = center + Vector3.new(math.cos(moonTheta), 0, math.sin(moonTheta)) * activeRadius + Vector3.new(0, 3, 0)
                    local subParts = math.ceil(totalParts / numMoons)
                    local subTheta = (i / subParts) * math.pi * 2 + (currentTick * rotationSpeed * 1.5)
                    local subRad = activeRadius * 0.2
                    targetPos = moonCenter + Vector3.new(math.cos(subTheta)*subRad, math.sin(subTheta)*subRad, 0)

                elseif currentShape == "Claw" then
                    local palmCount = math.floor(totalParts * 0.3)
                    local fingerCount = totalParts - palmCount
                    local fingers = 4
                    local forward = playerLookDir
                    local right = Vector3.new(0,1,0):Cross(forward).Unit
                    local up = Vector3.new(0,1,0)
                    local clawCenter = center + up * (activeRadius * 0.5)

                    if i <= palmCount then
                        local angle = (i / palmCount) * math.pi * 2
                        targetPos = clawCenter + right * math.cos(angle) * (activeRadius * 0.4) - forward * math.sin(angle) * (activeRadius * 0.4)
                    else
                        local fI = i - palmCount
                        local fingerId = fI % fingers
                        local segment = math.floor(fI / fingers) / (fingerCount / fingers) 
                        local fAngle = (fingerId / fingers) * math.pi * 2 + math.pi/4
                        local fDir = right * math.cos(fAngle) - forward * math.sin(fAngle)
                        local reach = segment * activeRadius
                        local drop = (segment ^ 2) * activeRadius
                        local grasp = math.sin(currentTick * rotationSpeed * 0.5) * 0.5 + 0.5
                        drop = drop + grasp * (segment * activeRadius * 0.8)
                        local inward = fDir * grasp * (segment ^ 2 * activeRadius * 0.8)
                        targetPos = clawCenter + fDir * activeRadius * 0.4 + fDir * reach - up * drop - inward
                    end

                elseif currentShape == "Punch" then
                    local thrust = math.max(0, math.sin(currentTick * rotationSpeed * 0.5)) ^ 6 * (activeRadius * 2.5)
                    local grid = math.ceil(totalParts^(1/3))
                    local x = (i % grid) - grid/2
                    local y = (math.floor(i / grid) % grid) - grid/2
                    local z = (math.floor(i / (grid*grid))) - grid/2
                    local spacing = activeRadius * 0.3
                    local fistCenter = center + playerLookDir * (activeRadius + thrust)
                    local right = Vector3.new(0,1,0):Cross(playerLookDir).Unit
                    targetPos = fistCenter + (right * x * spacing) + (Vector3.new(0,1,0) * y * spacing) + (playerLookDir * z * spacing)

                elseif currentShape == "Plane" then
                    local forward = playerLookDir
                    local right = Vector3.new(0,1,0):Cross(forward).Unit
                    local up = Vector3.new(0,1,0)
                    local fuseCount = math.floor(totalParts * 0.5)
                    local wingCount = math.floor(totalParts * 0.4)
                    local tailCount = totalParts - fuseCount - wingCount

                    if i <= fuseCount then
                        local p = i / fuseCount
                        targetPos = center + forward * ((p - 0.5) * activeRadius * 3)
                    elseif i <= fuseCount + wingCount then
                        local wI = i - fuseCount
                        local p = wI / wingCount
                        local side = (wI % 2 == 0) and 1 or -1
                        targetPos = center + right * side * (p * activeRadius * 2) - forward * (activeRadius * 0.2)
                    else
                        local tI = i - fuseCount - wingCount
                        local p = tI / tailCount
                        targetPos = center - forward * (activeRadius * 1.5) + up * (p * activeRadius * 0.8)
                    end

                elseif currentPattern == "Worm" and currentShape ~= "Centipede" and currentShape ~= "Wings" and currentShape ~= "Dragon" and currentShape ~= "Giant Sword" and currentShape ~= "Jellyfish" then
                    local slitherSpeed = rotationSpeed * 0.05
                    local spacing = 0.15
                    local t = (currentTick * slitherSpeed) - (i * spacing)
                    local slitherRadius = radius + math.sin(t * 3) * (radius * 0.2)
                    targetPos = center + Vector3.new(math.cos(t) * slitherRadius, math.sin(t * 4) * (radius * 0.2), math.sin(t) * slitherRadius)
                else
                    if currentShape == "Atom" then
                        local ringGroup = i % 3
                        local theta = (i / totalParts) * math.pi * 2 + (currentTick * rotationSpeed)
                        if ringGroup == 0 then targetPos = center + Vector3.new(math.cos(theta)*activeRadius, math.sin(theta)*activeRadius, 0)
                        elseif ringGroup == 1 then targetPos = center + Vector3.new(math.cos(theta)*activeRadius, 0, math.sin(theta)*activeRadius)
                        else targetPos = center + Vector3.new(0, math.cos(theta)*activeRadius, math.sin(theta)*activeRadius) end

                    elseif currentShape == "Centipede" then
                        local segmentIndex = math.ceil(i / 3)
                        local pathIdx = math.min(#centipedePath, segmentIndex)
                        local pathPos = centipedePath[pathIdx] or center
                        local nextPos = centipedePath[math.min(#centipedePath, pathIdx + 1)] or pathPos
                        local dir = (pathPos - nextPos)
                        if dir.Magnitude < 0.001 then dir = Vector3.new(0,0,1) end
                        dir = dir.Unit
                        local right = Vector3.new(0,1,0):Cross(dir).Unit
                        local width = activeRadius * 0.3
                        local mod = i % 3
                        if mod == 0 then targetPos = pathPos 
                        elseif mod == 1 then targetPos = pathPos + right * width + dir * math.sin(currentTick * rotationSpeed + segmentIndex) * (width * 0.8)
                        else targetPos = pathPos - right * width + dir * math.sin(currentTick * rotationSpeed + segmentIndex + math.pi) * (width * 0.8) end

                    elseif currentShape == "3D Sphere" or currentShape == "3D Cube" then
                        local phi = math.pi * (3 - math.sqrt(5))
                        local y = totalParts > 1 and (1 - ((i - 1) / (totalParts - 1)) * 2) or 0
                        local r = math.sqrt(1 - y * y)
                        local theta = phi * i
                        local localX, localY, localZ = math.cos(theta) * r, y, math.sin(theta) * r
                        if currentShape == "3D Cube" then
                            local maxAxis = math.max(math.abs(localX), math.abs(localY), math.abs(localZ))
                            localX, localY, localZ = localX / maxAxis, localY / maxAxis, localZ / maxAxis
                        end
                        local rotX = localX * math.cos(timeOffset) - localZ * math.sin(timeOffset)
                        local rotZ = localX * math.sin(timeOffset) + localZ * math.cos(timeOffset)
                        targetPos = center + Vector3.new(rotX * activeRadius, (localY * activeRadius) + activeRadius, rotZ * activeRadius)
                        
                    elseif currentShape == "Tornado" then
                        local yOff = (i / totalParts) * (activeRadius * 2)
                        local r = (yOff / (activeRadius * 2)) * activeRadius * 1.5
                        local theta = (yOff * 0.2) + timeOffset
                        targetPos = center + Vector3.new(math.cos(theta) * r, yOff, math.sin(theta) * r)
                        
                    elseif currentShape == "DNA" then
                        local yOff = (i / totalParts) * (activeRadius * 2)
                        local theta = (yOff * 0.1) + timeOffset
                        local phase = (i % 2 == 0) and 0 or math.pi
                        targetPos = center + Vector3.new(math.cos(theta + phase) * activeRadius * 0.8, yOff, math.sin(theta + phase) * activeRadius * 0.8)
                        
                    elseif currentShape == "Galaxy" then
                        local spiralT = (i / totalParts) * math.pi * 4
                        local r = (spiralT / (math.pi * 4)) * activeRadius
                        local theta = spiralT + timeOffset
                        targetPos = Vector3.new(center.X + math.cos(theta) * r, activeY, center.Z + math.sin(theta) * r)
                        
                    elseif currentShape == "Black Hole" then
                        local inwardT = (currentTick * rotationSpeed + (i / totalParts) * 10) % 10
                        local r = activeRadius * (1 - (inwardT / 10))
                        local theta = inwardT * 2 + timeOffset
                        targetPos = Vector3.new(center.X + math.cos(theta) * r, activeY, center.Z + math.sin(theta) * r)
                        
                    else
                        local angle = math.atan2(part.Position.Z - center.Z, part.Position.X - center.X)
                        local newAngle = angle + math.rad(rotationSpeed)
                        local currentR = activeRadius
                        if currentShape == "Circle" then currentR = activeRadius
                        elseif currentShape == "Star" then
                            local wave = 1 - (math.acos(math.cos(5 * newAngle)) / math.pi)
                            currentR = (activeRadius * 0.2) + ((activeRadius * 0.8) * wave)
                        else
                            local n = 3 
                            if currentShape == "Square" then n = 4
                            elseif currentShape == "Pentagram" then n = 5
                            elseif currentShape == "Hexagon" then n = 6 end
                            local pi_n = math.pi / n
                            currentR = activeRadius * math.cos(pi_n) / math.cos((newAngle % (2 * pi_n)) - pi_n)
                        end
                        targetPos = Vector3.new(center.X + math.cos(newAngle) * currentR, activeY, center.Z + math.sin(newAngle) * currentR)
                    end
                end
            end
            
            targetPos = targetPos + getJitter()

            if antiClipEnabled then
                targetPos = Vector3.new(targetPos.X, math.max(targetPos.Y, floorY + (part.Size.Y/2)), targetPos.Z)
            end

            local distanceVector = targetPos - part.Position
            
            if motionMode == "Fluid" then
                part.Velocity = distanceVector * (attractionStrength * 0.005)
            elseif motionMode == "Ricochet" then
                local ping = math.sin(currentTick * rotationSpeed * 2 + i)
                part.Velocity = distanceVector * (attractionStrength * 0.008) + Vector3.new(ping, -ping, ping) * 20
            else
                if distanceVector.Magnitude > 0 then
                    part.Velocity = distanceVector.Unit * attractionStrength
                else
                    part.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
