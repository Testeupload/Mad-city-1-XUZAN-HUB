--[[
    AUTO-POLICIAL MAD CITY - VERSÃO COM CARREGAMENTO ROBUSTO
    - Aguarda o jogo carregar completamente (personagem, leaderstats, time)
    - Após server hop, espera 5-6 segundos antes de prosseguir
    - Movimento Tween, segura E, server hop automático, persistência total
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ===================== CONFIGURAÇÕES =====================
local ALTURA_VOO = 200
local VEL_VOO = 300
local VEL_SUBIDA = 150
local VEL_DESCIDA = 120
local TEMPO_GRUDE_MAX = 5
local INTERVALO_PRENDE = 0.8
local TEMPO_SEGURAR_E = 0.5
local MIN_CRIMINOSOS = 3
local CHECK_INTERVAL = 30
local TEMPO_ESPERA_CARREGAR = 6  -- segundos após teleporte

local SAVE_FILE = "MadCity_Gains.txt"

-- ===================== PERSISTÊNCIA TOTAL =====================
local gains = { totalLevelGain = 0, totalMoneyGain = 0, startTime = nil, initialRank = nil, initialMoney = nil }

local function saveGains()
    if writefile then
        local data = string.format("%d,%d,%d,%d,%d",
            gains.totalLevelGain, gains.totalMoneyGain,
            gains.startTime or tick(),
            gains.initialRank or 0, gains.initialMoney or 0)
        writefile(SAVE_FILE, data)
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
            if #parts >= 5 then
                gains.totalLevelGain = parts[1] or 0
                gains.totalMoneyGain = parts[2] or 0
                gains.startTime = parts[3] or tick()
                gains.initialRank = parts[4]
                gains.initialMoney = parts[5]
                return
            end
        end
    end
    -- Primeira execução: será preenchido após o jogo carregar
    gains.totalLevelGain = 0
    gains.totalMoneyGain = 0
    gains.startTime = tick()
    gains.initialRank = nil
    gains.initialMoney = nil
end

-- ===================== FUNÇÕES DE OBTENÇÃO (COM SEGURANÇA) =====================
local function getCurrentRank()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local rankStat = leaderstats:FindFirstChild("Rank") or leaderstats:FindFirstChild("Level")
        if rankStat then
            return rankStat.Value
        end
    end
    return 0
end

local function getCurrentMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
        if cash then
            return cash.Value
        end
    end
    return 0
end

-- ===================== ATUALIZAÇÃO DOS GANHOS (COM INICIALIZAÇÃO) =====================
local function initializeGains()
    -- Se os valores iniciais ainda não foram salvos, salva agora
    if gains.initialRank == nil then
        gains.initialRank = getCurrentRank()
        gains.initialMoney = getCurrentMoney()
        gains.startTime = tick()
        saveGains()
        print("[Persist] Valores iniciais salvos: Rank=" .. gains.initialRank .. ", Money=" .. gains.initialMoney)
    end
end

local function updateGains()
    local currentRank = getCurrentRank()
    local currentMoney = getCurrentMoney()
    gains.totalLevelGain = currentRank - gains.initialRank
    gains.totalMoneyGain = currentMoney - gains.initialMoney
    saveGains()
    return gains.totalLevelGain, gains.totalMoneyGain
end

-- ===================== GUI =====================
local function createGainsGUI()
    local GUI_NAME = "GainsGUI_MadCity"
    local oldGui = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = GUI_NAME
    screenGui.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 110)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "📈 GANHOS (desde início)"
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

-- ===================== MOVIMENTO (TWEEN) =====================
local function disableCollision(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function moverPara(root, posAlvo, duracao)
    local tween = TweenService:Create(root, TweenInfo.new(duracao, Enum.EasingStyle.Linear), {CFrame = CFrame.new(posAlvo)})
    tween:Play()
    tween.Completed:Wait()
end

local function subir(root)
    local posAtual = root.Position
    if posAtual.Y >= ALTURA_VOO - 10 then return end
    local posAlvo = Vector3.new(posAtual.X, ALTURA_VOO, posAtual.Z)
    local dist = (posAlvo - posAtual).Magnitude
    moverPara(root, posAlvo, dist / VEL_SUBIDA)
end

local function moverHorizontal(root, destinoXZ)
    local posAtual = root.Position
    local posAlvo = Vector3.new(destinoXZ.X, ALTURA_VOO, destinoXZ.Z)
    local dist = (posAlvo - posAtual).Magnitude
    if dist < 1 then return end
    moverPara(root, posAlvo, dist / VEL_VOO)
end

local function descer(root, posFinal)
    local posAtual = root.Position
    local dist = (posAtual.Y - posFinal.Y)
    if dist <= 0 then return end
    moverPara(root, posFinal, dist / VEL_DESCIDA)
end

-- ===================== AÇÕES =====================
local function joinPolice()
    local RemoteFunction = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunction")
    if RemoteFunction then
        pcall(function() RemoteFunction:InvokeServer("SetTeam", "Police") end)
        print("[Auto] Time Police ativado")
    end
end

local function selectSlot3()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
    end)
end

local function segurarTeclaE()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(TEMPO_SEGURAR_E)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- ===================== DETECÇÃO =====================
local function isCriminal(player)
    if player == LocalPlayer then return false end
    return player.Team and player.Team.Name == "Criminals"
end

local function getNearestCriminal()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pos = root.Position
    local nearest = nil
    local nearestDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if isCriminal(p) and p.Character then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (targetRoot.Position - pos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = p
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ===================== PERSEGUIÇÃO =====================
local function perseguirCriminoso(criminal)
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    print("[Auto] Perseguindo " .. criminal.Name)

    subir(root)
    task.wait(0.1)

    repeat
        if not criminal.Character then return false end
        local targetRoot = criminal.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return false end
        local posCrim = targetRoot.Position
        moverHorizontal(root, Vector3.new(posCrim.X, ALTURA_VOO, posCrim.Z))
        task.wait(0.05)
        if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(posCrim.X, 0, posCrim.Z)).Magnitude < 10 then
            break
        end
    until not criminal.Character or not isCriminal(criminal)

    if not criminal.Character then return false end
    local targetRoot = criminal.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    descer(root, targetRoot.Position + Vector3.new(0, 2, 0))
    task.wait(0.1)

    local inicio = tick()
    local ultimoPrende = 0
    while isCriminal(criminal) and tick() - inicio < TEMPO_GRUDE_MAX do
        if not criminal.Character then break end
        local tr = criminal.Character:FindFirstChild("HumanoidRootPart")
        if not tr then break end
        root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 1.5, 1.5))

        if tick() - ultimoPrende >= INTERVALO_PRENDE then
            segurarTeclaE()
            ultimoPrende = tick()
        end
        task.wait(0.1)
    end

    if not isCriminal(criminal) then
        print("[Auto] " .. criminal.Name .. " foi preso!")
    else
        print("[Auto] Tempo esgotado para " .. criminal.Name)
    end
    return true
end

-- ===================== SERVER HOP =====================
local function serverHop()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if isCriminal(p) then count = count + 1 end
    end
    if count >= MIN_CRIMINOSOS then return false end

    print("[Hop] Apenas " .. count .. " criminoso(s). Trocando de servidor...")
    saveGains()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
    return true
end

-- ===================== INICIALIZAÇÃO ROBUSTA (ESPERA O JOGO CARREGAR) =====================
print("[Auto] Aguardando carregamento do jogo...")
task.wait(TEMPO_ESPERA_CARREGAR)  -- espera 6 segundos para o jogo estabilizar

-- Aguarda o personagem existir
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
-- Aguarda o HumanoidRootPart
local rootPart = character:WaitForChild("HumanoidRootPart", 10)
-- Aguarda leaderstats (pode demorar mais alguns segundos)
local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
if not leaderstats then
    leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
end

print("[Auto] Jogo carregado. Iniciando...")

-- Carregar ganhos salvos
loadGains()

-- Se os valores iniciais ainda não foram definidos (primeira execução), define agora
if gains.initialRank == nil then
    gains.initialRank = getCurrentRank()
    gains.initialMoney = getCurrentMoney()
    gains.startTime = tick()
    saveGains()
    print("[Persist] Primeira execução. Valores iniciais: Rank=" .. gains.initialRank .. ", Money=" .. gains.initialMoney)
end

-- Criar GUI
local gui = createGainsGUI()
local startTime = gains.startTime

-- Loop de atualização do GUI
spawn(function()
    while true do
        local levelGain, moneyGain = updateGains()
        if gui.levelLabel then
            gui.levelLabel.Text = "⭐ Nível ganho: +" .. levelGain
        end
        if gui.moneyLabel then
            gui.moneyLabel.Text = "💰 Dinheiro ganho: +$" .. moneyGain
        end
        if gui.uptimeLabel then
            local elapsed = tick() - startTime
            local minutes = math.floor(elapsed / 60)
            local seconds = math.floor(elapsed % 60)
            gui.uptimeLabel.Text = string.format("⏱️ Tempo: %02d:%02d", minutes, seconds)
        end
        task.wait(2)
    end
end)

-- Desabilitar colisão
disableCollision(character)

-- Entrar na polícia e selecionar slot 3
joinPolice()
task.wait(0.5)
selectSlot3()
task.wait(0.5)

print("[Auto] Patrulha iniciada. Server hop ativo (min criminosos: " .. MIN_CRIMINOSOS .. ")")

-- Verificador periódico de quantidade de criminosos
spawn(function()
    while true do
        task.wait(CHECK_INTERVAL)
        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if isCriminal(p) then count = count + 1 end
        end
        if count < MIN_CRIMINOSOS then
            serverHop()
            break
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
        task.wait(1)
    end
end
