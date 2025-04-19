FGL = {}
FGL.name = "FollowGroupLeader"
FGL.autoFollowEnabled = false
FGL.awaitingConfirm = false

local LGB = LibGroupBroadcast
local handler = LGB:RegisterHandler("FollowGroupLeaderHandler", "FGL")
handler:SetDisplayName("Follow Group Leader")
handler:SetDescription("Teleport group members to the leader via command")

local FireTeleportEvent = handler:DeclareCustomEvent(1, "FGL_Teleport")
LGB:RegisterForCustomEvent("FGL_Teleport", function() FGL:OnTeleportCommand() end)

function FGL.OnAddOnLoaded(event, addonName)
    if addonName ~= FGL.name then return end

    SLASH_COMMANDS["/fgl"] = function(cmd)
        if IsUnitGroupLeader("player") then
            FGL:SendTeleportCommand()
        else
            d("[FGL] Only the group leader can send commands.")
        end
    end

    FGLUI = FGLUI or {}
    FGLUI:Init()
    FGL:onGroupChanged()

    local function onGroupChanged()
        FGL:onGroupChanged()
    end

    EVENT_MANAGER:RegisterForEvent(FGL.name .. "_GROUP_UPDATE", EVENT_GROUP_MEMBER_JOINED, onGroupChanged)
    EVENT_MANAGER:RegisterForEvent(FGL.name .. "_GROUP_UPDATE", EVENT_GROUP_MEMBER_LEFT, onGroupChanged)
    EVENT_MANAGER:RegisterForEvent(FGL.name .. "_GROUP_UPDATE", EVENT_LEADER_UPDATE, onGroupChanged)
end

function FGL:onGroupChanged()
    FGL:OnGroupStatusChanged()
    FGLUI:UpdateVisibility()
end

function FGL:SendTeleportCommand()
    FireTeleportEvent()
    StartChatInput("TP TO ME", CHAT_CHANNEL_PARTY)
end

function FGL:OnTeleportCommand()
    if IsUnitGroupLeader("player") then
        return
    end

    if FGL.autoFollowEnabled then
        zo_callLater(function()
            if not IsUnitInCombat("player") then
                JumpToGroupLeader()
            end
        end, 1500)
    elseif not FGL.awaitingConfirm then
        FGL.awaitingConfirm = true
        FGLUI:ShowPrompt()
    end
end

function FGL:OnGroupStatusChanged()
    if not IsUnitGrouped("player") or IsUnitGroupLeader("player") == false then
        FGL.autoFollowEnabled = false
    end
end

EVENT_MANAGER:RegisterForEvent(FGL.name, EVENT_ADD_ON_LOADED, function(...) FGL.OnAddOnLoaded(...) end)
