--[[
    INFINITY HUB | The Endless Night with Fredbear
    UI: Obsidian
    Authors: INFINITY, CLAUDE

    Функции:
      - INFINITE STAMINA
      - TELEPORT TO SPRING BONNIE SUIT
      - ESP: BOX + NAME TEXT над головой (FREDBEAR и т.д.)
      - RAINBOW BOX + RAINBOW TEXT (синхронизированы — один общий цвет)
]]

-- ========== LOAD LIBRARY ==========
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local connections = {}
local unloaded = false

-- ========== WINDOW ==========
local Window = Library:CreateWindow({
    Title = "INFINITY HUB",
    Footer = "THE ENDLESS NIGHT WITH FREDBEAR | INFINITY & CLAUDE",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab("MAIN", "user"),
    Visuals = Window:AddTab("VISUALS", "eye"),
    Settings = Window:AddTab("SETTINGS", "settings"),
}

-- ========== HELPERS ==========
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function rainbowColor()
    return Color3.fromHSV((tick() * 0.4) % 1, 1, 1)
end

local function containsAny(str, list)
    str = str:lower()
    for _, key in ipairs(list) do
        if key ~= "" and str:find(key, 1, true) then
            return true
        end
    end
    return false
end

------------------------------------------------------------
-- MAIN TAB: INFINITE STAMINA
------------------------------------------------------------
local StaminaGroup = Tabs.Main:AddLeftGroupbox("STAMINA")

local staminaWords = { "stamina", "sprint", "energy" }
local maxSeen = setmetatable({}, { __mode = "k" })

local function isStaminaName(name)
    local n = name:lower()
    if n:find("max", 1, true) then return false end
    return containsAny(n, staminaWords)
end

local function refillValue(v)
    local cur = v.Value
    local m = maxSeen[v] or cur
    if cur > m then m = cur end
    maxSeen[v] = m
    if m < 100 then m = 100 end
    if v.Value < m then v.Value = m end
end

local function refillContainer(container)
    if not container then return end
    for _, v in ipairs(container:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and isStaminaName(v.Name) then
            pcall(refillValue, v)
        end
    end
    -- атрибуты
    pcall(function()
        for name, val in pairs(container:GetAttributes()) do
            if type(val) == "number" and isStaminaName(name) then
                local key = container
                maxSeen[key] = maxSeen[key] or {}
                local m = math.max(maxSeen[key][name] or val, val, 100)
                maxSeen[key][name] = m
                if val < m then container:SetAttribute(name, m) end
            end
        end
    end)
end

local gcCache = setmetatable({}, { __mode = "k" })
local function gcScan()
    if not getgc then return end
    local ok, list = pcall(getgc, true)
    if not ok then return end
    for _, t in ipairs(list) do
        if type(t) == "table" then
            for _, key in ipairs({ "Stamina", "stamina", "CurrentStamina", "currentStamina" }) do
                local val = rawget(t, key)
                if type(val) == "number" then
                    local m = math.max(gcCache[t] or val, val, 100)
                    gcCache[t] = m
                    if val < m then pcall(rawset, t, key, m) end
                end
            end
        end
    end
end

StaminaGroup:AddToggle("InfStamina", {
    Text = "INFINITE STAMINA",
    Default = false,
    Tooltip = "Постоянно держит выносливость на максимуме",
})

StaminaGroup:AddToggle("InfStaminaDeep", {
    Text = "DEEP SCAN (GC)",
    Default = false,
    Tooltip = "Включи, если обычный режим не помог (ищет стамину в скриптах игры)",
})

task.spawn(function()
    local gcTimer = 0
    while not unloaded do
        if Toggles.InfStamina and Toggles.InfStamina.Value then
            refillContainer(LocalPlayer.Character)
            refillContainer(LocalPlayer)
            refillContainer(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
            gcTimer += 0.1
            if Toggles.InfStaminaDeep and Toggles.InfStaminaDeep.Value and gcTimer >= 2 then
                gcTimer = 0
                gcScan()
            end
        end
        task.wait(0.1)
    end
end)

------------------------------------------------------------
-- MAIN TAB: TELEPORT TO SPRING BONNIE SUIT
------------------------------------------------------------
local TeleportGroup = Tabs.Main:AddRightGroupbox("TELEPORT")

local suitKeywords = { "springbonnie", "spring bonnie", "spring_bonnie", "springbonny", "spring bonny" }
local suitCandidates = {}

local function getInstancePosition(inst)
    if inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok then return cf.Position end
    elseif inst:IsA("BasePart") then
        return inst.Position
    end
end

local function scanSuits()
    table.clear(suitCandidates)
    local names = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if (inst:IsA("Model") or inst:IsA("BasePart")) and containsAny(inst.Name, suitKeywords) then
            local pos = getInstancePosition(inst)
            if pos then
                table.insert(suitCandidates, { inst = inst, pos = pos })
                table.insert(names, string.format("%d. %s", #suitCandidates, inst:GetFullName():sub(1, 60)))
            end
        end
    end
    if #names == 0 then names = { "NOT FOUND" } end
    return names
end

TeleportGroup:AddDropdown("SuitList", {
    Text = "SPRING BONNIE SUIT",
    Values = { "PRESS REFRESH" },
    Default = 1,
    Multi = false,
})

TeleportGroup:AddButton({
    Text = "REFRESH LIST",
    Func = function()
        local names = scanSuits()
        Options.SuitList:SetValues(names)
        Options.SuitList:SetValue(names[1])
        Library:Notify("FOUND: " .. #suitCandidates, 3)
    end,
})

local function getSelectedSuit()
    if #suitCandidates == 0 then scanSuits() end
    local sel = Options.SuitList and Options.SuitList.Value or ""
    local idx = tonumber(tostring(sel):match("^(%d+)%."))
    return suitCandidates[idx or 1]
end

TeleportGroup:AddButton({
    Text = "TELEPORT TO SUIT",
    Func = function()
        local root = getRoot()
        if not root then return Library:Notify("NO CHARACTER", 3) end
        local target = getSelectedSuit()
        if not target or not target.inst.Parent then
            return Library:Notify("SPRING BONNIE SUIT NOT FOUND", 3)
        end
        local pos = getInstancePosition(target.inst) or target.pos
        root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
        Library:Notify("TELEPORTED", 2)
    end,
})

TeleportGroup:AddButton({
    Text = "INTERACT (PROMPT)",
    Tooltip = "Нажимает ProximityPrompt у костюма, если он есть",
    Func = function()
        local target = getSelectedSuit()
        if not target then return Library:Notify("NOT FOUND", 3) end
        local fired = false
        for _, d in ipairs(target.inst:GetDescendants()) do
            if d:IsA("ProximityPrompt") and fireproximityprompt then
                fireproximityprompt(d)
                fired = true
            end
        end
        Library:Notify(fired and "PROMPT FIRED" or "NO PROMPT", 3)
    end,
})

------------------------------------------------------------
-- VISUALS TAB: ESP
------------------------------------------------------------
local EspGroup = Tabs.Visuals:AddLeftGroupbox("ANIMATRONIC ESP")
local ColorGroup = Tabs.Visuals:AddRightGroupbox("COLORS")

local animatronicKeywords = {
    "fredbear", "springbonnie", "spring bonnie", "spring_bonnie",
    "golden freddy", "goldenfreddy", "freddy", "bonnie", "chica", "foxy",
    "animatronic", "nightmare", "rainbow", "puppet", "mangle",
}

EspGroup:AddToggle("EspEnabled", { Text = "ESP ENABLED", Default = false })
EspGroup:AddToggle("EspBox", { Text = "BOX", Default = true })
EspGroup:AddToggle("EspText", { Text = "NAME TEXT (OVER HEAD)", Default = true })
EspGroup:AddToggle("EspRainbow", {
    Text = "RAINBOW (BOX + TEXT SYNC)",
    Default = false,
    Tooltip = "Бокс и текст используют один и тот же радужный цвет одновременно",
})
EspGroup:AddSlider("EspTextSize", {
    Text = "TEXT SIZE", Default = 16, Min = 10, Max = 30, Rounding = 0,
})
EspGroup:AddSlider("EspDistance", {
    Text = "MAX DISTANCE", Default = 1500, Min = 100, Max = 5000, Rounding = 0,
})
EspGroup:AddToggle("EspShowDistance", { Text = "SHOW DISTANCE", Default = false })
EspGroup:AddInput("EspExtra", {
    Text = "EXTRA KEYWORD",
    Default = "",
    Placeholder = "например: withered",
    Finished = true,
    Callback = function(value)
        value = (value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if value ~= "" then
            table.insert(animatronicKeywords, value)
            Library:Notify("ADDED: " .. value:upper(), 3)
        end
    end,
})

ColorGroup:AddLabel("BOX COLOR"):AddColorPicker("EspBoxColor", { Default = Color3.fromRGB(255, 0, 0) })
ColorGroup:AddLabel("TEXT COLOR"):AddColorPicker("EspTextColor", { Default = Color3.fromRGB(255, 255, 255) })

-- tracking
local tracked = {} -- [model] = { box = Drawing, text = Drawing }

local function isPlayerCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return true end
    end
    return false
end

local function newDrawings()
    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false
    local txt = Drawing.new("Text")
    txt.Center = true
    txt.Outline = true
    txt.Visible = false
    txt.Size = 16
    return { box = box, text = txt }
end

local function removeEsp(model)
    local d = tracked[model]
    if d then
        pcall(function() d.box:Remove() end)
        pcall(function() d.text:Remove() end)
        tracked[model] = nil
    end
end

local function scanAnimatronics()
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("Model") and not tracked[inst] and not isPlayerCharacter(inst)
            and containsAny(inst.Name, animatronicKeywords)
            and inst:FindFirstChildWhichIsA("BasePart", true) then
            -- не берём вложенные модели внутри уже найденного аниматроника
            local parentTracked = false
            for m in pairs(tracked) do
                if inst:IsDescendantOf(m) then parentTracked = true break end
            end
            if not parentTracked then
                tracked[inst] = newDrawings()
            end
        end
    end
end

task.spawn(function()
    while not unloaded do
        if Toggles.EspEnabled and Toggles.EspEnabled.Value then
            pcall(scanAnimatronics)
        end
        task.wait(2)
    end
end)

local corners = {}
for x = -1, 1, 2 do
    for y = -1, 1, 2 do
        for z = -1, 1, 2 do
            table.insert(corners, Vector3.new(x, y, z))
        end
    end
end

local function hideAll()
    for _, d in pairs(tracked) do
        d.box.Visible = false
        d.text.Visible = false
    end
end

connections.render = RunService.RenderStepped:Connect(function()
    if unloaded then return end
    Camera = Workspace.CurrentCamera
    if not (Toggles.EspEnabled and Toggles.EspEnabled.Value) then
        hideAll()
        return
    end

    -- ЕДИНЫЙ цвет: бокс и текст берут его из одной переменной -> всегда синхронны
    local rainbow = Toggles.EspRainbow.Value
    local sharedRainbow = rainbowColor()
    local boxColor = rainbow and sharedRainbow or Options.EspBoxColor.Value
    local textColor = rainbow and sharedRainbow or Options.EspTextColor.Value

    local root = getRoot()
    for model, d in pairs(tracked) do
        if not model.Parent then
            removeEsp(model)
        else
            local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
            if not ok then
                d.box.Visible = false
                d.text.Visible = false
            else
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                local visible = true
                for _, c in ipairs(corners) do
                    local world = cf:PointToWorldSpace(c * size / 2)
                    local screen, onScreen = Camera:WorldToViewportPoint(world)
                    if screen.Z <= 0 then visible = false break end
                    minX = math.min(minX, screen.X)
                    minY = math.min(minY, screen.Y)
                    maxX = math.max(maxX, screen.X)
                    maxY = math.max(maxY, screen.Y)
                end

                local dist = root and (root.Position - cf.Position).Magnitude or 0
                if dist > Options.EspDistance.Value then visible = false end

                if visible then
                    if Toggles.EspBox.Value then
                        d.box.Position = Vector2.new(minX, minY)
                        d.box.Size = Vector2.new(maxX - minX, maxY - minY)
                        d.box.Color = boxColor
                        d.box.Visible = true
                    else
                        d.box.Visible = false
                    end

                    if Toggles.EspText.Value then
                        local label = model.Name:upper()
                        if Toggles.EspShowDistance.Value then
                            label = string.format("%s [%dM]", label, math.floor(dist))
                        end
                        d.text.Text = label
                        d.text.Size = Options.EspTextSize.Value
                        d.text.Color = textColor
                        d.text.Position = Vector2.new((minX + maxX) / 2, minY - Options.EspTextSize.Value - 3)
                        d.text.Visible = true
                    else
                        d.text.Visible = false
                    end
                else
                    d.box.Visible = false
                    d.text.Visible = false
                end
            end
        end
    end
end)

Toggles.EspEnabled:OnChanged(function()
    if Toggles.EspEnabled.Value then
        pcall(scanAnimatronics)
    else
        hideAll()
    end
end)

------------------------------------------------------------
-- SETTINGS TAB
------------------------------------------------------------
local MenuGroup = Tabs.Settings:AddLeftGroupbox("MENU")
local CreditsGroup = Tabs.Settings:AddRightGroupbox("CREDITS")

MenuGroup:AddLabel("MENU BIND"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "MENU KEYBIND",
})
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddButton({
    Text = "UNLOAD",
    Func = function()
        unloaded = true
        for m in pairs(tracked) do removeEsp(m) end
        for _, c in pairs(connections) do pcall(function() c:Disconnect() end) end
        Library:Unload()
    end,
})

CreditsGroup:AddLabel("AUTHORS: INFINITY, CLAUDE")
CreditsGroup:AddLabel("GAME: THE ENDLESS NIGHT WITH FREDBEAR")

Library:Notify("INFINITY HUB LOADED", 4)
