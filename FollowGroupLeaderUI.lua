FGLUI = {}
FGLUI.widgetPositionSV = {}

function FGLUI:CreateMainWindow()
    local ui = FGL_MainUI
    self.ui = ui

    FGLUI.widgetPositionSV = ZO_SavedVars:NewAccountWide("widgetPosition", 1, nil, {})
    if FGLUI.widgetPositionSV.top then
        ui:ClearAnchors()
        ui:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, FGLUI.widgetPositionSV.left, FGLUI.widgetPositionSV.top)
    end

    self.elements = {
        leaderBtn = ui:GetNamedChild("LeaderCallButton"),
        jumpBtn = ui:GetNamedChild("JumpNowButton"),
        followBtn = ui:GetNamedChild("FollowLeaderButton"),
        spinner = ui:GetNamedChild("Spinner"),
        cancelBtn = ui:GetNamedChild("CancelFollowButton"),
    }

    self:StartSpinnerRotation(self.elements.spinner)

    self.elements.leaderBtn:SetHandler("OnClicked", function() FGL:SendTeleportCommand() end)
    self.elements.jumpBtn:SetHandler("OnClicked", function() JumpToGroupLeader() end)
    self.elements.followBtn:SetHandler("OnClicked", function() self:EnterFollowMode() end)
    self.elements.cancelBtn:SetHandler("OnClicked", function()
        FGL.autoFollowEnabled = false
        self:UpdateVisibility()
    end)
end

function FGLUI:StartSpinnerRotation(spinner)
    local angle = 0
    local rotationSpeed = 5

    local function rotate()
        angle = (angle + rotationSpeed) % 360
        spinner:SetTextureRotation(math.rad(angle))
    end

    EVENT_MANAGER:RegisterForUpdate("FGL_SpinnerRotation", 50, rotate)
end

function FGLUI:UpdateVisibility()
    local e = self.elements
    for _, control in pairs(e) do
        control:SetHidden(true)
    end

    local following = FGL.autoFollowEnabled
    local leader = IsUnitGroupLeader("player")
    local grouped = leader or IsUnitGrouped("player")

    self.ui:SetHidden(not grouped)

    if following then
        e.spinner:SetHidden(false)
        e.cancelBtn:SetHidden(false)
        return
    end

    if leader then
        e.leaderBtn:SetHidden(false)
        return
    end

    e.jumpBtn:SetHidden(false)
    e.followBtn:SetHidden(false)
end

function FGLUI:EnterFollowMode()
    FGL.autoFollowEnabled = true
    self:UpdateVisibility()
end

function FGLUI:CreateConfirmDialog()
    ZO_Dialogs_RegisterCustomDialog("FGL_CONFIRM_JUMP",
        {
            title = { text = "Teleport to Leader" },
            mainText = { text = function() return "Group leader requests you to teleport. Jump?" end },
            buttons = {
                {
                    text = "Yes",
                    callback = function()
                        JumpToGroupLeader()
                        FGL.awaitingConfirm = false
                    end
                },
                {
                    text = "No",
                    callback = function()
                        FGL.awaitingConfirm = false
                    end
                },
            },
            canQueue = true,
            allowShowOnLoadingScreen = false,
            mustChoose = false,
        })
end

function FGLUI:ShowPrompt()
    ZO_Dialogs_ShowDialog("FGL_CONFIRM_JUMP")
end

function FGLUI:Init()
    self:CreateMainWindow()
    self:CreateConfirmDialog()

    local onceActivatedEventSubscriberName = FGL.name .. "_ONCE_ACTIVATED_EVENT";
    EVENT_MANAGER:RegisterForEvent(onceActivatedEventSubscriberName, EVENT_PLAYER_ACTIVATED,
        function()
            EVENT_MANAGER:UnregisterForEvent(onceActivatedEventSubscriberName, EVENT_PLAYER_ACTIVATED)
            FGLUI:UpdateVisibility()
        end)

    self.ui:SetHandler("OnMoveStop", function()
        self.widgetPositionSV.left = FGLUI.ui:GetLeft()
        self.widgetPositionSV.top = FGLUI.ui:GetTop()
    end)
end
