if not _G.NEXUS_LOADER_AUTH then
    error("Access denied: Script must be loaded through Nexus loader")
end
_G.NEXUS_LOADER_AUTH = nil


local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = require(ReplicatedStorage.Actions)

local OldMeta = getmetatable(Actions)
local OldIndex = OldMeta and OldMeta.__index

local NewMeta = {
    __index = function(Table, Key)
        if type(Key) == "number" and (Key == 5 or Key == 503) then
            return function() end
        end
        if OldIndex then
            return OldIndex(Table, Key)
        end
        return rawget(Table, Key)
    end,
    __newindex = OldMeta and OldMeta.__newindex or function(Table, Key, Value)
        rawset(Table, Key, Value)
    end
}

for Key, Value in pairs(OldMeta or {}) do
    if Key ~= "__index" and Key ~= "__newindex" then
        NewMeta[Key] = Value
    end
end

setmetatable(Actions, NewMeta)

local OldNewIndex
OldNewIndex = hookmetamethod(game, "__newindex", function(Instance, Property, Value)
    if Property == "Parent" and Value == workspace.CurrentCamera then
        if Instance:IsA("Folder") and Instance.Name == "Folder" then
            return
        end
    end
    return OldNewIndex(Instance, Property, Value)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local platform = UserInputService:GetPlatform()

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/conexion19/NexusLib-v.1.1.1-/refs/heads/main/gffff"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/conexion19/InterfaceManager-NEW-/refs/heads/main/InterfaceManager.lua"))()

local IS_MOBILE = platform == Enum.Platform.IOS or platform == Enum.Platform.Android
local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")

local UserInfoSubtitle = _G.NEXUS_SUBTITLE or (_G.NEXUS_IS_PREMIUM and "Premium" or "Freemium")

local windowSize = IS_MOBILE and UDim2.fromOffset(550,350) or UDim2.fromOffset(635, 370)

local Window = Fluent:CreateWindow({
    Title = "NEXUS",
    SubTitle = "Death Ball",
    Search = false,
    Icon = "",
    TabWidth = 130,
    Size = windowSize,
    Theme = "Slate",
    MinimizeKey = Enum.KeyCode.LeftAlt,
    UserInfoSubtitle = UserInfoSubtitle})

local Tabs = {
    main = Window:AddTab({ Title = "Main", Icon = "home" }),
    rage = Window:AddTab({ Title = "Rage", Icon = "flame" }),
    movement = Window:AddTab({ Title = "Movement", Icon = "move" }),
    farm = Window:AddTab({ Title = "BossFarm", Icon = "skull" }),
    skins = Window:AddTab({ Title = "Visual", Icon = "paintbrush" }),
    settings = Window:AddTab({ Title = "Settings", Icon = "settings-2" })
}

Tabs.main:AddParagraph({
    Title = "Welcome",
    Content = "Thank you for being with us!\nUse the toggles below to configure features."
})

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

    local camera = Workspace.CurrentCamera
    local player = Players.LocalPlayer
    local autoAbilityEnabled = false
    

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
        return distance <= 15
    end

    local AutoParry = {
        connection = nil,
        isActive = false,
    
        _Services = {
            ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage")),
            Players = cloneref(game:GetService("Players")),
            Workspace = cloneref(game:GetService("Workspace")),
            RunService = cloneref(game:GetService("RunService"))
        },
        _Bitbuf = nil,
        _LocalPlayer = nil,
        _ActionRemote = nil,
        _LastPayload = nil,
        _LastPayloadTime = 0,
        _MaxPayloadAge = 0.5,
        _CachedMapOffset = nil,
        _ParryCooldown = 0.02,
        _HitboxRadius = 3.5,
        _HitboxHeight = 5.0,
        _CLASH_RADIUS = 9.0,
        _DASH_DANGER_DIST = 18.0,
        _DASH_DETECT_THRESHOLD = 600,
        _CLASH_COOLDOWN_BYPASS = 0.12,
        _CLASH_APPROACHING_DOT = -0.3,
        _TBIT_PAST_MARGIN = 0.08,
        _GravityVec = nil,
        _PING_WINDOW_SIZE = 16,
        _PingWindow = nil,
        _PingHead = 0,
        _PingCount = 0,
        _SmoothedPing = 0,
        _PingJitter = 0,
        _OneWayLatency = 0,
        _FRAME_BUDGET = 1 / 60,
        _FREEZE_DROP_RATIO = 0.08,
        _FREEZE_MIN_PREV_SPEED = 10,
        _TELEPORT_LAUNCH_THRESHOLD = 150,
        _DASH_ACCEL_THRESHOLD = 800,
        _STALL_LOCK_DURATION = 0.55,
        _THAW_ACCEL_THRESHOLD = 50,
        _ABILITY_DURATIONS = {
            freeze = 1.2,
            stop = 1.0,
            grip = 0.8,
            hold = 0.8,
            slow = 0.6,
            pull = 0.5,
            teleport = 0.3,
            dimension = 0.7,
            warp = 0.3,
            lock = 0.9,
        },
        _GlobalFrozen = false,
        _GlobalStallUntil = 0,
        _StallUntil = {},
        _BallFrozen = {},
        _PayloadBallPos = nil,
        _PayloadBallVel = nil,
        _PayloadDecodedAt = 0,
        _ParryFiredThisFrame = false,
        _lBall = nil,
        _PrevPos = {},
        _SmoothedVel = {},
        _PrevAccel = {},
        _PrevSpeed = {},
        _DirHistory = {},
        _DIR_HISTORY_SIZE = 8,
        _BEZIER_SPEED_THRESHOLD = 60,
        _BEZIER_CURVE_THRESHOLD = 0.08,
        _RaycastHighlight = nil,
        _RayParams = nil,
        _PrevPayloadVel = nil,
        _PayloadDirRing = nil,
        _CleanupAccum = 0,
        _autoPingCompensationEnabled = false,
        _FIXED_PARRY_DISTANCE = 15,
    }

    function AutoParry:_Gravity()
        local g = -self._Services.Workspace.Gravity
        if not self._GravityVec or self._GravityVec.Y ~= g then
            self._GravityVec = Vector3.new(0, g, 0)
        end
        return self._GravityVec
    end

    function AutoParry:_BallPosAt(pos, vel, t)
        return pos + vel * t + self:_Gravity() * (0.5 * t * t)
    end

    function AutoParry:_ClosestApproach(ballPos, vel, rootPos, tMin, tMax)
        local g = self:_Gravity()
        local relPos = ballPos - rootPos

        local function dSq(t)
            local r = relPos + vel * t + g * (0.5 * t * t)
            local v = vel + g * t
            return 2 * r:Dot(v)
        end

        local lo, hi = tMin, tMax
        local dLo = dSq(lo)
        local dHi = dSq(hi)

        local tBest
        if dLo >= 0 then
            tBest = lo
        elseif dHi <= 0 then
            tBest = hi
        else
            for _ = 1, 10 do
                local mid = (lo + hi) * 0.5
                if dSq(mid) < 0 then lo = mid else hi = mid end
            end
            tBest = (lo + hi) * 0.5
        end

        local closest = self:_BallPosAt(ballPos, vel, tBest)
        local closestDist = (closest - rootPos).Magnitude
        return tBest, closestDist
    end

    function AutoParry:_WillHitCylinder(ballPos, vel, rootPos, tMin, tMax)
        local tHit, dist = self:_ClosestApproach(ballPos, vel, rootPos, tMin, tMax)
        if dist > self._HitboxRadius + 1.5 then return false, tHit end
        local hitY = self:_BallPosAt(ballPos, vel, math.max(tHit, tMin)).Y
        if math.abs(hitY - rootPos.Y) > self._HitboxHeight then return false, tHit end
        return true, tHit
    end

    function AutoParry:_UpdatePing(rawPing)
        self._SmoothedPing = self._SmoothedPing * 0.88 + rawPing * 0.12
        self._OneWayLatency = self._SmoothedPing * 0.5
        self._PingHead = (self._PingHead % self._PING_WINDOW_SIZE) + 1
        self._PingWindow[self._PingHead] = rawPing
        if self._PingCount < self._PING_WINDOW_SIZE then self._PingCount = self._PingCount + 1 end

        
        if self._PingHead % 5 == 0 then
            local n = self._PingCount
            local mean = 0
            for i = 1, n do mean = mean + self._PingWindow[i] end
            mean = mean / n
            local variance = 0
            for i = 1, n do
                local d = self._PingWindow[i] - mean
                variance = variance + d * d
            end
            self._PingJitter = math.sqrt(variance / n)
        end
    end

    function AutoParry:_ParryWindow()
        local jitterBuf = math.clamp(self._PingJitter * 2, 0.005, 0.04)
        return self._OneWayLatency + jitterBuf + self._FRAME_BUDGET
    end

    function AutoParry:_DangerRadius(speed)
        return speed * self:_ParryWindow() + self._HitboxRadius + 2
    end

    function AutoParry:_StallAbility(abilityName, now)
        local name = tostring(abilityName):lower()
        local duration = nil
        for key, dur in pairs(self._ABILITY_DURATIONS) do
            if name:find(key) then duration = dur; break end
        end
        self._GlobalFrozen = true
        self._GlobalStallUntil = now + (duration or self._STALL_LOCK_DURATION)
    end

    function AutoParry:_CheckGlobalThaw(accelMag, speed, now)
        if not self._GlobalFrozen then return end
        if accelMag > self._THAW_ACCEL_THRESHOLD and speed > 5 then self._GlobalFrozen = false; return end
        if now >= self._GlobalStallUntil then self._GlobalFrozen = false end
    end

    function AutoParry:_CheckBallThaw(id, accelMag, speed, now)
        if not self._BallFrozen[id] then return end
        if accelMag > self._THAW_ACCEL_THRESHOLD and speed > 5 then self._BallFrozen[id] = false; self._StallUntil[id] = 0; return end
        if now >= (self._StallUntil[id] or 0) then self._BallFrozen[id] = false end
    end

    function AutoParry:_RingNew(size)
        return { buf = table.create(size), size = size, head = 0, count = 0 }
    end

    function AutoParry:_RingPush(r, v)
        r.head = (r.head % r.size) + 1
        r.buf[r.head] = v
        if r.count < r.size then r.count = r.count + 1 end
    end

    function AutoParry:_RingGet(r, i)
        if i > r.count then return nil end
        return r.buf[((r.head - i) % r.size) + 1]
    end

    function AutoParry:_CurveMag(ring, speed)
        if ring.count < 2 then return 0 end
        local total = 0
        local samples = math.min(ring.count - 1, 4)
        for i = 1, samples do
            local d1 = self:_RingGet(ring, i)
            local d2 = self:_RingGet(ring, i + 1)
            if d1 and d2 then
                total = total + (d1 - d2).Magnitude
            end
        end
        local raw = total / samples
        return raw * (1 - math.clamp(speed / 350, 0, 0.5))
    end

    function AutoParry:_QuadBezier(p0, p1, p2, t)
        local mt = 1 - t
        return p0 * (mt * mt) + p1 * (2 * mt * t) + p2 * (t * t)
    end

    function AutoParry:_PredictPos(ballPos, vel, ring, t)
        local speed = vel.Magnitude
        local curveMag = self:_CurveMag(ring, speed)
        local gravPred = self:_BallPosAt(ballPos, vel, t)

        if speed < self._BEZIER_SPEED_THRESHOLD and curveMag > self._BEZIER_CURVE_THRESHOLD and ring.count >= 3 then
            local d0 = self:_RingGet(ring, 1)
            local dmid = self:_RingGet(ring, math.max(1, math.ceil(ring.count / 2)))
            local dold = self:_RingGet(ring, ring.count)

            local curveScale = math.clamp(curveMag * 3, 0, 1)
            local p0 = ballPos
            local p1 = ballPos + dmid * speed * t * 0.4 * curveScale
            local p2 = ballPos + dold * speed * t * 0.7 * curveScale
            local bezierPred = self:_QuadBezier(p0, p1, p2, 0.85)

            local gravWeight = math.clamp(speed / self._BEZIER_SPEED_THRESHOLD, 0.4, 1.0)
            return gravPred * gravWeight + bezierPred * (1 - gravWeight)
        end

        return gravPred
    end

    function AutoParry:_SetHighlight(char, enabled)
        if not char then return end
        self._RaycastHighlight.Adornee = enabled and char or nil
        self._RaycastHighlight.Parent = enabled and self._Services.Workspace or nil
        self._RaycastHighlight.Enabled = enabled
    end

    function AutoParry:_GetMapOffset()
        local map = self._Services.Workspace:FindFirstChild("ActiveMap")
        if map then
            for _, c in map:GetDescendants() do
                if c:IsA("Folder") and c.Name == "BallSpawns" and c:FindFirstChild("Part") then
                    return c.Part.Position
                end
            end
        end
        return Vector3.zero
    end

    function AutoParry:_DecodeBallPayload(payload)
        local buf = self._Bitbuf.fromString(payload)
        buf:ReadUint(10)
        buf:ReadFloat(64)
        local pos = Vector3.new(buf:ReadInt(23)/1000, buf:ReadInt(23)/1000, buf:ReadInt(23)/1000)
        local vel = Vector3.new(buf:ReadInt(24)/1000, buf:ReadInt(24)/1000, buf:ReadInt(24)/1000)
        return pos, vel
    end

    function AutoParry:_ShouldParry(ballPos, vel, rootPos, accelMag)
        local now = os.clock()
        local sinceParry = now - (_G.__LastParryTime or 0)
        local dist = (ballPos - rootPos).Magnitude
        
        local toBall = ballPos - rootPos
        local toBallUnit = toBall.Unit
        
        if sinceParry < self._ParryCooldown then
            local clashBypass = sinceParry < self._CLASH_COOLDOWN_BYPASS and dist < self._CLASH_RADIUS
            if not clashBypass then return false end
        end

        local speed = vel.Magnitude
        if speed <= 0 then return false end
        if speed < 0.5 then return false end

        if dist < self._CLASH_RADIUS then
            local awayDot = vel:Dot(toBallUnit)
            if awayDot < speed * 0.85 then
                return true
            end

            if speed < 30 then return true end
            return false
        end

        accelMag = accelMag or 0
        if accelMag > self._DASH_DETECT_THRESHOLD and dist < self._DASH_DANGER_DIST then
            local awayDot = vel:Dot(toBallUnit)
            if awayDot < speed * 0.6 then
                return true
            end
        end

        local approaching = vel:Dot(-toBall) > 0

        if not approaching and dist > self._CLASH_RADIUS * 1.5 then return false end

        
        local maxDist
        if self._autoPingCompensationEnabled then
            local dRadius = self:_DangerRadius(speed)
            maxDist = dRadius + 5
        else
            maxDist = self._FIXED_PARRY_DISTANCE
        end
        
        if dist > maxDist then return false end

        local window = self:_ParryWindow()
        local tMax = window * 1.8
        local tMin = -self._TBIT_PAST_MARGIN

        local willHit, tHit = self:_WillHitCylinder(ballPos, vel, rootPos, tMin, tMax)
        if not willHit then return false end

        if tHit < -self._TBIT_PAST_MARGIN or tHit > window then return false end

        return true
    end

    function AutoParry:_RunPayloadPath(dt, now)
        if not self._LastPayload then return end
        if now - self._LastPayloadTime > self._MaxPayloadAge then
            self._LastPayload = nil
            self._PayloadBallPos, self._PayloadBallVel = nil, nil
            self._PrevPayloadVel = nil
            return
        end

        if not (_G.__IsTargeted or false) then
            self._PayloadBallPos, self._PayloadBallVel = nil, nil
            self._PrevPayloadVel = nil
            self._PayloadDirRing = self:_RingNew(self._DIR_HISTORY_SIZE)
            return
        end

        if now - (_G.__LastParryTime or 0) < self._ParryCooldown then return end
        if self._ParryFiredThisFrame then return end

        local char = self._LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local ok, decPos, decVel = pcall(function() return self:_DecodeBallPayload(self._LastPayload) end)
        if not ok then return end

        local rawPing = self._LocalPlayer:GetNetworkPing()
        self:_UpdatePing(rawPing)

        local speed = decVel.Magnitude
        local payloadAccelMag = 0

        if self._PrevPayloadVel and dt > 0 then
            local prevSpeed = self._PrevPayloadVel.Magnitude
            payloadAccelMag = (decVel - self._PrevPayloadVel).Magnitude / dt
            if prevSpeed > self._FREEZE_MIN_PREV_SPEED and speed < prevSpeed * self._FREEZE_DROP_RATIO then
                self._GlobalFrozen = true
                self._GlobalStallUntil = now + self._STALL_LOCK_DURATION
            elseif prevSpeed < 10 and speed > self._TELEPORT_LAUNCH_THRESHOLD then
                self._PayloadDirRing = self:_RingNew(self._DIR_HISTORY_SIZE)
                self._GlobalFrozen = false
            elseif payloadAccelMag > self._DASH_ACCEL_THRESHOLD and speed > 20 then
                self._PayloadDirRing = self:_RingNew(self._DIR_HISTORY_SIZE)
            end
            self:_CheckGlobalThaw(payloadAccelMag, speed, now)
        end
        self._PrevPayloadVel = decVel

        if self._GlobalFrozen then return end
        if speed < 1 then return end

        self:_RingPush(self._PayloadDirRing, decVel.Unit)

        local packetAge = now - self._LastPayloadTime
        local baseBallPos = decPos + (self._CachedMapOffset or Vector3.zero)
        local currentPos = self:_BallPosAt(baseBallPos, decVel, packetAge)
        local rootPos = root.Position

        if self:_ShouldParry(currentPos, decVel, rootPos, payloadAccelMag) then
            self._ParryFiredThisFrame = true
            task.defer(_G.RequestParry or function() end)
        end
    end

    function AutoParry:_RunLBallPath(dt, now)
        if not self._lBall then
            return  
        end

        local char = self._LocalPlayer.Character
        if not char then self:_SetHighlight(nil, false); return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then self:_SetHighlight(nil, false); return end

        local ws = self._Services.Workspace
        local balls = self._lBall and self._lBall.ALL_BALLS
        local rp = self._RayParams
        local rootPos = root.Position

        local rawPing = self._LocalPlayer:GetNetworkPing()
        self:_UpdatePing(rawPing)
        
        local isEffectivelyTargeted = (_G.__IsTargeted or false)
        if not isEffectivelyTargeted then
            for id2, ball2 in pairs(balls or {}) do
                if raycastTriggered then break end  
                local body2 = rawget(ball2, "Body")
                if not body2 then continue end
                local pv2 = body2.AssemblyLinearVelocity
                local pv2Mag = pv2.Magnitude
                if pv2Mag < 0.5 then
                    local smoothed = self._SmoothedVel[id2]
                    if not smoothed or smoothed.Magnitude < 8 then continue end
                else
                    if pv2Mag < 8 then continue end
                end
                
                local bp = body2.Position
                local toUs = rootPos - bp
                local d2 = toUs.Magnitude
                
                if d2 < self._CLASH_RADIUS then
                    isEffectivelyTargeted = true; break
                end
                
                if d2 < 28 then
                    local dotThresh = d2 < 20 and 0.35 or 0.5
                    local vel2 = pv2Mag > 0.5 and pv2 or (self._SmoothedVel[id2] or Vector3.zero)
                    if toUs.Unit:Dot(vel2.Unit) > dotThresh then
                        isEffectivelyTargeted = true; break
                    end
                end
            end
            if not isEffectivelyTargeted then
                self:_SetHighlight(char, false); return
            end
        end

        if self._ParryFiredThisFrame then
            self:_SetHighlight(char, false); return
        end

        local raycastTriggered = false
        self._RayParams.FilterDescendantsInstances = {char}  

        for id, ball in pairs(balls or {}) do
            local body = rawget(ball, "Body")
            if not body then continue end

            local ballPos = body.Position
            local physVel = body.AssemblyLinearVelocity
            local hasPV = physVel.Magnitude > 0.5

            local rawVel = Vector3.zero
            if self._PrevPos[id] and dt > 0 then
                rawVel = (ballPos - self._PrevPos[id]) / dt
            end
            self._PrevPos[id] = ballPos

            local velForLogic = hasPV and physVel or rawVel
            self._SmoothedVel[id] = velForLogic

            local speed = velForLogic.Magnitude
            if speed <= 0 then continue end  
            
            local prevVel = self._PrevAccel[id] or velForLogic
            local accelVec = dt > 0 and (velForLogic - prevVel) / dt or Vector3.zero
            self._PrevAccel[id] = velForLogic
            local prevSpeed = self._PrevSpeed[id] or speed
            self._PrevSpeed[id] = speed
            local accelMag = accelVec.Magnitude

            if prevSpeed > self._FREEZE_MIN_PREV_SPEED and speed < prevSpeed * self._FREEZE_DROP_RATIO then
                self._BallFrozen[id] = true
                self._StallUntil[id] = now + self._STALL_LOCK_DURATION
                self._GlobalFrozen = true
                self._GlobalStallUntil = now + self._STALL_LOCK_DURATION
            elseif prevSpeed < 10 and speed > self._TELEPORT_LAUNCH_THRESHOLD then
                self._SmoothedVel[id] = velForLogic
                self._DirHistory[id] = self:_RingNew(self._DIR_HISTORY_SIZE)
                self._BallFrozen[id] = false
            elseif accelMag > self._DASH_ACCEL_THRESHOLD and speed > 20 then
                self._DirHistory[id] = self:_RingNew(self._DIR_HISTORY_SIZE)
            end

            self:_CheckBallThaw(id, accelMag, speed, now)
            self:_CheckGlobalThaw(accelMag, speed, now)

            if self._BallFrozen[id] or self._GlobalFrozen then continue end
            if speed < 1 then continue end

            if not self._DirHistory[id] then self._DirHistory[id] = self:_RingNew(self._DIR_HISTORY_SIZE) end
            self:_RingPush(self._DirHistory[id], velForLogic.Unit)

            local physPos = ballPos
            local blendedPos = physPos
            local payloadAge = now - self._PayloadDecodedAt
            if self._PayloadBallPos and payloadAge < 0.08 and (_G.__IsTargeted or false) then
                local payloadNowPos = self:_BallPosAt(self._PayloadBallPos, self._PayloadBallVel, payloadAge)
                local w = math.clamp(1 - payloadAge / 0.08, 0.5, 0.8)
                blendedPos = payloadNowPos * w + physPos * (1 - w)
            end

            local blendedVel = velForLogic
            if self._PayloadBallVel and payloadAge < 0.08 and (_G.__IsTargeted or false) then
                local w = math.clamp(1 - payloadAge / 0.08, 0.4, 0.75)
                blendedVel = self._PayloadBallVel * w + velForLogic * (1 - w)
            end

            if self:_ShouldParry(blendedPos, blendedVel, rootPos, accelMag) then
                local rayResult
                local rayDir = rootPos - ballPos
                local rayLen = rayDir.Magnitude
                if rayLen > 0.1 then
                    rayResult = ws:Raycast(
                        ballPos, rayDir.Unit * math.min(rayLen + 2, 60), rp
                    )
                end
                if rayResult or (blendedPos - rootPos).Magnitude < 15 then
                    raycastTriggered = true
                    self:_SetHighlight(char, true)
                end
                self._ParryFiredThisFrame = true
                task.defer(_G.RequestParry or function() end)
                break
            end
        end

        if not raycastTriggered then self:_SetHighlight(char, false) end

        self._CleanupAccum = self._CleanupAccum + 1
        if self._CleanupAccum >= 30 then
            self._CleanupAccum = 0
            if self._lBall and self._lBall.ALL_BALLS then
                for id in pairs(self._PrevPos) do
                    if not self._lBall.ALL_BALLS[id] then
                        self._PrevPos[id] = nil
                        self._SmoothedVel[id] = nil
                        self._PrevAccel[id] = nil
                        self._PrevSpeed[id] = nil
                        self._StallUntil[id] = nil
                        self._BallFrozen[id] = nil
                        self._DirHistory[id] = nil
                    end
                end
            end
        end
    end

    function AutoParry:_InitSetup()
        self._Bitbuf = require(self._Services.ReplicatedStorage.Modules.Bitbuf)
        self._LocalPlayer = self._Services.Players.LocalPlayer
        self._PingWindow = table.create(self._PING_WINDOW_SIZE, 0)
        self._PayloadDirRing = self:_RingNew(self._DIR_HISTORY_SIZE)

        
        if not self._lBall then
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "ALL_BALLS") then self._lBall = v; break end
            end
        end

        self._RaycastHighlight = Instance.new("Highlight")
        self._RaycastHighlight.FillColor = Color3.fromRGB(255, 50, 50)
        self._RaycastHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        self._RaycastHighlight.FillTransparency = 0.5
        self._RaycastHighlight.OutlineTransparency = 0
        self._RaycastHighlight.Enabled = false

        self._RayParams = RaycastParams.new()
        self._RayParams.FilterType = Enum.RaycastFilterType.Include

        self._CachedMapOffset = self:_GetMapOffset()
        pcall(function()
            self._Services.Workspace:WaitForChild("ActiveMap").ChildAdded:Connect(function()
                task.wait(0.5)
                self._CachedMapOffset = self:_GetMapOffset()
            end)
        end)

        for _, inst in ipairs(getnilinstances()) do
            if inst.ClassName == "UnreliableRemoteEvent" and inst.Name == "Action" then
                self._ActionRemote = inst; break
            end
        end

        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and rawget(obj, "AllButtons") and rawget(obj, "DeflectButton") then
                _G.__DeflectButton = rawget(obj, "DeflectButton"); break
            end
        end

        pcall(function()
            require(self._Services.ReplicatedStorage.Actions).SET_ROUND_BALL_TARGET:Connect(function(p)
                if typeof(p) == "Instance" and p.Parent then
                    _G.__IsTargeted = self._Services.Players:GetPlayerFromCharacter(p.Parent) == self._LocalPlayer
                else
                    _G.__IsTargeted = false
                end
            end)
        end)

        pcall(function()
            local __Actions = require(self._Services.ReplicatedStorage.Actions)
            if __Actions.SET_BALL_ABILITY then
                __Actions.SET_BALL_ABILITY:Connect(function(abilityName)
                    self:_StallAbility(abilityName, os.clock())
                end)
            end
        end)

        pcall(function()
            if self._ActionRemote then
                self._ActionRemote.OnClientEvent:Connect(function(t, payload)
                    if t == "Update" and type(payload) == "string" then
                        local now = os.clock()
                        self._LastPayload = payload
                        self._LastPayloadTime = now
                        local ok, pos, vel = pcall(function() return self:_DecodeBallPayload(payload) end)
                        if ok then
                            local ageCompensated = pos + (self._CachedMapOffset or Vector3.zero)
                            self._PayloadBallPos = ageCompensated
                            self._PayloadBallVel = vel
                            self._PayloadDecodedAt = now
                        end
                    end
                end)
            end
        end)

        _G.__LastParryTime = _G.__LastParryTime or 0
        _G.__IsTargeted = _G.__IsTargeted or false

        _G.RequestParry = _G.RequestParry or function()
            local now = os.clock()
            if now - (_G.__LastParryTime or 0) < self._ParryCooldown then return end
            local btn = _G.__DeflectButton
            if btn then pcall(function() btn:OnClick() end) end
            _G.__LastParryTime = now
            
            
            if autoSpamEnabled then
                table.insert(parryTimestamps, now)
                startAutoSpam()
            end
        end
    end

    function AutoParry:Start()
        if self.isActive then return end
        self:_InitSetup()
        self.isActive = true

        self.connection = self._Services.RunService.Heartbeat:Connect(function(dt)
            if not self.isActive then return end
            local now = os.clock()
            self._ParryFiredThisFrame = false
            self:_RunPayloadPath(dt, now)
            self:_RunLBallPath(dt, now)
        end)
    end

    function AutoParry:Stop()
        if not self.isActive then return end
        self.isActive = false
        
        
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        
        
        for k in pairs(self._PrevPos) do self._PrevPos[k] = nil end
        for k in pairs(self._SmoothedVel) do self._SmoothedVel[k] = nil end
        for k in pairs(self._PrevAccel) do self._PrevAccel[k] = nil end
        for k in pairs(self._PrevSpeed) do self._PrevSpeed[k] = nil end
        for k in pairs(self._DirHistory) do self._DirHistory[k] = nil end
        for k in pairs(self._StallUntil) do self._StallUntil[k] = nil end
        for k in pairs(self._BallFrozen) do self._BallFrozen[k] = nil end
        
        
        if self._RaycastHighlight then
            if self._RaycastHighlight.Parent then
                self._RaycastHighlight:Destroy()
            end
            self._RaycastHighlight = nil
        end
        
        
        self._GlobalFrozen = false
        self._GlobalStallUntil = 0
        self._LastPayload = nil
        self._PayloadBallPos = nil
        self._PayloadBallVel = nil
        self._ParryFiredThisFrame = false
        self._PrevPayloadVel = nil
        self._lBall = nil
    end

    
    local autoSpamEnabled = false
    local spamConnection = nil
    
    
    
    local parryTimestamps = {}
    local PARRY_WINDOW = 5                      
    local PARRY_REQUIRED = 2                    
    
    
    local SPAM_ENABLED = true
    local SPAM_DISTANCE = 20                   
    local SPAM_RATE = 50                       
    local SPAM_CHECK_INTERVAL = 0.016          

    local lastSpamTime = 0
    local isSpamming = false
    local spamConditionMet = false

    
    local function checkParryCondition()
        local now = os.clock()
        
        
        for i = #parryTimestamps, 1, -1 do
            if now - parryTimestamps[i] > PARRY_WINDOW then
                table.remove(parryTimestamps, i)
            end
        end
        
        
        return #parryTimestamps >= PARRY_REQUIRED
    end

    
    local function getHighlightedTarget()
        local lp = Players.LocalPlayer
        if not lp or not lp.Character then return nil, math.huge end
        
        local myRoot = lp.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil, math.huge end
        
        local closestPlayer = nil
        local closestDist = math.huge
        
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local highlight = p.Character:FindFirstChild("Highlight")
                if highlight and highlight:IsA("Highlight") and highlight.Enabled then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - myRoot.Position).Magnitude
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

    
    local function spamAttack(attacksPerFrame)
        local btn = _G.__DeflectButton
        if not btn then return false end
        
        local success = false
        pcall(function()
            for _ = 1, attacksPerFrame do
                btn:OnClick()
                success = true
            end
        end)
        return success
    end

    
    local function startAutoSpam()
        if spamConnection then return end
        
        isSpamming = true
        spamConnection = RunService.Heartbeat:Connect(function()
            if not autoSpamEnabled or not SPAM_ENABLED then
                isSpamming = false
                spamConditionMet = false
                return
            end
            
            
            if not checkParryCondition() then
                isSpamming = false
                spamConditionMet = false
                return
            end
            
            spamConditionMet = true
            
            
            local target, distance = getHighlightedTarget()
            
            
            if not target or distance > 20 then
                isSpamming = false
                spamConditionMet = false
                return
            end
            
            
            local now = os.clock()
            if now - lastSpamTime >= 1/50 then
                spamAttack(1)
                lastSpamTime = now
            end
        end)
    end

    
    local function stopAutoSpam()
        if spamConnection then
            spamConnection:Disconnect()
            spamConnection = nil
        end
        isSpamming = false
        lastSpamTime = 0
    end

    local autoParryEnabled = false
    

    local AutoParryToggle = Tabs.main:AddToggle("autoparry", {
        Title = "Auto Parry",
        Description = "Automatically parries incoming attacks",
        Default = false,
        Callback = function(value)
            autoParryEnabled = value
            if value then
                AutoParry:Start()
            else
                AutoParry:Stop()
                stopAutoSpam()
            end
        end
    })

    Tabs.main:AddToggle("AutoPingCompensation", {
        Title = "Auto ping compensation",
        Description = "Adjusts parry distance based on ping for better accuracy",
        Default = false,
        Callback = function(Value)
            AutoParry._autoPingCompensationEnabled = Value
        end
    })


    
    Tabs.main:AddToggle("AutoSpam", {
        Title = "Auto Spam",
        Description = "In development..",
        Default = false,
        Callback = function(Value)
            autoSpamEnabled = Value
            if Value then
                startAutoSpam()
            else
                stopAutoSpam()
            end
        end
    })



local player = Players.LocalPlayer
local deflectButton = nil
local lastTransparency = nil
local timerRunning = false
local startTime = 0
local printed90 = false


local function getDeflectButton()
    if not deflectButton then
        pcall(function()
            deflectButton = player:WaitForChild("PlayerGui"):WaitForChild("HUD"):WaitForChild("HolderBottom"):WaitForChild("ToolbarButtons"):WaitForChild("DeflectButton")
            if deflectButton then
                lastTransparency = deflectButton.BackgroundTransparency
            end
        end)
    end
    return deflectButton
end

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
    local char = player.Character
    if not char then return false end
    local highlight = char:FindFirstChild("Highlight")
    if highlight and highlight:IsA("Highlight") then
        return math.abs(highlight.FillTransparency - 0.34) <= 0.001
    end
    return false
end

task.spawn(function()
    while true do
        if autoAbilityEnabled then
            local btn = getDeflectButton()
            if btn then
                
                local ballDist = math.huge
                local ball = Workspace:FindFirstChild("Ball")
                if ball and ball:IsA("BasePart") and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        ballDist = (ball.Position - hrp.Position).Magnitude
                    end
                end
                if isOnCooldown(btn) and ballDist < 20 then
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

                local currentTransparency = btn.BackgroundTransparency
                local now = tick()
                if lastTransparency and currentTransparency ~= lastTransparency then
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
        end
        task.wait(0.05)
    end
end)
    Tabs.main:AddToggle("autoability", {
    Title = "Auto ability",
    Description = "automatically activates the ability at the right moment",
    Default = false,
    Callback = function(value)
        autoAbilityEnabled = value
    end
    })
        
    local autoReadyConnection = nil
    local originalReadyZoneState = nil

    Tabs.main:AddToggle("autoready", {
        Title = "Auto Ready",
        Description = "Automatically readies you at the start of rounds",
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



local humanoidRootPart = nil

local function getHumanoidRootPart()
    if not humanoidRootPart then
        pcall(function()
            local char = Players.LocalPlayer.Character
            if char then
                humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
            end
        end)
    end
    return humanoidRootPart
end


Players.LocalPlayer.CharacterAdded:Connect(function()
    humanoidRootPart = nil
end)

    Tabs.main:AddSlider("fov", {
        Title = "FOV Value",
        Description = "Adjust your field of view (70-120)",
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
        Description = "",
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
		if farmAlignPosition and farmAlignPosition.Parent then farmAlignPosition:Destroy() end
		if farmRootAttachment and farmRootAttachment.Parent then farmRootAttachment:Destroy() end
		farmAlignPosition, farmRootAttachment = nil, nil
		local _, hrp = getCharacterComponents()
		if hrp then hrp.Anchored = false end
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
				collider:Destroy()
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
	end

	local function deactivateFarm(returnToLastPosition)
		local lastCFrame = lastKnownFarmCFrame
		destroyFarmMover()
		currentFarmingBossName = nil
		if returnToLastPosition and lastCFrame then
			local _, hrp = getCharacterComponents()
			if hrp then
				hrp.Anchored = false; hrp.CFrame = lastCFrame; task.wait(0.1); hrp.Anchored = false
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
	
	Tabs.farm:AddSection("")
	Tabs.farm:AddParagraph({Title = "BossFarm", Content = "Soon..."})
	
	

	

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


local flyConnection = nil
local flyEnabled = false
local flySpeed = 50
local speedHackEnabled = false
local speedHackValue = 50
local speedHackConnection = nil
local originalSpeedValue = nil
local jumpPowerEnabled = false
local jumpPowerValue = 50
local jumpPowerConnection = nil
local originalJumpPowerValue = nil
local allConnections = {}
local allToggles = {}

local function enableFly()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    if flyConnection then flyConnection:Disconnect() end
    
    local wasBodyVelocity = false
    flyConnection = RunService.RenderStepped:Connect(function()
        
        local currentChar = player.Character
        local currentRootPart = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not flyEnabled or not currentRootPart then return end

        local camCF = workspace.CurrentCamera.CFrame
        local moveVec = Vector3.new()

        if IS_MOBILE then
            moveVec = moveVec + camCF.LookVector
        else
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
        end

        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit * flySpeed
            currentRootPart.Velocity = moveVec
            wasBodyVelocity = true
        else
            if wasBodyVelocity then
                currentRootPart.Velocity = Vector3.zero
            end
        end
    end)
end

local function disableFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Velocity = Vector3.zero
        end
    end
end

local function getMovementHandler()
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    local Classes = ReplicatedFirst:FindFirstChild("Classes")
    if not Classes then return nil end
    local PlayerControl = Classes:FindFirstChild("PlayerControl")
    if not PlayerControl then return nil end
    local success, result = pcall(require, PlayerControl)
    if success then return result end
    return nil
end

local function applySpeedHack()
    if not speedHackEnabled then return end
    
    if originalSpeedValue == nil then
        local control = getMovementHandler()
        if control and control.Movement then
            originalSpeedValue = control.Movement.RunSpeed or 16
        end
    end
    
    if speedHackConnection then speedHackConnection:Disconnect() end
    speedHackConnection = RunService.Heartbeat:Connect(function()
        if speedHackEnabled then
            local control = getMovementHandler()
            if control and control.Movement then
                control.Movement.RunSpeed = speedHackValue
                control.Movement.OverrideWalkSpeed = speedHackValue
            end
        end
    end)
    table.insert(allConnections, speedHackConnection)
end

local function disableSpeedHack()
    if speedHackConnection then
        speedHackConnection:Disconnect()
        speedHackConnection = nil
    end
    
    if originalSpeedValue ~= nil then
        local control = getMovementHandler()
        if control and control.Movement then
            control.Movement.RunSpeed = originalSpeedValue
            control.Movement.OverrideWalkSpeed = originalSpeedValue
        end
        originalSpeedValue = nil
    end
end

local function applyJumpPower()
    if not jumpPowerEnabled then return end
    
    if originalJumpPowerValue == nil then
        local control = getMovementHandler()
        if control and control.Movement then
            originalJumpPowerValue = control.Movement.DoubleJumpPower or 50
        end
    end
    
    if jumpPowerConnection then jumpPowerConnection:Disconnect() end
    jumpPowerConnection = RunService.Heartbeat:Connect(function()
        if jumpPowerEnabled then
            local control = getMovementHandler()
            if control and control.Movement then
                control.Movement.DoubleJumpPower = jumpPowerValue
                if control.Movement.Humanoid then
                    control.Movement.Humanoid.JumpPower = jumpPowerValue
                end
            end
        end
    end)
    table.insert(allConnections, jumpPowerConnection)
end

local function disableJumpPower()
    if jumpPowerConnection then
        jumpPowerConnection:Disconnect()
        jumpPowerConnection = nil
    end
    
    if originalJumpPowerValue ~= nil then
        local control = getMovementHandler()
        if control and control.Movement then
            control.Movement.DoubleJumpPower = originalJumpPowerValue
        end
        originalJumpPowerValue = nil
    end
end



local function disableAllToggles()
    flyEnabled = false
    speedHackEnabled = false
    jumpPowerEnabled = false
    
    disableFly()
    disableSpeedHack()
    disableJumpPower()
    
    for _, toggle in ipairs(allToggles) do
        if toggle and toggle.Set then
            toggle:Set(false)
        end
    end
end

local function cleanupAllConnections()
    for _, connection in ipairs(allConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    allConnections = {}
end

local flyToggle = Tabs.movement:AddToggle("flyToggle", {
    Title = "Fly",
    Description = "Enable flight mode to freely move in any direction",
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
table.insert(allToggles, flyToggle)

local flySpeedSlider = Tabs.movement:AddSlider("flySpeed", {
    Title = "Fly speed",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        flySpeed = value
    end
})

local speedHackToggle = Tabs.movement:AddToggle("speedHackToggle", {
    Title = "Speed Hack",
    Description = "Increase your movement speed",
    Default = false,
    Callback = function(value)
        speedHackEnabled = value
        if value then
            applySpeedHack()
        else
            disableSpeedHack()
        end
    end
})
table.insert(allToggles, speedHackToggle)

local speedValueSlider = Tabs.movement:AddSlider("speedValue", {
    Title = "Speed Value",
    Default = 50,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        speedHackValue = value
    end
})

local jumpPowerToggle = Tabs.movement:AddToggle("jumpPowerToggle", {
    Title = "Jump Power",
    Description = "Increase your jump power",
    Default = false,
    Callback = function(value)
        jumpPowerEnabled = value
        if value then
            applyJumpPower()
        else
            disableJumpPower()
        end
    end
})
table.insert(allToggles, jumpPowerToggle)

local jumpPowerValueSlider = Tabs.movement:AddSlider("jumpPowerValue", {
    Title = "Jump Power Value",
    Default = 50,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        jumpPowerValue = value
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
        Description = "Enables infinite double jump for unrestricted aerial mobility",
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
        Description = "Removes dash cooldown for unlimited dash ability usage",
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
        Title = "Infinite Parry",
        Description = "Removes parry cooldown for constant defense capability",
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
        Description = "Automatically applies curve to your ball throws for unpredictable trajectories",
        Default = false,
        Callback = function(Value)
            autoCurveEnabled = Value
        end
    })

local function Shutdown()
    disableAllToggles()
    cleanupAllConnections()
    for _, conn in ipairs(rageConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
end

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

if Fluent then
    local originalDestroy = Fluent.Destroy
    Fluent.Destroy = function(...)
        Shutdown()
        if originalDestroy then
            return originalDestroy(...)
        end
    end
end
    
