local FGL = {}
FGL.name = "FollowGroupLeader"
FGL.autoFollowEnabled = false
FGL.awaitingConfirm = false

-- Получаем ссылку на библиотеку LibGroupBroadcast
local LGB = LibGroupBroadcast

-- Регистрация обработчика
local handler = LGB:RegisterHandler("FGL_Handler")
handler:SetDisplayName("Follow Group Leader Handler")
handler:SetDescription("Handles teleport commands for group leader")

-- Регистрируем пользовательское событие
local FireEvent = handler:DeclareCustomEvent(12, "FGL_TeleportEvent")

-- Функция для обработки команды телепортации
function FGL.OnAddOnLoaded(event, addonName)
    if addonName ~= FGL.name then return end

    -- Регистрация события для получения телепортации
    LGB:RegisterForCustomEvent("FGL_TeleportEvent", function(unitTag)
        FGL:OnTeleportCommand(unitTag)
    end)

    SLASH_COMMANDS["/fgl"] = function(cmd)
        if IsUnitGroupLeader("player") then
            FGL:SendTeleportCommand()
        else
            d("[FGL] Only the group leader can send commands.")
        end
    end

    FGLUI:Init()
end

-- Функция для отправки команды телепортации
function FGL:SendTeleportCommand()
    local msg = { leader = GetUnitName("player"), timestamp = GetTimeStamp() }

    -- Отправляем событие с данными
    FireEvent()

    -- Отправляем сообщение в чат
    StartChatInput("TP TO ME", CHAT_CHANNEL_PARTY)
end

-- Функция для обработки команды телепортации
function FGL:OnTeleportCommand(data)
    if FGL.autoFollowEnabled then
        zo_callLater(function()
            if not IsUnitInCombat("player") then
                JumpToGroupLeader()
            end
        end, 1500)
    elseif not FGL.awaitingConfirm then
        FGL.awaitingConfirm = true
        FGLUI:ShowPrompt(data.leader)
    end
end

EVENT_MANAGER:RegisterForEvent(FGL.name, EVENT_ADD_ON_LOADED, function(...) FGL.OnAddOnLoaded(...) end)
_FGL = FGL
