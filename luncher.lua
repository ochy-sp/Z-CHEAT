--[[
KeyBox GUI (English) + load remote script ONLY after valid key
Place this in a LocalScript (StarterGui).
Note: fetching & executing remote code requires an executor that allows HTTP and loadstring.
This GUI will try to parent to CoreGui (to appear above the ESC menu). If that fails it uses PlayerGui.
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- configuration
local LINKVERTISE = "https://direct-link.net/1416195/54wjItUk0O6r"
local REMOTE_SCRIPT_URL = "https://raw.githubusercontent.com/ochy-sp/z-cheat/refs/heads/rivals/RIVALS.lua"
local EXPECTED_KEY = "itsthekey77" -- change this to your real key

-- try several fetch methods depending on executor
local function fetchUrl(url)
    if syn and syn.request then
        local ok, res = pcall(function() return syn.request({ Url = url, Method = "GET" }) end)
        if ok and res and res.Body then return res.Body end
    end

    if request then
        local ok, res = pcall(function() return request({ Url = url, Method = "GET" }) end)
        if ok and res and res.Body then return res.Body end
    end

    if http_request then
        local ok, res = pcall(function() return http_request({ Url = url, Method = "GET" }) end)
        if ok and res and res.Body then return res.Body end
    end

    -- game:HttpGet (some environments)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end

    return nil, "No available HTTP fetch method in this environment."
end

-- run code string using load/loadstring
local function runString(src)
    if not src then return false, "Empty source" end
    local loader = loadstring or load
    if not loader then return false, "No load/loadstring available" end
    local success, fnOrErr = pcall(function() return loader(src) end)
    if not success then
        return false, ("Load error: %s"):format(tostring(fnOrErr))
    end
    local func = fnOrErr
    local ok, result = pcall(func)
    if not ok then
        return false, ("Execution error: %s"):format(tostring(result))
    end
    return true, result
end

-- GUI creation
local function createGui(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeyBoxGui"
    screenGui.ResetOnSpawn = false
    -- try to ensure topmost
    pcall(function() screenGui:SetAttribute("forceTop", true) end)
    -- large display order to try to be above other GUIs
    if screenGui.DisplayOrder then
        screenGui.DisplayOrder = 9999
    end
    -- ignore inset so it stays put even with topbar
    if screenGui.IgnoreGuiInset ~= nil then
        screenGui.IgnoreGuiInset = true
    end
    screenGui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 160)
    frame.Position = UDim2.new(0.5, -210, 0.4, -80)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Active = true -- keep it responsive
    frame.ZIndex = 50

    local title = Instance.new("TextLabel")
    title.Text = "Activation - Enter your key"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = frame
    title.ZIndex = 51

    local keyBox = Instance.new("TextBox")
    -- FIXED placeholder text (was showing 'TextBox' before for you)
    keyBox.PlaceholderText = "Put your key here..."
    keyBox.Text = "" -- ensure no default text that can display 'TextBox'
    keyBox.Size = UDim2.new(1, -20, 0, 40)
    keyBox.Position = UDim2.new(0, 10, 0, 44)
    keyBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    keyBox.TextColor3 = Color3.new(1,1,1)
    keyBox.ClearTextOnFocus = false
    keyBox.Font = Enum.Font.SourceSans
    keyBox.TextSize = 18
    keyBox.Parent = frame
    keyBox.ZIndex = 51

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 92)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.new(1,1,1)
    status.Font = Enum.Font.SourceSansItalic
    status.TextSize = 16
    status.Text = "Status: waiting..."
    status.Parent = frame
    status.ZIndex = 51

    local function makeButton(text, posX, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 120, 0, 30)
        b.Position = UDim2.new(0, posX, 0, 116)
        b.Text = text
        b.Parent = frame
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 16
        b.BackgroundColor3 = Color3.fromRGB(45,45,45)
        b.TextColor3 = Color3.new(1,1,1)
        b.ZIndex = 52
        b.MouseButton1Click:Connect(function()
            pcall(callback, b)
        end)
        return b
    end

    -- Copy Link button
    makeButton("Copy Link", 10, function()
        local ok, err = pcall(function()
            if setclipboard then
                setclipboard(LINKVERTISE)
            elseif toclipboard then
                toclipboard(LINKVERTISE)
            else
                error("Clipboard function not available")
            end
        end)
        if ok then
            status.Text = "Link copied to clipboard."
        else
            status.Text = "Copy failed: " .. tostring(err)
        end
    end)

    -- Validate key button (ONLY way to fetch & run remote script)
    makeButton("Validate Key", 150, function()
        local entered = tostring(keyBox.Text or "")
        if entered == "" then
            status.Text = "No key entered."
            return
        end

        if entered == EXPECTED_KEY then
            status.Text = "Key valid. Loading remote script..."
            local body, ferr = fetchUrl(REMOTE_SCRIPT_URL)
            if not body then
                status.Text = "Fetch error: " .. tostring(ferr)
                return
            end

            local ok, err = runString(body)
            if ok then
                status.Text = "Remote script executed successfully."
                -- close GUI after successful execution
                pcall(function() screenGui:Destroy() end)
            else
                status.Text = "Execution error: " .. tostring(err)
            end
        else
            status.Text = "Invalid key."
        end
    end)

    -- Close button (user can still close without running)
    makeButton("Close", 290, function()
        screenGui:Destroy()
    end)

    -- Close UI on ESC (UX)
    local UserInput = game:GetService("UserInputService")
    UserInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            -- keep UX: user can still close with ESC
            pcall(function() screenGui:Destroy() end)
        end
    end)

    return screenGui
end

-- Attempt to parent to CoreGui (so it appears above ESC menu); if not allowed, fallback to PlayerGui
local function safeParentGui()
    -- prefer CoreGui (may require exploit permission)
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local success, sg = pcall(function() return createGui(cg) end)
        if success and sg and sg.Parent == cg then
            -- try to force high DisplayOrder if available
            pcall(function() sg.DisplayOrder = 99999 end)
            return
        end
    end
    -- fallback
    createGui(playerGui)
end

safeParentGui()
