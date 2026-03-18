local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Rayfield Initialization
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "God Parts V16 | The Apex Update",
    LoadingTitle = "Initializing God Parts...",
    LoadingSubtitle = "Loading framework...",
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

-- Personalized Welcome Notification
if LocalPlayer.Name == "HeavenlyReminiscence" then
    Rayfield:Notify({
        Title = "Welcome back, Master",
        Content = "<font color='rgb(255, 255, 0)'>HeavenlyReminiscence</font> recognized. Systems optimal.",
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

local targetMode = "Player" 
local currentShape = "Shield" 
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
local centipedePath = {}
local pathRecordDist = 1.5

-- Expanded Lists
local shapesList = {"Shield", "Crown", "Swords", "Rings", "Satellites", "Dragon", "Claw", "Punch", "Plane", "Wings", "Atom", "Centipede", "Circle", "Triangle", "Square", "Pentagram", "Hexagon", "Star", "3D Sphere", "3D Cube", "Tornado", "DNA", "Galaxy", "Black Hole"}
local patternsList = {"Spin", "Wave", "Worm", "Pulse", "Swarm"}
local weaponsList = {"Burst", "Minigun", "Nova", "Rain"}

-- Network Bypass & Part Retention
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
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
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, Part in pairs(Network.BaseParts) do
                if Part:IsDescendantOf(workspace) then
                    Part.Velocity = Network.Velocity
                end
            end
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
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then table.remove(parts, index) end
    partFireData[part] = nil 
    if selectionBoxes[part] then
        selectionBoxes[part]:Destroy()
        selectionBoxes[part] = nil
    end
    if trailsMap[part] then
        trailsMap[part][1]:Destroy()
        trailsMap[part][2]:Destroy()
        trailsMap[part][3]:Destroy()
        trailsMap[part] = nil
    end
end

for _, part in pairs(workspace:GetDescendants()) do addPart(part) end
workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

-- ==== RAYFIELD TABS & ELEMENTS ====

local MainTab = Window:CreateTab("Combat & Shapes", 4483362458) 
local SettingsTab = Window:CreateTab("Adjustments", 4483345998) 
local VisualsTab = Window:CreateTab("Visuals & Info", 4483362875) 

local PartCountLabel = VisualsTab:CreateLabel("Parts Controlled: 0")
local CooldownLabel = MainTab:CreateLabel("Weapon Status: Ready")

MainTab:CreateToggle({
    Name = "Enable God Parts",
    CurrentValue = false,
    Flag = "PowerToggle", 
    Callback = function(Value)
        partsEnabled = Value
    end,
})

MainTab:CreateDropdown({
    Name = "Target Mode",
    Options = {"Player", "Mouse"},
    CurrentOption = {"Player"},
    MultipleOptions = false,
    Flag = "TargetDropdown",
    Callback = function(Option)
        targetMode = Option[1]
    end,
})

MainTab:CreateDropdown({
    Name = "Shape Configuration",
    Options = shapesList,
    CurrentOption = {"Shield"},
    MultipleOptions = false,
    Flag = "ShapeDropdown",
    Callback = function(Option)
        currentShape = Option[1]
        if currentShape == "Centipede" or currentShape == "Dragon" then 
            centipedePath = {} 
        end
    end,
})

MainTab:CreateDropdown({
    Name = "Movement Pattern",
    Options = patternsList,
    CurrentOption = {"Spin"},
    MultipleOptions = false,
    Flag = "PatternDropdown",
    Callback = function(Option)
        currentPattern = Option[1]
    end,
})

MainTab:CreateDropdown({
    Name = "Weapon Mode [Press/Hold F]",
    Options = weaponsList,
    CurrentOption = {"Burst"},
    MultipleOptions = false,
    Flag = "WeaponDropdown",
    Callback = function(Option)
        fireMode = Option[1]
    end,
})

MainTab:CreateDropdown({
    Name = "Physics Motion",
    Options = {"Fluid", "Snap"},
    CurrentOption = {"Fluid"},
    MultipleOptions = false,
    Flag = "MotionDropdown",
    Callback = function(Option)
        motionMode = Option[1]
    end,
})

SettingsTab:CreateSlider({
    Name = "Formation Radius",
    Range = {5, 150},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 30,
    Flag = "RadiusSlider",
    Callback = function(Value)
        radius = Value
    end,
})

SettingsTab:CreateSlider({
    Name = "Elevation Offset",
    Range = {-50, 100},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 0,
    Flag = "ElevSlider",
    Callback = function(Value)
        elevation = Value
    end,
})

SettingsTab:CreateSlider({
    Name = "Rotation Speed",
    Range = {1, 50},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 10,
    Flag = "SpeedSlider",
    Callback = function(Value)
        rotationSpeed = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "Enable Visual Trails",
    CurrentValue = false,
    Flag = "TrailsToggle",
    Callback = function(Value)
        showTrails = Value
        for _, tData in pairs(trailsMap) do tData[3].Enabled = showTrails end
    end,
})

VisualsTab:CreateToggle({
    Name = "Ownership ESP (Green = Yours)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        showOwnership = Value
        for _, box in pairs(selectionBoxes) do box.Visible = showOwnership end
    end,
})

-- Input Handling for Weapons
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not partsEnabled then return end
    if input.KeyCode == Enum.KeyCode.F then
        isHoldingF = true
        local currentTick = tick()
        
        if fireMode == "Burst" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local tHit = Mouse.Hit.Position
                for _, p in ipairs(parts) do
                    partFireData[p] = {
                        endTime = currentTick + 1.5,
                        targetVec = tHit + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
                    }
                end
            end
            
        elseif fireMode == "Nova" then
            if currentTick - lastBurstTime >= burstCooldown then
                lastBurstTime = currentTick
                local center = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()
                for _, p in ipairs(parts) do
                    local outwardDir = (p.Position - center).Unit
                    if outwardDir.Magnitude == 0 then outwardDir = Vector3.new(0,1,0) end
                    partFireData[p] = {
                        endTime = currentTick + 1.5,
                        targetVec = p.Position + outwardDir * (radius * 5)
                    }
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.F then isHoldingF = false end
end)

-- Main Physics & Movement Loop
RunService.Heartbeat:Connect(function()
    if not partsEnabled then return end
    local currentTick = tick()
    
    PartCountLabel:Set("Parts Controlled: " .. #parts)

    if fireMode == "Burst" or fireMode == "Nova" then
        local timeSinceBurst = currentTick - lastBurstTime
        if timeSinceBurst >= burstCooldown then
            CooldownLabel:Set("Weapon Status: READY [Press F]")
        else
            CooldownLabel:Set(string.format("Weapon Status: COOLDOWN (%.1fs)", burstCooldown - timeSinceBurst))
        end
    else
        CooldownLabel:Set(isHoldingF and "Weapon Status: FIRING!" or "Weapon Status: READY [Hold F]")
    end

    -- Minigun / Rain Logic (Continuous Fire)
    if (fireMode == "Minigun" or fireMode == "Rain") and isHoldingF then
        if currentTick - lastMinigunShot >= minigunRate then
            lastMinigunShot = currentTick
            if #parts > 0 then
                minigunIndex = (minigunIndex % #parts) + 1
                local partToFire = parts[minigunIndex]
                if partToFire then
                    if fireMode == "Rain" then
                        -- Teleport high up, then crash down
                        local dropPos = Mouse.Hit.Position + Vector3.new(math.random(-15, 15), 100, math.random(-15, 15))
                        partToFire.CFrame = CFrame.new(dropPos)
                        partFireData[partToFire] = {
                            endTime = currentTick + 2,
                            targetVec = Mouse.Hit.Position
                        }
                    else
                        partFireData[partToFire] = {
                            endTime = currentTick + 1.5,
                            targetVec = Mouse.Hit.Position + Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
                        }
                    end
                end
            end
        end
    end

    local center = Vector3.new()
    local playerLookDir = Vector3.new(0,0,1)
    if targetMode == "Mouse" then
        center = Mouse.Hit.Position + Vector3.new(0, elevation, 0)
    else
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            center = hrp.Position + Vector3.new(0, elevation - 3, 0)
            playerLookDir = hrp.CFrame.LookVector
        else return end
    end

    local totalParts = #parts
    local timeOffset = currentTick * (rotationSpeed / 5)
    local activeRadius = radius

    if currentPattern == "Pulse" then
        activeRadius = radius * (1 + 0.3 * math.sin(currentTick * rotationSpeed * 0.5))
    end
    local activeY = center.Y
    if currentPattern == "Wave" then
        activeY = center.Y + (10 * math.sin(currentTick * rotationSpeed * 0.5))
    end

    local getJitter = function()
        if currentPattern == "Swarm" then
            return Vector3.new(math.random(-100,100), math.random(-100,100), math.random(-100,100)) * 0.01 * (activeRadius * 0.2)
        end
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
        if part.Parent and not part.Anchored then
            
            if showOwnership and selectionBoxes[part] then
                local isOwner = false
                if type(isnetworkowner) == "function" then
                    isOwner = pcall(isnetworkowner, part) and isnetworkowner(part)
                else
                    isOwner = part.ReceiveAge == 0
                end
                if isOwner then
                    selectionBoxes[part].SurfaceColor3 = Color3.fromRGB(0, 255, 0)
                    selectionBoxes[part].Color3 = Color3.fromRGB(0, 255, 0)
                else
                    selectionBoxes[part].SurfaceColor3 = Color3.fromRGB(255, 0, 0)
                    selectionBoxes[part].Color3 = Color3.fromRGB(255, 0, 0)
                end
            end

            local targetPos
            local isFired = false
            
            if partFireData[part] then
                if currentTick < partFireData[part].endTime then
                    targetPos = partFireData[part].targetVec
                    isFired = true
                else
                    partFireData[part] = nil 
                end
            end
            
            if not isFired then
                -- SHAPE CALCULATIONS
                if currentShape == "Shield" then
                    local phi = math.pi * (3 - math.sqrt(5))
                    local y = totalParts > 1 and (1 - ((i - 1) / (totalParts - 1)) * 2) or 0
                    local r = math.sqrt(1 - y * y)
                    local theta = phi * i + (currentTick * rotationSpeed) 
                    local sRad = activeRadius * 0.4
                    targetPos = center + Vector3.new(math.cos(theta) * r, y, math.sin(theta) * r) * sRad + Vector3.new(0, 3, 0)

                elseif currentShape == "Crown" then
                    local angle = (i / totalParts) * math.pi * 2 + timeOffset
                    local r = activeRadius * 0.6
                    local spike = math.abs(math.sin(angle * 5)) * (activeRadius * 0.5) -- 5 peaks
                    targetPos = center + Vector3.new(math.cos(angle) * r, 5 + spike, math.sin(angle) * r)
                    
                elseif currentShape == "Swords" then
                    local numSwords = 4
                    local swordId = i % numSwords
                    local sParts = math.ceil(totalParts / numSwords)
                    local pProgress = (math.floor(i / numSwords)) / math.max(1, sParts) -- 0 to 1 along the blade
                    
                    local rightVec = Vector3.new(0,1,0):Cross(playerLookDir).Unit
                    local upVec = Vector3.new(0,1,0)
                    local spread = (swordId - (numSwords/2) + 0.5) * (activeRadius * 0.5)
                    
                    local hiltPos = center - playerLookDir * (activeRadius * 0.5) + rightVec * spread + upVec * 2
                    local bladeDir = (upVec * 2 + playerLookDir + rightVec * (spread * 0.05)).Unit
                    
                    targetPos = hiltPos + bladeDir * (pProgress * activeRadius * 2)

                elseif currentShape == "Wings" then
                    -- FIXED WINGS MATH: Proportion-based layout
                    local side = (i % 2 == 0) and 1 or -1
                    local wI = math.ceil(i / 2)
                    local halfParts = math.max(1, math.floor(totalParts / 2))
                    local p = wI / halfParts -- Progress along wing (0 to 1)
                    
                    local rightVector = Vector3.new(0,1,0):Cross(playerLookDir).Unit
                    local wingSpread = rightVector * side * (p * activeRadius * 1.5)
                    local wingBack = -playerLookDir * (activeRadius * 0.2 + p * activeRadius * 0.5)
                    local wingFlap = math.sin(currentTick * rotationSpeed * 0.5 + (p * math.pi)) * (activeRadius * 0.3 * p)
                    local wingCurve = Vector3.new(0, (1 - p) * (activeRadius * 0.5) + wingFlap, 0)
                    
                    targetPos = center + wingSpread + wingBack + wingCurve
                    
                elseif currentShape == "Dragon" then
                    -- FIXED DRAGON MATH: Safe indexing and proper proportion linking
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
                        -- Anchor wings to the front 20% of the spine
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
                    if ringGroup == 0 then
                        targetPos = center + (CFrame.Angles(math.rad(45), currentTick, 0) * baseVec)
                    elseif ringGroup == 1 then
                        targetPos = center + (CFrame.Angles(0, math.rad(45) + currentTick, 0) * baseVec)
                    else
                        targetPos = center + (CFrame.Angles(0, 0, math.rad(45) + currentTick) * baseVec)
                    end
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

                elseif currentPattern == "Worm" and currentShape ~= "Centipede" then
                    local slitherSpeed = rotationSpeed * 0.05
                    local spacing = 0.15
                    local t = (currentTick * slitherSpeed) - (i * spacing)
                    local slitherRadius = radius + math.sin(t * 3) * (radius * 0.2)
                    targetPos = center + Vector3.new(math.cos(t) * slitherRadius, math.sin(t * 4) * (radius * 0.2), math.sin(t) * slitherRadius)
                else
                    if currentShape == "Atom" then
                        local ringGroup = i % 3
                        local theta = (i / totalParts) * math.pi * 2 + (currentTick * rotationSpeed)
                        if ringGroup == 0 then
                            targetPos = center + Vector3.new(math.cos(theta)*activeRadius, math.sin(theta)*activeRadius, 0)
                        elseif ringGroup == 1 then
                            targetPos = center + Vector3.new(math.cos(theta)*activeRadius, 0, math.sin(theta)*activeRadius)
                        else
                            targetPos = center + Vector3.new(0, math.cos(theta)*activeRadius, math.sin(theta)*activeRadius)
                        end

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
                        if mod == 0 then
                            targetPos = pathPos 
                        elseif mod == 1 then
                            targetPos = pathPos + right * width + dir * math.sin(currentTick * rotationSpeed + segmentIndex) * (width * 0.8)
                        else
                            targetPos = pathPos - right * width + dir * math.sin(currentTick * rotationSpeed + segmentIndex + math.pi) * (width * 0.8)
                        end

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

            local distanceVector = targetPos - part.Position
            if motionMode == "Fluid" then
                part.Velocity = distanceVector * (attractionStrength * 0.005)
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
