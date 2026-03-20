local addonName = ...
local addon = CreateFrame("Frame")

local container
local buttons = {}
local initialized = false

local BUTTON_SIZE = 48
local BUTTON_GAP = 6
local CONTAINER_WIDTH = BUTTON_SIZE + 20

local function GetCurrentSpecIndex()
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        return C_SpecializationInfo.GetSpecialization()
    end

    return GetSpecialization()
end

local function GetSpecData(specIndex)
    if not specIndex then
        return nil
    end

    local specID, name, description, icon, role

    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
        specID, name, description, icon, role = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    else
        specID, name, description, icon, role = GetSpecializationInfo(specIndex)
    end

    if not specID then
        return nil
    end

    return {
        specIndex = specIndex,
        specID = specID,
        name = name,
        description = description,
        icon = icon,
        role = role,
    }
end

local function GetVisibleSpecs()
    local specs = {}
    local count = GetNumSpecializations() or 0

    for specIndex = 1, count do
        local data = GetSpecData(specIndex)
        if data then
            specs[#specs + 1] = data
        end
    end

    return specs
end

local function SwitchToSpec(specIndex)
    if not specIndex then
        return
    end

    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("Cannot change specialization in combat.", 1.0, 0.1, 0.1)
        return
    end

    local currentSpec = GetCurrentSpecIndex()
    if currentSpec == specIndex then
        return
    end

    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        C_SpecializationInfo.SetSpecialization(specIndex)
    else
        SetSpecialization(specIndex)
    end
end

local function IsSpellbookPageVisible()
    if not PlayerSpellsFrame or not PlayerSpellsFrame:IsShown() then
        return false
    end

    if PlayerSpellsFrame.SpellBookFrame and PlayerSpellsFrame.SpellBookFrame:IsShown() then
        return true
    end

    return false
end

local function UpdateButtonTooltip(self)
    if not self.specData then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("LEFT", self, "RIGHT", 12, 0)

    GameTooltip:AddLine(self.specData.name or UNKNOWN, 1, 0.82, 0)
    GameTooltip:AddLine(" ")

    if self.specData.specIndex == GetCurrentSpecIndex() then
        GameTooltip:AddLine("Current specialization", 1, 0.1, 0.1)
    else
        GameTooltip:AddLine("Click to switch", 0, 1, 0)
    end

    GameTooltip:Show()
end

local function UpdateButtonState(button, isSelected)
    if isSelected then
        button.selectedGlow:Show()
        button.leftFlair:SetAlpha(1)
        button.icon:SetAlpha(1)
    else
        button.selectedGlow:Hide()
        button.leftFlair:SetAlpha(0.35)
        button.icon:SetAlpha(0.95)
    end
end

local function CreateSpecButton(parent, index)
    local button = CreateFrame("Button", addonName .. "Tab" .. index, parent)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.09, 0.08, 0.95)
    button.bg = bg

    local border = button:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    button.border = border

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", -5, 5)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.icon = icon

    local hoverGlow = button:CreateTexture(nil, "OVERLAY")
    hoverGlow:SetAllPoints()
    hoverGlow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hoverGlow:SetBlendMode("ADD")
    hoverGlow:SetAlpha(0.55)
    hoverGlow:Hide()
    button.hoverGlow = hoverGlow

    local selectedGlow = button:CreateTexture(nil, "OVERLAY")
    selectedGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
    selectedGlow:SetBlendMode("ADD")
    selectedGlow:SetAlpha(0.85)
    selectedGlow:SetPoint("TOPLEFT", icon, -20, 20)
    selectedGlow:SetPoint("BOTTOMRIGHT", icon, 20, -20)
    selectedGlow:Hide()
    button.selectedGlow = selectedGlow

    local leftFlair = button:CreateTexture(nil, "OVERLAY")
    leftFlair:SetWidth(10)
    leftFlair:SetPoint("TOPLEFT", -4, 0)
    leftFlair:SetPoint("BOTTOMLEFT", -4, 0)
    leftFlair:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    leftFlair:SetTexCoord(0.05, 0.18, 0.2, 0.8)
    leftFlair:SetBlendMode("ADD")
    leftFlair:SetAlpha(0.35)
    button.leftFlair = leftFlair

    local pushedShade = button:CreateTexture(nil, "OVERLAY")
    pushedShade:SetAllPoints()
    pushedShade:SetColorTexture(0, 0, 0, 0.2)
    pushedShade:Hide()
    button.pushedShade = pushedShade

    button:SetScript("OnClick", function(self)
        if self.specData then
            SwitchToSpec(self.specData.specIndex)
        end
    end)

    button:SetScript("OnEnter", function(self)
        self.hoverGlow:Show()
        UpdateButtonTooltip(self)
    end)

    button:SetScript("OnLeave", function(self)
        self.hoverGlow:Hide()
        GameTooltip_Hide()
    end)

    button:SetScript("OnMouseDown", function(self)
        self.pushedShade:Show()
        self.icon:ClearAllPoints()
        self.icon:SetPoint("TOPLEFT", 6, -6)
        self.icon:SetPoint("BOTTOMRIGHT", -4, 4)
    end)

    button:SetScript("OnMouseUp", function(self)
        self.pushedShade:Hide()
        self.icon:ClearAllPoints()
        self.icon:SetPoint("TOPLEFT", 5, -5)
        self.icon:SetPoint("BOTTOMRIGHT", -5, 5)
    end)

    return button
end

local function EnsureUI()
    if initialized then
        return
    end

    if not PlayerSpellsFrame then
        return
    end

    container = CreateFrame("Frame", addonName .. "Container", PlayerSpellsFrame)
    container:SetWidth(CONTAINER_WIDTH)
    container:SetPoint("TOPLEFT", PlayerSpellsFrame, "TOPRIGHT", -1, -74)
    container:SetFrameStrata("HIGH")
    container:SetFrameLevel(PlayerSpellsFrame:GetFrameLevel() + 5)

    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints()
    container.bg:SetColorTexture(0.14, 0.12, 0.10, 0.94)

    container.top = container:CreateTexture(nil, "BORDER")
    container.top:SetPoint("TOPLEFT")
    container.top:SetPoint("TOPRIGHT")
    container.top:SetHeight(2)
    container.top:SetColorTexture(0.6, 0.6, 0.6, 0.8)

    container.right = container:CreateTexture(nil, "BORDER")
    container.right:SetPoint("TOPRIGHT")
    container.right:SetPoint("BOTTOMRIGHT")
    container.right:SetWidth(2)
    container.right:SetColorTexture(0.6, 0.6, 0.6, 0.8)

    container.bottom = container:CreateTexture(nil, "BORDER")
    container.bottom:SetPoint("BOTTOMLEFT")
    container.bottom:SetPoint("BOTTOMRIGHT")
    container.bottom:SetHeight(2)
    container.bottom:SetColorTexture(0.6, 0.6, 0.6, 0.8)

    for i = 1, 4 do
        buttons[i] = CreateSpecButton(container, i)
    end

    container:Hide()
    initialized = true
end

local function LayoutButtons()
    if not container then
        return
    end

    local y = 0

    for i = 1, #buttons do
        local button = buttons[i]
        if button and button:IsShown() then
            button:ClearAllPoints()
            button:SetPoint("TOP", container, "TOP", 0, -7 - y)
            y = y + BUTTON_SIZE + BUTTON_GAP
        end
    end

    container:SetHeight(math.max(y + 8, BUTTON_SIZE + 14))
end

local function UpdateButtons()
    EnsureUI()
    if not initialized then
        return
    end

    local specs = GetVisibleSpecs()
    local currentSpec = GetCurrentSpecIndex()

    if #specs <= 1 then
        for i = 1, #buttons do
            buttons[i]:Hide()
        end
        container:Hide()
        return
    end

    for i = 1, #buttons do
        local button = buttons[i]
        local data = specs[i]

        if data then
            button.specData = data
            button.icon:SetTexture(data.icon or 134400)
            button:Show()
            UpdateButtonState(button, currentSpec == data.specIndex)
        else
            button.specData = nil
            button:Hide()
            button.hoverGlow:Hide()
            button.selectedGlow:Hide()
        end
    end

    LayoutButtons()

    if IsSpellbookPageVisible() then
        container:Show()
    else
        container:Hide()
    end
end

local function OnPlayerSpellsFrameShown()
    UpdateButtons()
end

local function OnPlayerSpellsFrameHidden()
    if container then
        container:Hide()
    end
end

local function TryHookPlayerSpellsFrame()
    if not PlayerSpellsFrame then
        return
    end

    EnsureUI()

    if not PlayerSpellsFrame.__SpellbookSpecSwitcherHooked then
        PlayerSpellsFrame:HookScript("OnShow", OnPlayerSpellsFrameShown)
        PlayerSpellsFrame:HookScript("OnHide", OnPlayerSpellsFrameHidden)
        PlayerSpellsFrame.__SpellbookSpecSwitcherHooked = true
    end

    if PlayerSpellsFrame.SpellBookFrame and not PlayerSpellsFrame.SpellBookFrame.__SpellbookSpecSwitcherHooked then
        PlayerSpellsFrame.SpellBookFrame:HookScript("OnShow", UpdateButtons)
        PlayerSpellsFrame.SpellBookFrame:HookScript("OnHide", UpdateButtons)
        PlayerSpellsFrame.SpellBookFrame.__SpellbookSpecSwitcherHooked = true
    end
end

addon:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        TryHookPlayerSpellsFrame()
        return
    end

    if event == "ADDON_LOADED" and arg1 == "Blizzard_PlayerSpells" then
        TryHookPlayerSpellsFrame()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        UpdateButtons()
        return
    end

    if event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
        UpdateButtons()
        return
    end

    if event == "SPECIALIZATION_CHANGE_CAST_FAILED" then
        UpdateButtons()
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "SPELLS_CHANGED" then
        UpdateButtons()
        return
    end
end)

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
addon:RegisterEvent("SPECIALIZATION_CHANGE_CAST_FAILED")
addon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
addon:RegisterEvent("SPELLS_CHANGED")
