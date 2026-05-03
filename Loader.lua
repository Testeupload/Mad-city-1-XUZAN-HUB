--[[
    Loader - AutoExec Mad City
    Carrega o script principal de um arquivo local (mais rápido e confiável)
    Se preferir URL, troque pelo loadstring(game:HttpGet("URL"))
--]]

local function loadMainScript()
    -- Método 1: Carregar de arquivo local (recomendado, não depende de internet)
    local filePath = "AutoPolice.lua"  -- mesmo nome do script principal
    
    if readfile and isfile and isfile(filePath) then
        local scriptContent = readfile(filePath)
        if scriptContent then
            local func, err = loadstring(scriptContent)
            if func then
                func()
                print("[Loader] Script principal carregado com sucesso (local)")
            else
                warn("[Loader] Erro ao compilar script: " .. tostring(err))
            end
        else
            warn("[Loader] Conteúdo do arquivo vazio")
        end
    else
        -- Fallback: carregar de URL (se você tiver o script online)
        -- Descomente a linha abaixo e substitua pela URL raw do seu script
        -- loadstring(game:HttpGet("https://raw.githubusercontent.com/seuusuario/seurepo/main/AutoPolice.lua"))()
        warn("[Loader] Arquivo local não encontrado. Criando template...")
        -- Cria um arquivo template se não existir
        local template = [[
--[[ AutoPolice.lua - Script principal do Auto-Policial Mad City ]]
print("[Auto] Script principal carregado. Substitua este conteúdo pelo script completo.")
]]
        if writefile then
            writefile("AutoPolice.lua", template)
            print("[Loader] Arquivo AutoPolice.lua criado. Cole o script completo nele e reinicie.")
        end
    end
end

-- Pequeno delay para garantir que o jogo carregou
task.wait(2)
loadMainScript()
