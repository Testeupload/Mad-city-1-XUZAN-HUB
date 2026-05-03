-- Loader Universal para Mad City Auto-Policial
local SCRIPT_URL = "https://raw.githubusercontent.com/Testeupload/Mad-city-1-XUZAN-HUB/refs/heads/main/AutoPolice.lua"

-- Aguarda o jogo carregar minimamente
task.wait(5)

-- Carrega e executa o script principal
loadstring(game:HttpGet(SCRIPT_URL))()
