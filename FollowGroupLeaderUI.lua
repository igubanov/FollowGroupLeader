FGLUI = {}

function FGLUI:Init()
    self:CreateMainWindow()
    self:CreateConfirmDialog()
end

function FGLUI:CreateMainWindow()
    local ui = FGL_MainUI
    self.ui = ui

    self.elements = {
        -- label = ui:GetNamedChild("Label"),
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

    FGLUI:AddTooltip(self.elements.leaderBtn, "Call group to me")
    FGLUI:AddTooltip(self.elements.jumpBtn, "Jump to leader")
    FGLUI:AddTooltip(self.elements.followBtn, "Follow leader (auto jumpming)")
    FGLUI:AddTooltip(self.elements.cancelBtn, "Cancel")
    FGLUI:AddTooltip(self.elements.spinner, "Waiting leader command to jump")
end

function FGLUI:AddTooltip(control, text)
    control:SetHandler("OnMouseEnter", function(self)
        InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -5)
        SetTooltipText(InformationTooltip, text)
    end)
    control:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
end

function FGLUI:StartSpinnerRotation(spinner)
    local angle = 0
    local rotationSpeed = 5

    local function rotate()
        angle = (angle + rotationSpeed) % 360
        spinner:SetTextureRotation(math.rad(angle))
    end

    zo_callLater(rotate, 50)
    EVENT_MANAGER:RegisterForUpdate("FGL_SpinnerRotation", 50, rotate)
end

function FGLUI:UpdateVisibility()
    local e = self.elements
    for _, control in pairs(e) do
        control:SetHidden(true)
    end

    local following = FGL.autoFollowEnabled
    local grouped = IsUnitGrouped("player")
    local leader = IsUnitGroupLeader("player")

    self.ui:SetHidden(not grouped)

    if following then
        e.spinner:SetHidden(false)
        e.cancelBtn:SetHidden(false)
        return
    end

    -- if not grouped then
    --     e.label:SetHidden(false)
    --     return
    -- end

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
