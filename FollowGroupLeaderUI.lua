FGLUI = {}

function FGLUI:Init()
    self:CreateMainWindow()
    self:CreateConfirmDialog()
end

function FGLUI:CreateMainWindow()
    local wm = WINDOW_MANAGER
    self.ui = wm:CreateTopLevelWindow("FGL_MainUI")
    local ui = self.ui
    ui:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -50, 100)
    ui:SetMovable(true)
    ui:SetMouseEnabled(true)
    ui:SetClampedToScreen(true)
    ui:SetResizeToFitDescendents(true)
    ui:SetHidden(false)

    self.elements = {
        label = wm:CreateControl(nil, ui, CT_LABEL),
        leaderBtn = wm:CreateControl("FGL_LeaderCallButton", ui, CT_BUTTON),
        jumpBtn = wm:CreateControl("FGL_JumpNowButton", ui, CT_BUTTON),
        followBtn = wm:CreateControl("FGL_FollowLeaderButton", ui, CT_BUTTON),
        spinner = wm:CreateControl(nil, ui, CT_LABEL),
        cancelBtn = wm:CreateControl("FGL_CancelFollowButton", ui, CT_BUTTON),
    }

    self.elements.label:SetFont("ZoFontGame")
    self.elements.label:SetAnchor(TOPLEFT, ui, TOPLEFT, 10, 0)
    self.elements.label:SetText("This addon works only in a group.")

    self.elements.leaderBtn:SetFont("ZoFontGame")
    self.elements.leaderBtn:SetDimensions(260, 30)
    self.elements.leaderBtn:SetAnchor(TOPLEFT, ui, TOPLEFT, 10, 0)
    self.elements.leaderBtn:SetText("Call group to me")
    self.elements.leaderBtn:SetHandler("OnClicked", function() FGL:SendTeleportCommand() end)

    self.elements.jumpBtn:SetDimensions(260, 30)
    self.elements.jumpBtn:SetFont("ZoFontGame")
    self.elements.jumpBtn:SetAnchor(TOPLEFT, ui, TOPLEFT, 10, 0)
    self.elements.jumpBtn:SetText("Jump to leader")
    self.elements.jumpBtn:SetHandler("OnClicked", function() JumpToGroupLeader() end)

    self.elements.followBtn:SetDimensions(260, 30)
    self.elements.followBtn:SetFont("ZoFontGame")
    self.elements.followBtn:SetAnchor(TOPLEFT, ui, TOPLEFT, 10, 40)
    self.elements.followBtn:SetText("Follow leader")
    self.elements.followBtn:SetHandler("OnClicked", function() self:EnterFollowMode() end)

    self.elements.spinner:SetFont("ZoFontGame")
    self.elements.spinner:SetAnchor(TOPLEFT, ui, TOPLEFT, 10, 0)
    self.elements.spinner:SetText("Following leader... waiting for teleport command...")

    self.elements.cancelBtn:SetDimensions(260, 30)
    self.elements.cancelBtn:SetFont("ZoFontGame")
    self.elements.cancelBtn:SetAnchor(TOPLEFT, ui, TOPLEFT, 10, 40)
    self.elements.cancelBtn:SetText("Cancel")
    self.elements.cancelBtn:SetHandler("OnClicked", function()
        FGL.autoFollowEnabled = false
        self:UpdateVisibility()
    end)
end

function FGLUI:UpdateVisibility()
    local e = self.elements
    for _, control in pairs(e) do
        control:SetHidden(true)
    end

    local following = FGL.autoFollowEnabled
    local grouped = IsUnitGrouped("player")
    local leader = IsUnitGroupLeader("player")


    if following then
        e.spinner:SetHidden(false)
        e.cancelBtn:SetHidden(false)
        return
    end

    if not grouped then
        e.label:SetHidden(false)
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

-- TODO: remove
function FGLUI:ShowTeleportInvite()
    local messageId = CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_ANNOUNCEMENT_MESSAGE, CSA_EVENT_SMALL_TEXT,
        SOUNDS.ABILITY_MORPH_CHOSEN, "Teleport to leader? [Y/N]")

    local keybind = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = "Yes",
            keybind = "UI_SHORTCUT_PRIMARY", -- клавиша "E" по умолчанию
            callback = function()
                JumpToGroupLeader()
                FGL.awaitingConfirm = false
            end,
        },
        {
            name = "No",
            keybind = "UI_SHORTCUT_NEGATIVE", -- клавиша "Q" по умолчанию
            callback = function()
                FGL.awaitingConfirm = false
            end,
        }
    }

    KEYBIND_STRIP:AddKeybindButtonGroup(keybind)

    -- Автоматически убрать кнопки через 8 секунд
    zo_callLater(function()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(keybind)
    end, 8000)
end
