--[[
    Auto-Perseguição Mad City (Original + Server Hop + GUI de Ganhos)
    - Movimento suave com TweenService (igual ao que funcionava)
    - Segura a tecla E por 0.5s para prender
    - GUI mostra níveis e dinheiro GANHOS desde o início (persistente)
    - Server hop automático se menos de 3 criminosos
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
local SAVE_FILE = "MadCity_Gains.txt"

-- ===================== PERSISTÊNCIA =====================
local gains = { totalLevelGain = 0, totalMoneyGain = 0, startTime = nil }

local function saveGains()
    if writefile then
        local data = string.format("%d,%d,%d", gains.totalLevelGain, gains.totalMoneyGain, gains.startTime or tick())
        writefile(SAVE_FILE, data)
        print("[Persist] Salvos: Level +" .. gains.totalLevelGain .. ", Money +" .. gains.totalMoneyGain)
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
                print("[Persist] Carregados: Level +" .. gains.totalLevelGain .. ", Money +" .. gains.totalMoneyGain)
                return
            end
        end
    end
    gains.totalLevelGain = 0
    gains.totalMoneyGain = 0
    gains.startTime = tick()
    saveGains()
end

-- ===================== FUNÇÕES DE DADOS =====================
local function getCurrentRank()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local rank = leaderstats:FindFirstChild("Rank")
        if rank then return rank.Value end
    end
    return 0
end

local function getCurrentMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
        if cash then return cash.Value end
    end
    return 0
end

-- ===================== GUI DE GANHOS =====================
local function createGainsGUI()
    local GUI_NAME = "GainsGUI_MadCity"
    local old = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end

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

-- ===================== MOVIMENTO (TWEEN - IGUAL AO ORIGINAL) =====================
local function disableCollision(char)
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
        print("[Auto] Tecla 3 pressionada")
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
    local nearest, nearestDist = nil, math.huge
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

-- ===================== PERSEGUIÇÃO (ORIGINAL) =====================
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
        local posAlvo = tr.Position + Vector3.new(0, 1.5, 1.5)
        root.CFrame = CFrame.new(posAlvo)
        
        local agora = tick()
        if agora - ultimoPrende >= INTERVALO_PRENDE then
            segurarTeclaE()
            ultimoPrende = agora
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

-- ===================== INICIALIZAÇÃO =====================
loadGains()

local initialRank = getCurrentRank()
local initialMoney = getCurrentMoney()
local totalLevelGain = gains.totalLevelGain
local totalMoneyGain = gains.totalMoneyGain
local startTime = gains.startTime

local gui = createGainsGUI()
spawn(function()
    while true do
        local currentRank = getCurrentRank()
        local currentMoney = getCurrentMoney()
        totalLevelGain = gains.totalLevelGain + (currentRank - initialRank)
        totalMoneyGain = gains.totalMoneyGain + (currentMoney - initialMoney)
        gains.totalLevelGain = totalLevelGain
        gains.totalMoneyGain = totalMoneyGain
        saveGains()
        
        if gui.levelLabel then
            gui.levelLabel.Text = "⭐ Nível ganho: +" .. totalLevelGain
        end
        if gui.moneyLabel then
            gui.moneyLabel.Text = "💰 Dinheiro ganho: +$" .. totalMoneyGain
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

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
disableCollision(character)

joinPolice()
task.wait(0.5)
selectSlot3()
task.wait(0.5)

print("[Auto] Iniciado. Movimento Tween, segura E, server hop ativo.")

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

while true do
    local criminal, dist = getNearestCriminal()
    if criminal then
        print("[Auto] Alvo: " .. criminal.Name .. " (dist " .. math.floor(dist) .. ")")
        perseguirCriminoso(criminal)
    else
        task.wait(1)
    end
end 
