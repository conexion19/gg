local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Nexus active")

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/conexion19/NexusLib-v.1.1.1-/refs/heads/main/gffff"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/conexion19/InterfaceManager-NEW-/refs/heads/main/InterfaceManager.lua"))()

local Player = game:GetService("Players").LocalPlayer

local UserInputService = game:GetService("UserInputService")
local IS_MOBILE = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
local IS_DESKTOP = (UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled)

local windowSize = IS_MOBILE and UDim2.fromOffset(390, 250) or UDim2.fromOffset(605, 355)

local Window = Fluent:CreateWindow({
    Title = "NEXUS",
    SubTitle = "Death Ball",
    Search = false,
    Icon = "",
    TabWidth = 130,
    Size = windowSize,
    Theme = "Slate",
    MinimizeKey = Enum.KeyCode.LeftAlt,
    UserInfoSubtitle = _G.NEXUS_IS_PREMIUM and "Premium" or "Freekey"
})

task.wait(2)

local Tabs = {
    main = Window:AddTab({ Title = "Main", Icon = "home" }),
    rage = Window:AddTab({ Title = "Rage", Icon = "flame" }),
    farm = Window:AddTab({ Title = "BossFarm", Icon = "skull" }),
    skins = Window:AddTab({ Title = "Visual", Icon = "paintbrush" }),
    settings = Window:AddTab({ Title = "Settings", Icon = "settings-2" })
}

local Minimizer

if IS_MOBILE then
    Minimizer = Fluent:CreateMinimizer({
        Icon = "rbxassetid://111390226361567",
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(0, 320, 0, 24),
        Corner = 1,
        Transparency = 1,
        Draggable = true,
        Visible = true
    })
else
    Minimizer = nil  
end

local Options = Fluent.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Encode(str)
    local bytes = {str:byte(1, #str)}
    local pad = (3 - (#bytes % 3)) % 3
    for _ = 1, pad do
        table.insert(bytes, 0)
    end
    local result = {}
    for i = 1, #bytes, 3 do
        local n = bytes[i] * 65536 + bytes[i + 1] * 256 + bytes[i + 2]
        local b1 = math.floor(n / 262144) % 64 + 1
        local b2 = math.floor(n / 4096) % 64 + 1
        local b3 = math.floor(n / 64) % 64 + 1
        local b4 = n % 64 + 1
        table.insert(result, base64Alphabet:sub(b1, b1))
        table.insert(result, base64Alphabet:sub(b2, b2))
        table.insert(result, base64Alphabet:sub(b3, b3))
        table.insert(result, base64Alphabet:sub(b4, b4))
    end
    local encoded = table.concat(result)
    if pad > 0 then
        encoded = encoded:sub(1, #encoded - pad) .. string.rep("=", pad)
    end
    return encoded
end

local function vectorToCipher(vec)
    return base64Encode(string.format("%.3f|%.3f|%.3f", vec.X, vec.Y, vec.Z))
end

local lastCipherTick = 0
local cipherInterval = 0.15


    local camera = Workspace.CurrentCamera
    local player = Players.LocalPlayer
    local autoAbilityEnabled = true
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")


    local autoParryEnabled = false
    local distanceThreshold = 15
    local parryCooldown = 0.1
    local lastParryTime = 0

    local targetBall = nil
    local targetHighlight = nil
    local ballConnection = nil
    local highlightConnection = nil

    local ballData = {
        position = Vector3.new(0, 0, 0),
        lastPosition = Vector3.new(0, 0, 0),
        velocity = Vector3.new(0, 0, 0),
        highlightColor = Color3.new(1, 1, 1),
        lastUpdate = tick(),
        isActive = false
    }

    local function logBallPosition(force)
        if not ballData.isActive then
            return
        end
        local now = tick()
        if not force and now - lastCipherTick < cipherInterval then
            return
        end
        lastCipherTick = now
        print(vectorToCipher(ballData.position))
    end

    local function cleanupConnections()
        if ballConnection then
            ballConnection:Disconnect()
            ballConnection = nil
        end
        if highlightConnection then
            highlightConnection:Disconnect()
            highlightConnection = nil
        end
    end

    local function setupBallTracking(ball)
        cleanupConnections()
        
        targetBall = ball
        targetHighlight = ball:WaitForChild("Highlight", 5)
        if not targetHighlight then return end
        
        ballData.position = ball.Position
        ballData.lastPosition = ball.Position
        ballData.highlightColor = targetHighlight.FillColor
        ballData.lastUpdate = tick()
        ballData.isActive = true
        logBallPosition(true)
        
        ballConnection = ball:GetPropertyChangedSignal("Position"):Connect(function()
            local oldPos = ballData.position
            local newPos = ball.Position
            local currentTime = tick()
            local timeDiff = currentTime - ballData.lastUpdate

            ballData.lastPosition = oldPos
            ballData.position = newPos
            ballData.lastUpdate = currentTime
            
            if timeDiff > 0 then
                ballData.velocity = (newPos - oldPos) / timeDiff
            end
            logBallPosition(false)
        end)
        
        highlightConnection = targetHighlight:GetPropertyChangedSignal("FillColor"):Connect(function()
            ballData.highlightColor = targetHighlight.FillColor
        end)
    end

    local function handleBallRemoval()
        cleanupConnections()
        
        targetBall = nil
        targetHighlight = nil
        ballData.isActive = false
        lastCipherTick = 0
        
    end

    local function findBall()
        local function checkStack(inst)
            return inst:FindFirstChildOfClass("Attachment") or inst:FindFirstChildOfClass("Trail") or inst:FindFirstChildOfClass("ParticleEmitter")
        end
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("BasePart") and (child.Name == "Part" or child.Name == "Ball" or child.Name == "ToroBall" or child.Name == "Part1") then
                if checkStack(child) then
                    setupBallTracking(child)
                    if ballData.isActive then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function quickBallAcquisition(duration)
        local deadline = tick() + (duration or 0.6)
        while autoParryEnabled and not ballData.isActive and tick() < deadline do
            if findBall() and ballData.isActive then
                logBallPosition(true)
                return true
            end
            task.wait(0.02)
        end
        return ballData.isActive
    end

    RunService.Heartbeat:Connect(function()
        if autoParryEnabled and ballData.isActive then
            logBallPosition(false)
        end
    end)

    local function getDistanceToBall()
        if not ballData.isActive or not targetBall then
            return math.huge
        end
        
        local playerCharacter = player.Character
        if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
            return math.huge
        end
        
        local playerPos = playerCharacter.HumanoidRootPart.Position
        return (ballData.position - playerPos).Magnitude
    end

    local autoPingCompensation = false
    local autoSpamEnabled = false

    local function getDistanceToNearestPlayer()
        local lp = Players.LocalPlayer
        if not lp or not lp.Character then return math.huge end
        
        local myRoot = lp.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return math.huge end
        local myPos = myRoot.Position
        
        local closest = math.huge
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist < closest then closest = dist end
                end
            end
        end
        return closest
    end


    local function getNearestHighlightedPlayer()
        local lp = Players.LocalPlayer
        if not lp or not lp.Character then return nil end
        
        local myRoot = lp.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local myPos = myRoot.Position
        
        local closestDist = math.huge
        local closestPlayer = nil
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local char = p.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local highlight = char:FindFirstChild("Highlight")
                    
                    if root and highlight and highlight:IsA("Highlight") and highlight.Enabled then
                        local dist = (root.Position - myPos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestPlayer = p
                        end
                    end
                end
            end
        end
        return closestPlayer, closestDist
    end

    local function isWithinDistance(distance)
        local threshold = 15
        if autoPingCompensation and ballData.velocity then
             local ping = Players.LocalPlayer:GetNetworkPing()
             local speed = ballData.velocity.Magnitude
             threshold = math.clamp(15 + (speed * ping * 0.5), 15, 60) 
        end
        return distance <= threshold
    end

    local function isBallFacingPlayer()
        if not ballData.isActive then return false end
        
        local playerCharacter = player.Character
        local hrp = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local ballPos = ballData.position
        local ballMovementVector = ballData.position - ballData.lastPosition
        
        if ballMovementVector.Magnitude == 0 or ballData.velocity.Magnitude < 2 then return false end 
        
        local vectorToPlayer = (hrp.Position - ballPos).Unit
        local ballDirectionUnit = ballMovementVector.Unit
        
        local directionDot = ballDirectionUnit:Dot(vectorToPlayer)
        return directionDot > 0.43
    end

    local function shouldParry()
        return ballData.isActive and ballData.highlightColor ~= Color3.new(1, 1, 1) and isBallFacingPlayer()
    end

    local function Parry()
        local currentTime = tick()
        
        if currentTime - lastParryTime < parryCooldown then
            return false
        end
        
        local distance = getDistanceToBall()
        if shouldParry() and isWithinDistance(distance) then
            VirtualInputManager:SendKeyEvent(true, "F", false, game)
            VirtualInputManager:SendKeyEvent(false, "F", false, game)
            
            lastParryTime = currentTime
            return true
        end
        
        return false
    end

    local parryHeartbeat = nil
    local parryChildAdded = nil
    local parryChildRemoved = nil

    local AutoParryToggle = Tabs.main:AddToggle("autoparry", {
        Title = "Auto parry",
        Default = true,
        Callback = function(value)
            autoParryEnabled = value
            
            local function StartParryLoop()
                quickBallAcquisition(0.8)
                if parryHeartbeat then parryHeartbeat:Disconnect() end
                
                local lastSearchTime = 0
                local searchCooldown = 1
                local errorCount = 0
                local zeroSpeedStart = 0
                local isSpamming = false

                parryHeartbeat = RunService.Heartbeat:Connect(function()
                    local currentTime = tick()

                    if not ballData.isActive and currentTime - lastSearchTime > searchCooldown then
                        findBall()
                        lastSearchTime = currentTime
                    end

                    if ballData.isActive and (not targetBall or not targetBall.Parent or targetBall.Parent ~= workspace) then
                        handleBallRemoval()
                        lastSearchTime = 0
                    end

                    if ballData.isActive and targetBall then
                        local success, _ = pcall(function() 
                            local _ = targetBall.Position 
                            local _ = targetBall.AssemblyLinearVelocity
                        end)
                        
                        if not success then
                             if parryHeartbeat then parryHeartbeat:Disconnect() parryHeartbeat = nil end
                             cleanupConnections()
                             targetBall = nil
                             ballData.isActive = false

                             task.delay(0.1, function()
                                 if autoParryEnabled then
                                     StartParryLoop()
                                 end
                             end)
                             return
                        end
                        
                        errorCount = 0

                        local distance = getDistanceToBall()
                        local speed = ballData.velocity.Magnitude

                        if speed <= 0.1 then

                        else
                            zeroSpeedStart = 0
                        end

                        if autoSpamEnabled and speed > 10 and ballData.highlightColor ~= Color3.new(1, 1, 1) and distance < 15 then
                            if not isSpamming then
                                isSpamming = true
                                task.spawn(function()
                                    local _, nearestDist = getNearestHighlightedPlayer()
                                    if nearestDist and nearestDist < 20 then
                                        for _ = 1, 55 do
                                            VirtualInputManager:SendKeyEvent(true, "F", false, game)
                                            VirtualInputManager:SendKeyEvent(false, "F", false, game)
                                            task.wait(0.01)
                                        end
                                    end
                                    isSpamming = false
                                end)
                            end
                        end

                        if isWithinDistance(distance) and shouldParry() then
                            Parry()
                        end
                    end
                end)
            end

            if value then
                StartParryLoop()

                parryChildAdded = workspace.ChildAdded:Connect(function(child)
                    if child:IsA("BasePart") and (child.Name == "Part" or child.Name == "Ball" or child.Name == "ToroBall" or child.Name == "Part1") then
                        if not ballData.isActive then
                            if not quickBallAcquisition(0.4) then
                                task.wait(1)
                                if child:FindFirstChildOfClass("Attachment") or child:FindFirstChildOfClass("Trail") or child:FindFirstChildOfClass("ParticleEmitter") then
                                    if not ballData.isActive then
                                        setupBallTracking(child)
                                    end
                                end
                            end
                        end
                    end
                end)
                
                parryChildRemoved = workspace.ChildRemoved:Connect(function(child)
                    if child == targetBall then
                        handleBallRemoval()
                    end
                end)
                
                findBall()
            else
                if parryHeartbeat then parryHeartbeat:Disconnect() parryHeartbeat = nil end
                if parryChildAdded then parryChildAdded:Disconnect() parryChildAdded = nil end
                if parryChildRemoved then parryChildRemoved:Disconnect() parryChildRemoved = nil end
                cleanupConnections()
                targetBall = nil
                ballData.isActive = false
            end
        end
    })

    Tabs.main:AddToggle("AutoPingCompensation", {
        Title = "Auto ping compensation",
        Default = false,
        Callback = function(Value)
            autoPingCompensation = Value
        end
    })

    Tabs.main:AddToggle("AutoSpam", {
        Title = "Auto Spam",
        Default = false,
        Callback = function(Value)
            autoSpamEnabled = Value
        end
    })

    local AutoParryKeybind = Tabs.main:AddKeybind("bind", {
        Title = "Parry Bind",
        Mode = "Toggle",
        Default = "G",
        Callback = function(Value)
            AutoParryToggle:SetValue(not AutoParryToggle.Value)
        end
    })

local player = Players.LocalPlayer
local character = Workspace:FindFirstChild(player.Name)

local deflectButton = player:WaitForChild("PlayerGui"):WaitForChild("HUD"):WaitForChild("HolderBottom"):WaitForChild("ToolbarButtons"):WaitForChild("DeflectButton")

local lastTransparency = deflectButton.BackgroundTransparency
local timerRunning = false
local startTime = 0
local printed90 = false

-- name of abilities 
local allowedAbilities = {
    ["FAKE BALL"] = true, ["ASTRAL PORTAL"] = true, ["CURSED BLUE"] = true,
    ["EXTEND-O ARM"] = true, ["GLASS WALL"] = true,
    ["UPPER CUT"] = true, ["SONIC SLIDE"] = true, ["GROUND WALLS"] = true,
    ["ZAP FREEZE"] = true, ["ZAP DEFLECT"] = true, ["GOD SPEED"] = true,
    ["ASSASSIN INVISIBILITY"] = true, ["LIGHTNING INTERCEPT"] = true,
    ["CHARGED KICK"] = true, ["JUGGLING BLAST"] = true,
    ["LEAP STRIKE"] = true, ["CHAIN SPEAR"] = true, ["HANDGUN"] = true,
    ["DRAGON RUSH"] = true, ["INSTANT TRAVEL"] = true, ["KI BLAST"] = true,
    ["ICE SLIDE"] = true, ["ICE SHIELD"] = true, ["FIRE DASH"] = true, ["FIRE BALL"] = true,
    ["BONK"] = true, ["SIDE STEP"] = true, ["BUNGEE"] = true,
    ["SHADOW RAMPAGE"] = true, ["DREAD SPHERE"] = true, ["PHANTOM GASP"] = true,
    ["ORBITAL CANNON"] = true,
    ["RULERS HOLD"] = true, ["DAGGER DASH"] = true
}

local function isOnCooldown(button)
    return button.BackgroundColor3 == Color3.new(0, 0, 0)
end

local function clickButton(button)
    local pos = button.AbsolutePosition
    local size = button.AbsoluteSize
    local inset = GuiService:GetGuiInset()
    local centerX = pos.X + size.X / 2
    local centerY = pos.Y + size.Y / 2 + inset.Y
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

local function isHighlightValid()
    local highlight = character:FindFirstChild("Highlight")
    if highlight and highlight:IsA("Highlight") then
        return math.abs(highlight.FillTransparency - 0.34) <= 0.001
    end
    return false
end

task.spawn(function()
    while true do
        if autoAbilityEnabled then
            local currentTransparency = deflectButton.BackgroundTransparency
            local now = tick()
            if currentTransparency ~= lastTransparency then
                if not timerRunning then
                    startTime = now
                    timerRunning = true
                    printed90 = false
                else
                    timerRunning = false
                end
                lastTransparency = currentTransparency
            end
            if timerRunning and not printed90 then
                local elapsed = now - startTime
                if elapsed >= 0.8 then
                    if isHighlightValid() then
                        local gui = player:WaitForChild("PlayerGui")
                        local hud = gui:WaitForChild("HUD")
                        local holderBottom = hud:WaitForChild("HolderBottom")
                        local toolbarButtons = holderBottom:WaitForChild("ToolbarButtons")

                        for i = 1, 4 do
                            local button = toolbarButtons:FindFirstChild("AbilityButton" .. i)
                            if button then
                                local nameLabel = button:FindFirstChild("AbilityNameLabel")
                                if nameLabel then
                                    local abilityName = nameLabel.Text
                                    if allowedAbilities[abilityName] and not isOnCooldown(button) then
                                        clickButton(button)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    printed90 = true
                end
            end
        end
        task.wait(0.05)
    end
end)

    Tabs.main:AddToggle("autoability", {
    Title = "Auto ability",
    Default = false,
    Callback = function(value)
        autoAbilityEnabled = value
    end
    })
        
    local autoReadyConnection = nil
    local originalReadyZoneState = nil

    Tabs.main:AddToggle("autoready", {
        Title = "Auto Ready",
        Default = false,
        Callback = function(Value)
            if Value then
                task.spawn(function()
                    local lobby = workspace:WaitForChild("New Lobby", 5)
                    if not lobby then return end
                    local readyArea = lobby:WaitForChild("ReadyArea", 5)
                    if not readyArea then return end
                    local readyZone = readyArea:WaitForChild("ReadyZone", 5)

                    if readyZone and readyZone:IsA("BasePart") then
                        if not originalReadyZoneState or originalReadyZoneState.Part ~= readyZone then
                            originalReadyZoneState = {
                                Part = readyZone,
                                Size = readyZone.Size,
                                Transparency = readyZone.Transparency,
                                CanCollide = readyZone.CanCollide
                            }
                        end
                        
                        local targetSize = originalReadyZoneState.Size * 60
                        
                        if autoReadyConnection then autoReadyConnection:Disconnect() end
                        
                        autoReadyConnection = RunService.Heartbeat:Connect(function()
                            if readyZone and readyZone.Parent then
                                readyZone.Size = targetSize
                                readyZone.CanCollide = false
                                readyZone.Transparency = 1
                            else
                                if autoReadyConnection then
                                    autoReadyConnection:Disconnect()
                                    autoReadyConnection = nil
                                end
                            end
                        end)
                    end
                end)
            else
                if autoReadyConnection then
                    autoReadyConnection:Disconnect()
                    autoReadyConnection = nil
                end
                
                if originalReadyZoneState and originalReadyZoneState.Part and originalReadyZoneState.Part.Parent then
                    originalReadyZoneState.Part.Size = originalReadyZoneState.Size
                    originalReadyZoneState.Part.Transparency = originalReadyZoneState.Transparency
                    originalReadyZoneState.Part.CanCollide = originalReadyZoneState.CanCollide
                end
            end
        end
    })    
    
local fovInicialPadrao = camera and math.clamp(camera.FieldOfView, 70, 120) or 70
local desiredFOV = fovInicialPadrao

local pizda = false

local targetFallback = Vector3.new(568, 280, -782) 
local teleportHeightOffset = -2.5
local prediction = 0.01

local savedBallPosition = nil
local currentBall = nil
local isThreat = false
local wasThreatLastFrame = false
local hasTeleportedToFallback = false
local oneTimeTeleportUsed = false

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

Tabs.main:AddSlider("fov", {
    Title = "FOV Value",
    Default = fovInicialPadrao,
    Min = 70,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        desiredFOV = Value
    end
})

local runService = game:GetService("RunService")
runService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if cam and desiredFOV then
        if cam.FieldOfView ~= desiredFOV then
            cam.FieldOfView = desiredFOV
        end
    end
end)
    
    Tabs.main:AddSlider("maxzoom", {
        Title = "Max Zoom",
        Default = 45,
        Min = 45,
        Max = 200,
        Rounding = 0,
        Callback = function(Value)
            local currentPlayer = Players.LocalPlayer
            if currentPlayer then 
                currentPlayer.CameraMaxZoomDistance = Value 
            end
        end
    })

	local LocalPlayer = Players.LocalPlayer

	local CONFIG = {
		REVIVE_FOLDER_NAME = "ReviveParts",
		TELEPORT_Y_OFFSET = 3,
		TELEPORT_TIMEOUT = 1.8,
		WAIT_AFTER_TP = 0.15,
		WAIT_AFTER_CLICK = 0.2,
		ALIGN_MAX_FORCE = 200000,
		ALIGN_RESPONSIVENESS = 180,
		BOSS_CHECK_INTERVAL = 0.8,
		INITIAL_BOSS_DETECT_DELAY = 3,
		COLLIDER_REMOVE_TOLERANCE = 0.1,
		SPECIFIC_COLLIDER_POS = Vector3.new(463.603, 310.282, 1245.33)
	}

	local bossCoordinates = {
		["VillainMech"] = Vector3.new(476.02, 348.572, 1161.245),
		["TheStatue"] = Vector3.new(462.908, 368.243, 1264.58),
		["CursedSpirit"] = Vector3.new(461.006, 350, 1180.881)
	}

	local currentFarmHeightY = 350
	local autoFarmEnabled = false
	local currentFarmingBossName = nil
	local isFarmMoverActive = false
	local lastKnownFarmCFrame = nil
	local previousDetectedBossInMap = nil
	local bossJustAppeared = false
	local farmAlignPosition, farmRootAttachment = nil, nil
	local autoFarmToggleObject = nil

	local function getCharacterComponents()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		if not (char and hrp and hum and hum.Health > 0) then return nil, nil, nil end
		return char, hrp, hum
	end

	local function destroyFarmMover()
		if not isFarmMoverActive then return end
		isFarmMoverActive = false
		pcall(function() if farmAlignPosition and farmAlignPosition.Parent then farmAlignPosition:Destroy() end end)
		pcall(function() if farmRootAttachment and farmRootAttachment.Parent then farmRootAttachment:Destroy() end end)
		farmAlignPosition, farmRootAttachment = nil, nil
		local _, hrp = getCharacterComponents()
		if hrp then pcall(function() hrp.Anchored = false end) end
	end

	local function arePositionsClose(pos1, pos2, tolerance)
		if not (pos1 and pos2) then return false end
		return (math.abs(pos1.X - pos2.X) <= tolerance) and (math.abs(pos1.Y - pos2.Y) <= tolerance) and (math.abs(pos1.Z - pos2.Z) <= tolerance)
	end

	local function removeSpecificColliderForTheStatue()
		local targetPos, tolerance = CONFIG.SPECIFIC_COLLIDER_POS, CONFIG.COLLIDER_REMOVE_TOLERANCE
		local activeMap = Workspace:FindFirstChild("ActiveMap")
		if not activeMap then return end
		local statueFolder = activeMap:FindFirstChild("TheStatue")
		if not statueFolder then return end
		local playerCollidersFolder = statueFolder:FindFirstChild("PlayerColliders")
		if not playerCollidersFolder then return end
		for _, collider in ipairs(playerCollidersFolder:GetChildren()) do
			if collider:IsA("Part") and arePositionsClose(collider.Position, targetPos, tolerance) then
				pcall(function() collider:Destroy() end)
				break
			end
		end
	end

	local function activateFarm(bossName)
		if not autoFarmEnabled then destroyFarmMover(); return end
		local _, hrp = getCharacterComponents()
		if not hrp then destroyFarmMover(); return end
		local targetBasePos = bossCoordinates[bossName]
		if not targetBasePos then destroyFarmMover(); return end
		local targetPosition = Vector3.new(targetBasePos.X, currentFarmHeightY, targetBasePos.Z)
		if bossName == "TheStatue" then removeSpecificColliderForTheStatue() end
		lastKnownFarmCFrame = hrp.CFrame
		currentFarmingBossName = bossName
		destroyFarmMover()
		local success = pcall(function()
			hrp.Anchored = false
			hrp.Velocity, hrp.RotVelocity = Vector3.zero, Vector3.zero
			hrp.CFrame = CFrame.new(targetPosition)
			task.wait(0.05)
			local _, curHrp = getCharacterComponents()
			if not curHrp then error("Character invalid post TP") end
			farmRootAttachment = Instance.new("Attachment", curHrp)
			farmAlignPosition = Instance.new("AlignPosition", curHrp)
			farmAlignPosition.Attachment0 = farmRootAttachment
			farmAlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
			farmAlignPosition.ApplyAtCenterOfMass = true
			farmAlignPosition.MaxForce = CONFIG.ALIGN_MAX_FORCE
			farmAlignPosition.Responsiveness = CONFIG.ALIGN_RESPONSIVENESS
			farmAlignPosition.Position = targetPosition
			isFarmMoverActive = true
		end)
		if not success then
			destroyFarmMover()
			currentFarmingBossName = nil
			lastKnownFarmCFrame = nil
			if autoFarmEnabled then
				autoFarmEnabled = false
				if autoFarmToggleObject and autoFarmToggleObject.SetValue then pcall(function() autoFarmToggleObject:SetValue(false) end) end
			end
		end
	end

	local function deactivateFarm(returnToLastPosition)
		local lastCFrame = lastKnownFarmCFrame
		destroyFarmMover()
		currentFarmingBossName = nil
		if returnToLastPosition and lastCFrame then
			local _, hrp = getCharacterComponents()
			if hrp then
				pcall(function() hrp.Anchored = false; hrp.CFrame = lastCFrame; task.wait(0.1); hrp.Anchored = false end)
			end
		end
		lastKnownFarmCFrame = nil
	end

	task.spawn(function()
		 while task.wait(CONFIG.BOSS_CHECK_INTERVAL) do
			 local char, hrp, hum = getCharacterComponents()
			 if not char then
				 if currentFarmingBossName then deactivateFarm(false) end
				 previousDetectedBossInMap = nil; continue
			 end
			 local activeMap = Workspace:FindFirstChild("ActiveMap")
			 local bossFoundInMap = nil
			 if activeMap then
				 for name, _ in pairs(bossCoordinates) do if activeMap:FindFirstChild(name) then bossFoundInMap = name; break end end
			 end
			 if bossFoundInMap ~= previousDetectedBossInMap then
				 if bossFoundInMap then
					 if autoFarmEnabled then bossJustAppeared = true
					 else destroyFarmMover(); currentFarmingBossName = nil
					 end
				 elseif currentFarmingBossName then deactivateFarm(false)
				 end
				 previousDetectedBossInMap = bossFoundInMap
			 end
			 if autoFarmEnabled and bossFoundInMap then
				 if currentFarmingBossName ~= bossFoundInMap or not isFarmMoverActive then
					 if bossJustAppeared then
						 task.wait(CONFIG.INITIAL_BOSS_DETECT_DELAY)
						 bossJustAppeared = false
						 if not autoFarmEnabled then continue end
						 local _, hrpAfterDelay, _ = getCharacterComponents(); if not hrpAfterDelay then continue end
						 local currentMapCheckAfterDelay = Workspace:FindFirstChild("ActiveMap")
						 local bossStillThere = currentMapCheckAfterDelay and currentMapCheckAfterDelay:FindFirstChild(bossFoundInMap)
						 if not bossStillThere then previousDetectedBossInMap = nil; continue end
						 activateFarm(bossFoundInMap)
					 else activateFarm(bossFoundInMap)
					 end
				 end
			 elseif not bossFoundInMap and currentFarmingBossName then deactivateFarm(false)
			 end
			 if not autoFarmEnabled or not bossFoundInMap then bossJustAppeared = false end
		 end
	end)

	autoFarmToggleObject = Tabs.farm:AddToggle("AutoFarmToggle", {Title = "Auto farm", Default = false, Callback = function(value)
		if autoFarmEnabled == value then return end
		autoFarmEnabled = value
		if value then
			local _, hrp, _ = getCharacterComponents()
			if not hrp then
				autoFarmEnabled = false
				if autoFarmToggleObject and autoFarmToggleObject.SetValue then pcall(function() autoFarmToggleObject:SetValue(false) end) end
				return
			end
			local activeMap = Workspace:FindFirstChild("ActiveMap")
			local bossAlreadyPresent = nil
			if activeMap then for name,_ in pairs(bossCoordinates) do if activeMap:FindFirstChild(name) then bossAlreadyPresent = name; break end end end
			if bossAlreadyPresent then activateFarm(bossAlreadyPresent) else destroyFarmMover(); currentFarmingBossName = nil end
		else deactivateFarm(true) end
	end})

	Tabs.farm:AddSlider("HeightSlider", {Title = "Farm height", Description = "высота фарма", Default = 350, Min = 300, Max = 380, Rounding = 0, Callback = function(value)
		currentFarmHeightY = math.floor(value + 0.5)
		if isFarmMoverActive and currentFarmingBossName and farmAlignPosition then
			local bossBasePos = bossCoordinates[currentFarmingBossName]
			if bossBasePos then
				local newTargetPos = Vector3.new(bossBasePos.X, currentFarmHeightY, bossBasePos.Z)
				pcall(function() farmAlignPosition.Position = newTargetPos end)
				local _, hrp = getCharacterComponents()
				if hrp then pcall(function() hrp.CFrame = CFrame.new(hrp.Position.X, newTargetPos.Y, hrp.Position.Z) end) end
			end
		end
	end})
	pcall(function() local sliderObj = Tabs.farm.Sections and Tabs.farm.Sections.AutoFarm and Tabs.farm.Sections.AutoFarm.Controls and Tabs.farm.Sections.AutoFarm.Controls.HeightSlider; if sliderObj and sliderObj.Value then currentFarmHeightY = math.floor(sliderObj.Value + 0.5) end end)

	Tabs.farm:AddButton({ Title = "Revive all", Callback = function()
		local RevivePlayers = game:GetService("Players")
		local ReviveWorkspace = game:GetService("Workspace")
		local reviveFolderName = CONFIG.REVIVE_FOLDER_NAME
		local localPlayerRevive = RevivePlayers.LocalPlayer
		local _, hrpBeforeRevive = getCharacterComponents()
		local cframeBeforeRevive = hrpBeforeRevive and hrpBeforeRevive.CFrame
		local returnCFrame = (autoFarmEnabled and lastKnownFarmCFrame) or cframeBeforeRevive
		local reviveAlignPos, reviveAttach = nil, nil

		local function destroyReviveMover()
			 pcall(function() if reviveAlignPos and reviveAlignPos.Parent then reviveAlignPos:Destroy() end end)
			 pcall(function() if reviveAttach and reviveAttach.Parent then reviveAttach:Destroy() end end)
			 reviveAlignPos, reviveAttach = nil, nil
			 local _, hrp = getCharacterComponents(); if hrp then pcall(function() hrp.Anchored = false end) end
		end
		local function teleportRevive(targetPos)
			 local _, hrp = getCharacterComponents(); if not hrp then return false end
			 destroyFarmMover(); destroyReviveMover()
			 local success, arrived = pcall(function()
				 hrp.Anchored = false; hrp.Velocity, hrp.RotVelocity = Vector3.zero, Vector3.zero
				 reviveAttach = Instance.new("Attachment", hrp)
				 reviveAlignPos = Instance.new("AlignPosition", hrp)
				 reviveAlignPos.Attachment0 = reviveAttach
				 reviveAlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
				 reviveAlignPos.ApplyAtCenterOfMass = true
				 reviveAlignPos.MaxForce = CONFIG.ALIGN_MAX_FORCE
				 reviveAlignPos.Responsiveness = CONFIG.ALIGN_RESPONSIVENESS
				 reviveAlignPos.Position = targetPos
				 hrp.CFrame = CFrame.new(targetPos)
				 local startTime, currentDist = tick(), (hrp.Position - targetPos).Magnitude
				 while currentDist > 4 and (tick() - startTime) < CONFIG.TELEPORT_TIMEOUT do
					 task.wait()
					 local _, curHrp = getCharacterComponents(); if not curHrp then error("Character invalid during revive TP wait") end
					 currentDist = (curHrp.Position - targetPos).Magnitude
				 end
				 destroyReviveMover()
				 return currentDist <= 4
			 end)
			 if not success then destroyReviveMover(); return false end
			 return arrived
		end
		local function doReviveSequence()
			 local _, hrp = getCharacterComponents(); if not hrp then return end
			 local revivePartsFolder = ReviveWorkspace:FindFirstChild(reviveFolderName); if not revivePartsFolder then return end
			 local prompts = {}
			 for _, obj in ipairs(revivePartsFolder:GetDescendants()) do
				 if obj:IsA("ProximityPrompt") then
					 local partParent = obj.Parent
					 if partParent and partParent:IsA("BasePart") then table.insert(prompts, {prompt = obj, pos = partParent.Position}); pcall(function() obj.HoldDuration = 0 end) end
				 end
			 end
			 if #prompts == 0 then return end
			 for _, data in ipairs(prompts) do
				 if teleportRevive(data.pos + Vector3.new(0, CONFIG.TELEPORT_Y_OFFSET, 0)) then
					 task.wait(CONFIG.WAIT_AFTER_TP)
					 local clickSuccess = pcall(function() if typeof(fireproximityprompt) == "function" then fireproximityprompt(data.prompt) else data.prompt:InputHoldBegin(); task.wait(0.05); data.prompt:InputHoldEnd() end end)
					 task.wait(CONFIG.WAIT_AFTER_CLICK)
				 end
				 local _, curHrp = getCharacterComponents(); if not curHrp then destroyReviveMover(); return end
			 end
			 if returnCFrame then
				 if teleportRevive(returnCFrame.Position) then
					 task.wait(0.1)
					 local _, finalHrp = getCharacterComponents()
					 if finalHrp then pcall(function() finalHrp.CFrame = returnCFrame end) end
					 destroyReviveMover()
					 if autoFarmEnabled and currentFarmingBossName then task.spawn(activateFarm, currentFarmingBossName) end
				 else destroyReviveMover() end
			 else destroyReviveMover() end
		end
		local char, hrp, hum = getCharacterComponents()
		if char and hrp and hum then task.spawn(doReviveSequence)
		else
			local conn; conn = localPlayerRevive.CharacterAdded:Once(function(newChar) local newHum = newChar:WaitForChild("Humanoid", 5); if newHum then task.wait(0.5); if newHum.Health > 0 then task.spawn(doReviveSequence) end end end)
			task.delay(20, function() if conn and conn.Connected then conn:Disconnect() end end)
		end
	end})

	local ballRemovedConnection = Workspace.ChildRemoved:Connect(function(child)
		if child.Name == "Ball" and autoFarmEnabled then
			autoFarmEnabled = false
			if autoFarmToggleObject and autoFarmToggleObject.SetValue then pcall(function() autoFarmToggleObject:SetValue(false) end) end
			deactivateFarm(true)
		end
	end)

    local swordsData = {
        { Name = "Drakos", WeldCFrame = CFrame.new(0, -1, -4.2) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Diamond Shardblade", WeldCFrame = CFrame.new(0, -1, -4.3) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Champion Scythe", WeldCFrame = CFrame.new(0, 0, -3.5) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(200)) },
        { Name = "Diamond Aegis", WeldCFrame = CFrame.new(0, -1.5, -5.3) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Demonic Shadow", WeldCFrame = CFrame.new(0, -1, -2.8) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Okiro", WeldCFrame = CFrame.new(0, -0.8, -3) * CFrame.Angles(math.rad(100), math.rad(85), math.rad(180)) },
        { Name = "Divine Shadow", WeldCFrame = CFrame.new(0, -1.5, -6) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Darkness", WeldCFrame = CFrame.new(0, -1, -4.5) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Divine Slayer", WeldCFrame = CFrame.new(0, -1, -4.8) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Amethyst Oblivion", WeldCFrame = CFrame.new(0, -1, -4.3) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Lotus Oblivion", WeldCFrame = CFrame.new(0, -1, -4.3) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Colossal Blazehead", WeldCFrame = CFrame.new(0, -0.4, -4.3) * CFrame.Angles(math.rad(100), math.rad(85), math.rad(180)) },
        { Name = "Enigma", WeldCFrame = CFrame.new(0, -0.9, -2.8) * CFrame.Angles(math.rad(110), math.rad(85), math.rad(180)) },
        { Name = "Cyber Enigma", WeldCFrame = CFrame.new(0.1, -1.3, -2.7) * CFrame.Angles(math.rad(0), math.rad(85), math.rad(-78)) },
        { Name = "Lumina", WeldCFrame = CFrame.new(0, -1, -4.3) * CFrame.Angles(math.rad(92), math.rad(85), math.rad(180)) },
        { Name = "Cyber Hammer", WeldCFrame = CFrame.new(0, -1, -4.3) * CFrame.Angles(math.rad(92), math.rad(85), math.rad(180)) },
        { Name = "Hikaru Axe", WeldCFrame = CFrame.new(0, -0.8, -2.2) * CFrame.Angles(math.rad(110), math.rad(85), math.rad(180)) },
        { Name = "Diamond Inception", WeldCFrame = CFrame.new(0, -0.8, -2.2) * CFrame.Angles(math.rad(110), math.rad(85), math.rad(180)) },
        { Name = "Golden Embrace", WeldCFrame = CFrame.new(0, -1, -2.8) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Black Nichi", WeldCFrame = CFrame.new(0, -1, -2.8) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Dizzy", WeldCFrame = CFrame.new(0, -1, -2.8) * CFrame.Angles(math.rad(90), math.rad(85), math.rad(180)) },
        { Name = "Rainbow Chaos", WeldCFrame = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(100), math.rad(180)) },
        { Name = "Penis", WeldCFrame = CFrame.new(0, -1, -2.8) * CFrame.Angles(math.rad(100), math.rad(85), math.rad(180)) },
        { Name = "Radiant Strike", WeldCFrame = CFrame.new(0, -0.4, -2.8) * CFrame.Angles(math.rad(100), math.rad(85), math.rad(180)) },
        { Name = "Divine Talon", WeldCFrame = CFrame.new(0, -0.2, -2) * CFrame.Angles(math.rad(110), math.rad(85), math.rad(180)) },
    }

    local swordsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Swords")
    local activeSwordsFolder = Workspace:FindFirstChild("ActiveSwords") or Instance.new("Folder")
    activeSwordsFolder.Name = "ActiveSwords"; activeSwordsFolder.Parent = Workspace
    local storageFolder = ReplicatedStorage:FindFirstChild("SwordStorage_"..Players.LocalPlayer.UserId) or Instance.new("Folder")
    storageFolder.Name = "SwordStorage_"..Players.LocalPlayer.UserId; storageFolder.Parent = ReplicatedStorage

    local equippedCustomSwordMap = {}
    local originalSwordFolderName = Players.LocalPlayer.Name .. " SwordWelds"
    local localPlayer = Players.LocalPlayer
    local mainSwordPartName = "Sword"
    local mainSwordWeldName = "Weld"

    local function cleanupCustomPlayerSword(player)
        local oldSword = equippedCustomSwordMap[player]
        if oldSword and oldSword.Parent then pcall(function() oldSword:Destroy() end) end
        equippedCustomSwordMap[player] = nil 
    end

    local function findAndMoveOriginalSwordToStorage()
        local movedSomething = false
        storageFolder:ClearAllChildren()
        local sourceFolder = nil
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name == originalSwordFolderName and child:IsA("Folder") and #child:GetChildren() > 0 then
                sourceFolder = child; break
            end
        end
        if sourceFolder then
            for _, potentialDuplicate in ipairs(Workspace:GetChildren()) do
                if potentialDuplicate.Name == originalSwordFolderName and potentialDuplicate:IsA("Folder") and potentialDuplicate ~= sourceFolder then
                    pcall(function() potentialDuplicate:Destroy() end)
                end
            end
            local itemsToMove = sourceFolder:GetChildren()
            for _, item in ipairs(itemsToMove) do item.Parent = storageFolder; movedSomething = true end
            return movedSomething
        end
        local looseItemsToMove = {}
        local looseSwordPart = Workspace:FindFirstChild(mainSwordPartName)
        if looseSwordPart and looseSwordPart.Parent == Workspace and looseSwordPart:IsA("BasePart") then
             table.insert(looseItemsToMove, looseSwordPart)
             local looseWeld = Workspace:FindFirstChild(mainSwordWeldName)
             if looseWeld and looseWeld.Parent == Workspace and looseWeld:IsA("Weld") then
                  table.insert(looseItemsToMove, looseWeld)
             end
        end
        if #looseItemsToMove > 0 then
            for _, item in ipairs(looseItemsToMove) do item.Parent = storageFolder; movedSomething = true end
        end
        return movedSomething
    end

    local function moveOriginalSwordBackToFolder()
        local itemsInStorage = storageFolder:GetChildren()
        if #itemsInStorage == 0 then return true end
        local targetFolder = Workspace:FindFirstChild(originalSwordFolderName)
        if not targetFolder or not targetFolder:IsA("Folder") then
             if targetFolder then pcall(function() targetFolder:Destroy() end) end
            targetFolder = Instance.new("Folder")
            targetFolder.Name = originalSwordFolderName
            targetFolder.Parent = Workspace
        end
        local success = false; local itemsMoved = 0
        for _, child in ipairs(itemsInStorage) do
            child.Parent = targetFolder
            if child.Parent == targetFolder then itemsMoved = itemsMoved + 1 end
            task.wait()
        end
        if #storageFolder:GetChildren() == 0 and itemsMoved > 0 then success = true end
        return success
    end

    local function equipCustomSword(swordName, weldCFrame)
        if not localPlayer then return end

        local currentlyEquipped = equippedCustomSwordMap[localPlayer]
        local originalWasMoved = false 

        if not currentlyEquipped then
            originalWasMoved = findAndMoveOriginalSwordToStorage()
        end

        cleanupCustomPlayerSword(localPlayer) 

        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
        if not hand then
            if originalWasMoved then moveOriginalSwordBackToFolder() end
            return
        end

        local swordModel = swordsFolder:FindFirstChild(swordName)
        local swordPart = swordModel and swordModel:FindFirstChild("Sword")
        if not swordPart then
            if originalWasMoved then moveOriginalSwordBackToFolder() end
            return
        end

        local newSword = swordPart:Clone(); newSword.Name = localPlayer.Name .. "_CustomSword_" .. swordName
        newSword.Anchored = false; newSword.CanCollide = false; newSword.Massless = true
        for _, part in ipairs(newSword:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false; part.Massless = true; part.Anchored = false end
        end
        local weld = Instance.new("Weld"); weld.Name = "HandWeld"; weld.Part0 = hand; weld.Part1 = newSword
        weld.C0 = weldCFrame; weld.Parent = newSword
        newSword.Parent = activeSwordsFolder
        equippedCustomSwordMap[localPlayer] = newSword
    end

    Players.PlayerRemoving:Connect(function(player)
        if player == localPlayer then
            local moveSucceeded = moveOriginalSwordBackToFolder()
            cleanupCustomPlayerSword(player) 
            if moveSucceeded and storageFolder and storageFolder.Parent then
                storageFolder:ClearAllChildren()
            end
        else
             cleanupCustomPlayerSword(player)
        end
    end)

    Tabs.skins:AddSection("Sword")
    local swordOptions = {"Default"}
    for _, sword in ipairs(swordsData) do table.insert(swordOptions, sword.Name) end

    Tabs.skins:AddDropdown("SwordSelector", {
        Title = "Select sword", Values = swordOptions, Default = "Default",
        Callback = function(Value)
            if Value == "Default" then
                cleanupCustomPlayerSword(localPlayer)
                moveOriginalSwordBackToFolder()   
            else
                for _, sword in ipairs(swordsData) do
                    if sword.Name == Value then
                         equipCustomSword(sword.Name, sword.WeldCFrame) 
                         break
                    end
                end
            end
        end
    })

    if storageFolder and #storageFolder:GetChildren() > 0 then
         moveOriginalSwordBackToFolder()
    end
    if equippedCustomSwordMap[localPlayer] and (not equippedCustomSwordMap[localPlayer].Parent) then
         equippedCustomSwordMap[localPlayer] = nil
    end


local rootPart = nil

local function enableFly()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

    if flyConnection then flyConnection:Disconnect() end
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not rootPart then return end

        local camCF = workspace.CurrentCamera.CFrame
        local moveVec = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec = moveVec + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec = moveVec - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec = moveVec - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec = moveVec + camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec = moveVec + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVec = moveVec - Vector3.new(0, 1, 0)
        end

        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit * flySpeed
        end

        rootPart.Velocity = moveVec
        rootPart.Anchored = moveVec.Magnitude == 0
    end)
end

local function disableFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Anchored = false
        end
    end
end

Tabs.main:AddToggle("flyToggle", {
    Title = "Fly",
    Default = false,
    Callback = function(value)
        flyEnabled = value
        if value then
            enableFly()
        else
            disableFly()
        end
    end
})

Tabs.main:AddSlider("flySpeed", {
    Title = "Fly speed",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        flySpeed = value
    end
})

    
    local autoCurveEnabled = false
    local rageConnections = {}
    local originalStates = {
        InfJump = nil,
        NoDash = nil,
        NoParry = nil
    }

    local function GetPlayerControl()
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local Classes = ReplicatedFirst:FindFirstChild("Classes")
        if not Classes then return nil end
        
        local PlayerControl = Classes:FindFirstChild("PlayerControl")
        if not PlayerControl then return nil end
        
        local success, result = pcall(require, PlayerControl)
        if success then return result end
        return nil
    end

    local function ToggleLoop(name, callback)
        if rageConnections[name] then
            rageConnections[name]:Disconnect()
            rageConnections[name] = nil
        end
        if callback then
            rageConnections[name] = RunService.Heartbeat:Connect(callback)
        end
    end

    local ReplicateCamLook = game:GetService("ReplicatedStorage"):FindFirstChild("ReplicateCamLook")
    if ReplicateCamLook then
        local mtHook
        mtHook = hookmetamethod(game, "__namecall", function(...)
            local self = ...
            if getnamecallmethod() == "FireServer" and self == ReplicateCamLook and autoCurveEnabled then
                local args = table.pack(...)
                args[2] = math.random() * 2 - 1
                args[3] = math.random() * 2 - 1
                args[4] = math.random() * 2 - 1
                return mtHook(table.unpack(args))
            end
            return mtHook(...)
        end)
        
        local oldFireServer
        oldFireServer = hookfunction(ReplicateCamLook.FireServer, function(...)
            local self = ...
            if self == ReplicateCamLook and autoCurveEnabled then
                local args = table.pack(...)
                args[2] = math.random() * 2 - 1
                args[3] = math.random() * 2 - 1
                args[4] = math.random() * 2 - 1
                return oldFireServer(table.unpack(args))
            end
            return oldFireServer(...)
        end)
    end

    Tabs.rage:AddToggle("InfiniteDoubleJump", {
        Title = "Infinite Double Jump",
        Default = false,
        Callback = function(Value)
            local control = GetPlayerControl()
            
            if Value then
                if not control or not control.Movement then return end
                
                if not originalStates.InfJump then
                    originalStates.InfJump = {
                        ExtraJumpCount = control.Movement.ExtraJumpCount,
                        UsedJumpCount = control.Movement.UsedJumpCount,
                        ReadyForDoubleJump = control.Movement.ReadyForDoubleJump
                    }
                end
                
                ToggleLoop("InfJump", function()
                    if control and control.Movement then
                        control.Movement.UsedJumpCount = 0
                        control.Movement.ExtraJumpCount = 999
                        control.Movement.ReadyForDoubleJump = true
                    end
                end)
            else
                ToggleLoop("InfJump", nil)
                
                if control and control.Movement and originalStates.InfJump then
                    control.Movement.ExtraJumpCount = originalStates.InfJump.ExtraJumpCount
                    control.Movement.UsedJumpCount = originalStates.InfJump.UsedJumpCount
                    control.Movement.ReadyForDoubleJump = originalStates.InfJump.ReadyForDoubleJump
                    originalStates.InfJump = nil
                end
            end
        end
    })

    Tabs.rage:AddToggle("NoDashCooldown", {
        Title = "No Dash Cooldown",
        Default = false,
        Callback = function(Value)
            local control = GetPlayerControl()

            if Value then
                if not control or not control.Movement then return end
                
                if not originalStates.NoDash then
                     originalStates.NoDash = {
                        IsDashOnCooldown = control.Movement.IsDashOnCooldown,
                        DashCooldown = control.Movement.DashCooldown
                     }
                end

                ToggleLoop("NoDash", function()
                    if control and control.Movement then
                        control.Movement.IsDashOnCooldown = false
                        control.Movement.DashCooldown = 0
                    end
                end)
            else
                ToggleLoop("NoDash", nil)
                
                if control and control.Movement and originalStates.NoDash then
                    control.Movement.IsDashOnCooldown = originalStates.NoDash.IsDashOnCooldown
                    control.Movement.DashCooldown = originalStates.NoDash.DashCooldown
                    originalStates.NoDash = nil
                end
            end
        end
    })

    Tabs.rage:AddToggle("NoParryCooldown", {
        Title = "No Parry Cooldown",
        Default = false,
        Callback = function(Value)
            local control = GetPlayerControl()

            if Value then
                if not control or not control.Sword then return end

                ToggleLoop("NoParry", function()
                    if control and control.Sword and control.Sword.Cooldown == true then
                        control.Sword.Cooldown = false
                        control.Sword.Ready = true
                    end
                end)
            else
                ToggleLoop("NoParry", nil)
            end
        end
    })

    Tabs.rage:AddToggle("AutoCurve", {
        Title = "Auto Curve",
        Default = false,
        Callback = function(Value)
            autoCurveEnabled = Value
        end
    })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("NEXUS")
SaveManager:SetFolder("Nexus/DeathBall")
InterfaceManager:BuildInterfaceSection(Tabs.settings)
SaveManager:BuildConfigSection(Tabs.settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
