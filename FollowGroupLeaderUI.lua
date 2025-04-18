FGLUI = {}

function FGLUI:Init()
    self:CreateMainWindow()
    self:CreateAutoFollowModal()
    self:CreateConfirmDialog()
end

function FGLUI:CreateMainWindow()
    local wm = WINDOW_MANAGER
    local ui = wm:CreateTopLevelWindow("FGL_MainUI")
    ui:SetDimensions(300, 180)
    ui:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -50, 100)
    ui:SetMovable(true)
    ui:SetMouseEnabled(true)
    ui:SetClampedToScreen(true)
    ui:SetHidden(false)

    local backdrop = wm:CreateControl(nil, ui, CT_BACKDROP)
    backdrop:SetAnchorFill()
    backdrop:SetCenterColor(0.1, 0.1, 0.1, 0.8)
    backdrop:SetEdgeColor(1, 1, 1, 0.5)

    local title = wm:CreateControl(nil, ui, CT_LABEL)
    title:SetFont("ZoFontGame")
    title:SetText("Follow Group Leader")
    title:SetAnchor(TOP, ui, TOP, 0, 10)

    if IsUnitGroupLeader("player") then
        local leaderBtn = wm:CreateControl("FGL_SendTPCommandButton", ui, CT_BUTTON)
        leaderBtn:SetDimensions(260, 30)
        leaderBtn:SetAnchor(TOP, title, BOTTOM, 0, 20)
        leaderBtn:SetText("Teleport group to me")
        leaderBtn:SetHandler("OnClicked", function()
            FGL:SendTeleportCommand()
        end)
    else
        local autoBtn = wm:CreateControl("FGL_EnableAutoFollowButton", ui, CT_BUTTON)
        autoBtn:SetDimensions(260, 30)
        autoBtn:SetAnchor(TOP, title, BOTTOM, 0, 20)
        autoBtn:SetText("Follow group leader")
        autoBtn:SetHandler("OnClicked", function()
            FGLUI:ShowAutoFollowModal()
        end)
    end
end

function FGLUI:CreateAutoFollowModal()
    local wm = WINDOW_MANAGER
    local backdrop = wm:CreateTopLevelWindow("FGL_AutoFollowModal")
    backdrop:SetDimensions(400, 200)
    backdrop:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    backdrop:SetHidden(true)
    backdrop:SetMovable(true)
    backdrop:SetMouseEnabled(true)

    local bg = wm:CreateControl(nil, backdrop, CT_BACKDROP)
    bg:SetAnchorFill()
    bg:SetCenterColor(0, 0, 0, 0.8)

    local btn = wm:CreateControl("FGL_StopFollowButton", backdrop, CT_BUTTON)
    btn:SetDimensions(180, 30)
    btn:SetAnchor(BOTTOM, backdrop, BOTTOM, 0, -20)
    btn:SetText("Stop following")
    btn:SetHandler("OnClicked", function()
        FGL.autoFollowEnabled = false
        backdrop:SetHidden(true)
    end)

    local lbl = wm:CreateControl("FGL_ModalLabel", backdrop, CT_LABEL)
    lbl:SetAnchor(TOP, backdrop, TOP, 0, 40)
    lbl:SetText("Following leader is active. Waiting for commands...")
end

function FGLUI:ShowAutoFollowModal()
    FGL.autoFollowEnabled = true
    FGL_AutoFollowModal:SetHidden(false)
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
            mustChoose = true,
        })
end

function FGLUI:ShowPrompt(leaderName)
    ZO_Dialogs_ShowDialog("FGL_CONFIRM_JUMP")
end
