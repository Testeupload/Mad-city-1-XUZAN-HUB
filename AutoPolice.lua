--[[
    AUTO-POLICIAL MAD CITY CHAPTER 1 - COMPLETO
    - Persegue criminosos (Team Criminals)
    - Pressiona E por 0.6s para prender
    - GUI mostra níveis e dinheiro ganhos (persistente)
    - Se menos de 3 criminosos, troca de servidor (server hop)
    - Velocidades otimizadas
    - Persistência de ganhos via arquivo
--]]

-- ===================== CONFIGURAÇÕES =====================
local ALTURA_VOO = 200
local VEL_VOO = 400
local VEL_SUBIDA = 200
local VEL_DESCIDA = 150
local TEMPO_GRUDE_MAX = 5
local TEMPO_SEGURAR_E = 0.6
local MIN_CRIMINOSOS = 3
local CHECK_INTERVAL = 30

local SAVE_FILE = "MadCity_Gains.txt"
local SCRIPT_NAME = "AutoPolice"

-- ===================== PERSISTÊNCIA =====================
local gains = { totalLevelGain = 0, totalMoneyGain = 0, startTime = nil }

local function saveGains()
    if writefile then
        local data = string.format("%d,%d,%d", gains.totalLevelGain, gains.totalMoneyGain, gains.startTime or tick())
        writefile(SAVE_FILE, data)
        print("[Persist] Ganhos salvos: Level +" .. gains.totalLevelGain .. ", Money +" .. gains.totalMoneyGain)
    end
end

local function loadGains()
    if readfile and isfile and isfile(SAVE_FILE) then
        local data = readfile(SAVE_FILE)
        if data then
            local parts = {}
            for part in string.gmatch(data, "[^,]+") do
                table.insert(parts, tonumber(part))
            end
            if #parts >= 3 then
                gains.totalLevelGain = parts[1] or 0
                gains.totalMoneyGain = parts[2] or 0
                gains.startTime = parts[3] or tick()
                print("[Persist] Ganhos carregados: Level +" .. gains.totalLevelGain .. ", Money +" .. gains.totalMoneyGain)
                return
            end
        end
    end
    gains.totalLevelGain = 0
    gains.totalMoneyGain = 0
    gains.startTime = tick()
    saveGains()
end

-- ===================== SERVER HOP =====================
local function serverHop()
    local count = 0
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p.Team and p.Team.Name == "Criminals" then
            count = count + 1
        end
    end
    if count >= MIN_CRIMINOSOS then return false end
    
    print("[Hop] Apenas " .. count .. " criminoso(s). Trocando de servidor...")
    saveGains()
    -- O loader na AutoExec vai reexecutar este script automaticamente
    game:GetService("TeleportService"):Teleport(game.PlaceId)
    return true
end

-- ===================== GUI DE GANHOS =====================
local function createGainsGUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local GUI_NAME = "GainsGUI_MadCity"
    local gui = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
    if gui then gui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = GUI_NAME
    screenGui.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 120)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "📈 GANHOS (desde o início)"
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 0, 25)
    levelLabel.Position = UDim2.new(0, 0, 0, 30)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "⭐ Nível ganho: +0"
    levelLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextSize = 14
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = frame

    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, 0, 0, 25)
    moneyLabel.Position = UDim2.new(0, 0, 0, 55)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "💰 Dinheiro ganho: +$0"
    moneyLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    moneyLabel.Font = Enum.Font.Gotham
    moneyLabel.TextSize = 14
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
    moneyLabel.Parent = frame

    local uptimeLabel = Instance.new("TextLabel")
    uptimeLabel.Size = UDim2.new(1, 0, 0, 25)
    uptimeLabel.Position = UDim2.new(0, 0, 0, 80)
    uptimeLabel.BackgroundTransparency = 1
    uptimeLabel.Text = "⏱️ Tempo: 00:00"
    uptimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    uptimeLabel.Font = Enum.Font.Gotham
    uptimeLabel.TextSize = 14
    uptimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    uptimeLabel.Parent = frame

    return { levelLabel = levelLabel, moneyLabel = moneyLabel, uptimeLabel = uptimeLabel }
end

-- ===================== FUNÇÕES AUXILIARES =====================
local function getCurrentRank()
    local leaderstats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local rankStat = leaderstats:FindFirstChild("Rank")
        if rankStat then return rankStat.Value end
    end
    return 0
end

local function getCurrentMoney()
    local leaderstats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
        if cash then return cash.Value end
    end
    return 0
end

local function joinPolice()
    local RemoteFunction = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")
    if RemoteFunction then
        pcall(function() RemoteFunction:InvokeServer("SetTeam", "Police") end)
        print("[Auto] Time Police ativado")
    end
end

local function selectSlot3()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
    end)
end

local function segurarTeclaE()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(TEMPO_SEGURAR_E)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- ===================== SISTEMA DE PERSEGUIÇÃO =====================
local function isCriminal(player)
    return player ~= game.Players.LocalPlayer and player.Team and player.Team.Name == "Criminals"
end

local function getNearestCriminal()
    local char = game.Players.LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(game.Players:GetPlayers()) do
        if isCriminal(p) and p.Character then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = p
                end
            end
        end
    end
    return nearest, nearestDist
end

local function perseguirCriminoso(criminal)
    local char = game.Players.LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    print("[Auto] Perseguindo " .. criminal.Name)
    
    -- Subir
    local posAlvo = Vector3.new(root.Position.X, ALTURA_VOO, root.Position.Z)
    root.CFrame = CFrame.new(posAlvo)
    task.wait(0.1)
    
    -- Voo horizontal
    while criminal.Character and isCriminal(criminal) do
        local tr = criminal.Character:FindFirstChild("HumanoidRootPart")
        if not tr then break end
        local targetPos = Vector3.new(tr.Position.X, ALTURA_VOO, tr.Position.Z)
        root.CFrame = CFrame.new(targetPos)
        if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(tr.Position.X, 0, tr.Position.Z)).Magnitude < 10 then
            break
        end
        task.wait(0.05)
    end
    
    -- Descer
    if not criminal.Character then return false end
    local tr = criminal.Character:FindFirstChild("HumanoidRootPart")
    if not tr then return false end
    local posDescer = tr.Position + Vector3.new(0, 2, 0)
    root.CFrame = CFrame.new(posDescer)
    task.wait(0.1)
    
    -- Grudar e prender
    local inicio = tick()
    while isCriminal(criminal) and tick() - inicio < TEMPO_GRUDE_MAX do
        if not criminal.Character then break end
        local tr2 = criminal.Character:FindFirstChild("HumanoidRootPart")
        if not tr2 then break end
        root.CFrame = CFrame.new(tr2.Position + Vector3.new(0, 1.5, 1.5))
        segurarTeclaE()
        task.wait(0.2)
    end
    return true
end

-- ===================== INICIALIZAÇÃO =====================
print("[Auto] Iniciando Auto-Policial Mad City...")

loadGains()
local startTime = gains.startTime
local initialRank = getCurrentRank()
local initialMoney = getCurrentMoney()
local totalLevelGain = gains.totalLevelGain
local totalMoneyGain = gains.totalMoneyGain

-- Criar GUI
local guiLabels = createGainsGUI()

-- Loop de atualização da GUI
spawn(function()
    while true do
        local currentRank = getCurrentRank()
        local currentMoney = getCurrentMoney()
        totalLevelGain = gains.totalLevelGain + (currentRank - initialRank)
        totalMoneyGain = gains.totalMoneyGain + (currentMoney - initialMoney)
        gains.totalLevelGain = totalLevelGain
        gains.totalMoneyGain = totalMoneyGain
        saveGains()
        
        if guiLabels.levelLabel then
            guiLabels.levelLabel.Text = "⭐ Nível ganho: +" .. totalLevelGain
        end
        if guiLabels.moneyLabel then
            guiLabels.moneyLabel.Text = "💰 Dinheiro ganho: +$" .. totalMoneyGain
        end
        if guiLabels.uptimeLabel then
            local elapsed = tick() - startTime
            local minutes = math.floor(elapsed / 60)
            local seconds = math.floor(elapsed % 60)
            guiLabels.uptimeLabel.Text = string.format("⏱️ Tempo: %02d:%02d", minutes, seconds)
        end
        task.wait(2)
    end
end)

-- Aguardar personagem
local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") then
        part.CanCollide = false
    end
end

-- Entrar na polícia e equipar slot 3
joinPolice()
task.wait(0.5)
selectSlot3()
task.wait(0.5)

-- Loop de verificação de servidor
spawn(function()
    while true do
        task.wait(CHECK_INTERVAL)
        local count = 0
        for _, p in ipairs(game.Players:GetPlayers()) do
            if isCriminal(p) then
                count = count + 1
            end
        end
        if count < MIN_CRIMINOSOS and count >= 0 then
            local hopped = serverHop()
            if hopped then break end
        end
    end
end)

-- Loop principal de perseguição
while true do
    local criminal, dist = getNearestCriminal()
    if criminal then
        print("[Auto] Alvo: " .. criminal.Name .. " (distância " .. math.floor(dist) .. ")")
        perseguirCriminoso(criminal)
    else
        task.wait(0.5)
    end
end
