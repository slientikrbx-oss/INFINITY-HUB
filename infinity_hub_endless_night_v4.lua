--[[
    INFINITY HUB | The Endless Night with Fredbear
    UI: Obsidian | Mobile version (Delta X Android)
    Authors: INFINITY, CLAUDE

    - INFINITE STAMINA
    - TELEPORT TO SPRING BONNIE SUIT
    - ESP: BOX + NAME TEXT over head (FREDBEAR etc.)
    - RAINBOW BOX + RAINBOW TEXT (synced, one shared color)
    - On-screen "INF" button to open/close the menu (no keyboard needed)
]]

-- ========== LOAD LIBRARY ==========
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local connections = {}
local unloaded = false

local function getGuiParent()
    local ok, parent = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    if ok and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local guiParent = getGuiParent()

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
-- MOBILE MENU BUTTON
------------------------------------------------------------
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "InfinityHubButton"
menuGui.ResetOnSpawn = false
menuGui.IgnoreGuiInset = true
menuGui.Parent = guiParent

local menuBtn = Instance.new("TextButton")
menuBtn.Size = UDim2.fromOffset(52, 52)
menuBtn.Position = UDim2.new(0, 12, 0.5, -26)
menuBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuBtn.BackgroundTransparency = 0.15
menuBtn.Text = "INF"
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 16
menuBtn.AutoButtonColor = true
menuBtn.Parent = menuGui
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(1, 0)
local btnStroke = Instance.new("UIStroke", menuBtn)
btnStroke.Thickness = 2
btnStroke.Color = Color3.fromRGB(255, 255, 255)

-- перетаскивание кнопки + нажатие
do
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    menuBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, moved = true, false
            dragStart, startPos = input.Position, menuBtn.Position
        end
    end)
    menuBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - dragStart
            if d.Magnitude > 8 then moved = true end
            if moved then
                menuBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    menuBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if not moved then
                pcall(function() Library:Toggle() end)
            end
        end
    end)
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
    pcall(function()
        for name, val in pairs(container:GetAttributes()) do
            if type(val) == "number" and isStaminaName(name) then
                maxSeen[container] = maxSeen[container] or {}
                local m = math.max(maxSeen[container][name] or val, val, 100)
                maxSeen[container][name] = m
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
                local okGet, val = pcall(rawget, t, key)
                if okGet and type(val) == "number" then
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
    Tooltip = "Keeps stamina at max",
})

StaminaGroup:AddToggle("InfStaminaDeep", {
    Text = "DEEP SCAN (GC)",
    Default = false,
    Tooltip = "Enable if normal mode does not help",
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
-- VISUALS TAB: ESP (SelectionBox + BillboardGui, no Drawing API)
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
    Tooltip = "Box and text use the same rainbow color at the same time",
})
EspGroup:AddSlider("EspTextSize", {
    Text = "TEXT SIZE", Default = 18, Min = 10, Max = 40, Rounding = 0,
})
EspGroup:AddSlider("EspDistance", {
    Text = "MAX DISTANCE", Default = 1500, Min = 100, Max = 5000, Rounding = 0,
})
EspGroup:AddToggle("EspShowDistance", { Text = "SHOW DISTANCE", Default = false })
EspGroup:AddInput("EspExtra", {
    Text = "EXTRA KEYWORD",
    Default = "",
    Placeholder = "e.g. withered",
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

local tracked = {} -- [model] = { box, gui, label }

local function isPlayerCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return true end
    end
    return false
end

local function removeEsp(model)
    local d = tracked[model]
    if d then
        pcall(function() d.box:Destroy() end)
        pcall(function() d.gui:Destroy() end)
        tracked[model] = nil
    end
end

local function createEsp(model)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local box = Instance.new("SelectionBox")
    box.Name = "InfinityEspBox"
    box.Adornee = model
    box.LineThickness = 0.05
    box.SurfaceTransparency = 1
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Visible = false
    box.Parent = guiParent

    local gui = Instance.new("BillboardGui")
    gui.Name = "InfinityEspText"
    gui.Adornee = part
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(260, 40)
    gui.Enabled = false
    gui.Parent = guiParent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Text = model.Name:upper()
    label.Parent = gui

    tracked[model] = { box = box, gui = gui, label = label, part = part }
end

local function scanAnimatronics()
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("Model") and not tracked[inst] and not isPlayerCharacter(inst)
            and containsAny(inst.Name, animatronicKeywords)
            and inst:FindFirstChildWhichIsA("BasePart", true) then
            local nested = false
            for m in pairs(tracked) do
                if inst:IsDescendantOf(m) then nested = true break end
            end
            if not nested then
                createEsp(inst)
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

local function hideAll()
    for _, d in pairs(tracked) do
        d.box.Visible = false
        d.gui.Enabled = false
    end
end

connections.render = RunService.RenderStepped:Connect(function()
    if unloaded then return end
    if not (Toggles.EspEnabled and Toggles.EspEnabled.Value) then
        hideAll()
        return
    end

    -- ОДИН общий цвет -> бокс и текст всегда синхронны
    local rainbow = Toggles.EspRainbow.Value
    local shared = rainbowColor()
    local boxColor = rainbow and shared or Options.EspBoxColor.Value
    local textColor = rainbow and shared or Options.EspTextColor.Value

    local root = getRoot()
    for model, d in pairs(tracked) do
        if not model.Parent then
            removeEsp(model)
        else
            local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
            if not ok then
                d.box.Visible = false
                d.gui.Enabled = false
            else
                if not d.part or not d.part.Parent then
                    d.part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                    d.gui.Adornee = d.part
                end
                local dist = root and (root.Position - cf.Position).Magnitude or 0
                local inRange = dist <= Options.EspDistance.Value

                d.box.Color3 = boxColor
                d.box.Visible = inRange and Toggles.EspBox.Value

                if inRange and Toggles.EspText.Value and d.part then
                    local textPos = cf.Position + Vector3.new(0, size.Y / 2 + 1.5, 0)
                    d.gui.StudsOffsetWorldSpace = textPos - d.part.Position
                    local label = model.Name:upper()
                    if Toggles.EspShowDistance.Value then
                        label = string.format("%s [%dM]", label, math.floor(dist))
                    end
                    d.label.Text = label
                    d.label.TextSize = Options.EspTextSize.Value
                    d.label.TextColor3 = textColor
                    d.gui.Enabled = true
                else
                    d.gui.Enabled = false
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
        pcall(function() menuGui:Destroy() end)
        Library:Unload()
    end,
})

CreditsGroup:AddLabel("AUTHORS: INFINITY, CLAUDE")
CreditsGroup:AddLabel("GAME: THE ENDLESS NIGHT WITH FREDBEAR")

Library:Notify("INFINITY HUB LOADED", 4)
