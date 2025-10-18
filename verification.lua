--[[
UI Keybox + Link / Load remote script
Usage: mettre dans un LocalScript (StarterGui).
Note: pour récupérer/exécuter la raw URL il faut un executor qui permet HttpGet / loadstring.
--]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- configuration
local LINKVERTISE = "https://direct-link.net/1416195/54wjItUk0O6r"
local REMOTE_SCRIPT_URL = "https://raw.githubusercontent.com/ochy-sp/z-cheat/refs/heads/rivals/main.lua"

-- helper pour fetch le contenu d'une URL (essaie plusieurs fonctions selon l'executor)
local function fetchUrl(url)
    -- try syn.request
    if syn and syn.request then
        local ok, res = pcall(function() return syn.request({ Url = url, Method = "GET" }) end)
        if ok and res and res.Body then return res.Body end
    end

    -- try request (some exploits)
    if request then
        local ok, res = pcall(function() return request({ Url = url, Method = "GET" }) end)
        if ok and res and res.Body then return res.Body end
    end

    -- try http_request
    if http_request then
        local ok, res = pcall(function() return http_request({ Url = url, Method = "GET" }) end)
        if ok and res and res.Body then return res.Body end
    end

    -- try game:HttpGet (some environments support it)
    if pcall and game.HttpGet then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then return res end
    end

    -- try game:GetObjects (rare)
    return nil, "Aucune méthode de fetch disponible dans cet environnement."
end

-- helper pour exécuter du code (essaie loadstring ou load)
local function runString(src)
    if not src then return false, "Source vide" end
    -- loadstring (ancien) puis load
    local fn, err = loadstring and loadstring(src) or load(src)
    if not fn then
        return false, ("Erreur load: %s"):format(tostring(err))
    end
    local ok, result = pcall(fn)
    if not ok then
        return false, ("Erreur exec: %s"):format(tostring(result))
    end
    return true, result
end

-- crée l'UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeyBoxGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 160)
frame.Position = UDim2.new(0.5, -210, 0.4, -80)
frame.BackgroundTransparency = 0.12
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Text = "Activation - Entrez la clé"
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = false
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = frame

local keyBox = Instance.new("TextBox")
keyBox.PlaceholderText = "Colle ta clé ici..."
keyBox.Size = UDim2.new(1, -20, 0, 40)
keyBox.Position = UDim2.new(0, 10, 0, 44)
keyBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
keyBox.TextColor3 = Color3.new(1,1,1)
keyBox.ClearTextOnFocus = false
keyBox.Font = Enum.Font.SourceSans
keyBox.TextSize = 18
keyBox.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 92)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1,1,1)
status.Font = Enum.Font.SourceSansItalic
status.TextSize = 16
status.Text = "Statut: en attente..."
status.Parent = frame

-- boutons
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
    b.MouseButton1Click:Connect(function()
        pcall(callback, b)
    end)
    return b
end

-- bouton copier lien
makeButton("Copier Link", 10, function()
    local ok, err = pcall(function()
        if setclipboard then
            setclipboard(LINKVERTISE)
        elseif toclipboard then
            toclipboard(LINKVERTISE)
        else
            error("Fonction de clipboard non disponible")
        end
    end)
    if ok then
        status.Text = "Lien copié dans le presse-papiers."
    else
        status.Text = "Impossible de copier: " .. tostring(err)
    end
end)

-- bouton ouvrir link (ouvre dans navigateur si possible via exploit, sinon copie)
makeButton("Ouvrir Link", 150, function()
    -- certains exploits exposent une fonction pour ouvrir une URL : try openbrowser or setclipboard fallback
    local opened = false
    if pcall(function() if syn and syn.request then opened = false end end) then
        -- pas de méthode universelle pour ouvrir le navigateur; on copie en backup
    end
    -- fallback: copier le lien
    if setclipboard then pcall(setclipboard, LINKVERTISE) end
    status.Text = "Lien prêt : coller dans ton navigateur (copié)."
end)

-- bouton valider clé (exemple très simple : compare à une "clé attendue")
makeButton("Valider clé", 290, function()
    local entered = tostring(keyBox.Text or "")
    if entered == "" then
        status.Text = "Aucune clé entrée."
        return
    end
    -- ici tu peux remplacer la logique par un check serveur (HttpRequest vers ton serveur)
    -- exemple simple : clé attendue "MONCLE123" (change/retire pour prod)
    local expected = "itsthekey77"
    if entered == expected then
        status.Text = "Clé valide. Chargement du script distant..."
        -- fetch & run remote script
        local body, ferr = fetchUrl(REMOTE_SCRIPT_URL)
        if not body then
            status.Text = "Erreur fetch: " .. tostring(ferr)
            return
        end
        local ok, err = runString(body)
        if ok then
            status.Text = "Script distant exécuté avec succès."
        else
            status.Text = "Erreur exécution: " .. tostring(err)
        end
    else
        status.Text = "Clé invalide."
    end
end)

-- bouton pour charger directement le remote (sans clé) — utile si tu veux tester
makeButton("Charger direct", 10 + 120 + 20, function()
    status.Text = "Récupération du script distant..."
    local body, ferr = fetchUrl(REMOTE_SCRIPT_URL)
    if not body then
        status.Text = "Erreur fetch: " .. tostring(ferr)
        return
    end
    local ok, err = runString(body)
    if ok then
        status.Text = "Script distant exécuté avec succès."
    else
        status.Text = "Erreur exec: " .. tostring(err)
    end
end)

-- petite touche : fermer la GUI en appuyant sur ESC
local UserInput = game:GetService("UserInputService")
UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Escape then
        screenGui:Destroy()
    end
end)
