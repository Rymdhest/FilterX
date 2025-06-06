LF = LF or {}
local FilterWindow

function LF.createFilterWindow()
    FilterWindow = LF.createBaseWindow("FilterWindow", "Edit Filter")
    LF.FilterWindow = FilterWindow
    FilterWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideFilterWindow()
    end)

    local nameText = FilterWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", FilterWindow, "TOPLEFT", 20, -30)
    nameText:SetText("Name:")
    nameText:SetTextColor(unpack(LF.Colors.Text))

    FilterWindow.nameInputBox = CreateFrame("EditBox", "MyEditableTextField", FilterWindow, "InputBoxTemplate")
    FilterWindow.nameInputBox:SetSize(150, 30)
    FilterWindow.nameInputBox:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    FilterWindow.nameInputBox:SetAutoFocus(false) -- prevent it from stealing focus immediately
    FilterWindow.nameInputBox:SetMaxLetters(30)
    FilterWindow.nameInputBox:SetFontObject("GameFontHighlightSmall")
    FilterWindow.nameInputBox:SetScript("OnEnterPressed", function(self)
        if LF.RenameFilter(LF.GetSelectedFilter(), self:GetText()) then
            UIDropDownMenu_Initialize(LF.MainWindow.dropdown, LF.InitializeDropdown)
            UIDropDownMenu_SetText(LF.MainWindow.dropdown, LF.GetSelectedFilter().name)
        else 
            FilterWindow.nameInputBox:SetText(LF.GetSelectedFilter().name)
        end
        self:ClearFocus() -- unfocus after pressing Enter
    end)
    FilterWindow.nameInputBox:SetScript("OnEscapePressed", function(self)
        FilterWindow.nameInputBox:SetText(LF.GetSelectedFilter().name)
        self:ClearFocus()
    end)

    FilterWindow.autoAddItemCheckbox = CreateFrame("CheckButton", "autoAddItemCheckbox", FilterWindow, "UICheckButtonTemplate")
    FilterWindow.autoAddItemCheckbox:SetPoint("TOPLEFT", FilterWindow, "TOP", 0, -50)
    FilterWindow.autoAddItemCheckbox.text = _G[FilterWindow.autoAddItemCheckbox:GetName() .. "Text"]
    FilterWindow.autoAddItemCheckbox.text:SetText("Auto add vendored items")
    FilterWindow.autoAddItemCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if checked then
            LF.setAutoAddVendor(true)
        else
            LF.setAutoAddVendor(false)
        end
        
    end)

    FilterWindow.autoAddItemDisenchantCheckbox = CreateFrame("CheckButton", "autoAddItemDisenchantCheckbox", FilterWindow, "UICheckButtonTemplate")
    FilterWindow.autoAddItemDisenchantCheckbox:SetPoint("TOPLEFT", FilterWindow, "TOP", 0, -30)
    FilterWindow.autoAddItemDisenchantCheckbox.text = _G[FilterWindow.autoAddItemDisenchantCheckbox:GetName() .. "Text"]
    FilterWindow.autoAddItemDisenchantCheckbox.text:SetText("Auto add Disenchanted items")
    FilterWindow.autoAddItemDisenchantCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if checked then
            LF.setAutoAddDisenchant(true)
        else
            LF.setAutoAddDisenchant(false)
        end
        
    end)

    FilterWindow.autoAddItemCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:SetText("Enable to automatically add items you manually vendor to a generated filter sell rule. When you buy buck an item it is also automatically removed from the rule.", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    FilterWindow.autoAddItemCheckbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

        FilterWindow.autoAddItemDisenchantCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:SetText("Enable to automatically add items you manually disenchant to a generated filter sell rule.", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    FilterWindow.autoAddItemDisenchantCheckbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Create the scroll frame
    FilterWindow.scrollFrame = CreateFrame("ScrollFrame", "FilterScrollFrame", FilterWindow, "UIPanelScrollFrameTemplate")
    FilterWindow.scrollFrame:SetPoint("TOPLEFT", FilterWindow, "TOPLEFT", 10, -100) -- below title    
    FilterWindow.scrollFrame:SetPoint("BOTTOMRIGHT", FilterWindow, "BOTTOMRIGHT", -30, 10)

    -- Create a border frame just behind the scrollFrame
    local border = CreateFrame("Frame", nil, FilterWindow)
    border:SetPoint("TOPLEFT", FilterWindow.scrollFrame, -1, 1)
    border:SetPoint("BOTTOMRIGHT", FilterWindow.scrollFrame, 1, -1)
    border:SetFrameLevel(FilterWindow.scrollFrame:GetFrameLevel() - 1) -- place behind

    -- Add a solid border using backdrop
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8", -- solid texture
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(unpack(LF.Colors.Border)) -- white border (r, g, b, alpha)

    -- add rule button
    local addRuleButton = CreateFrame("Button", "LF_addRuleButton", FilterWindow, "UIPanelButtonTemplate")
    addRuleButton:SetSize(100, 22)
    addRuleButton:SetText("Add Rule")
    addRuleButton:SetPoint("TOPLEFT", FilterWindow, "TOPLEFT", 10, -70)
    addRuleButton:SetScript("OnClick", function()
            local rule = LF.createNewRule()
            LF.SetSelectedRuleByName(rule.name)
            LF.RefreshFilterWindowRuleList()
            LF.showRuleWindow()
    end)

    FilterWindow.content = CreateFrame("Frame", "LootFilterContentFrame", FilterWindow.scrollFrame)
    FilterWindow.scrollFrame:SetScrollChild(FilterWindow.content)

    FilterWindow:SetFrameLevel(20)
end


function LF.showFilterWindow()
    if not LF.FilterWindow then
        LF.createFilterWindow()
    end
    if not LF.db.selectedFilterName then return false end
    FilterWindow:ClearAllPoints()
    FilterWindow:SetPoint("CENTER", LF.MainWindow, "CENTER", 20, -20)
    FilterWindow.nameInputBox:SetText(LF.GetSelectedFilter().name)
    FilterWindow.autoAddItemCheckbox:SetChecked(LF.GetSelectedFilter().isAutoAddWhenVendoring)
    FilterWindow.autoAddItemDisenchantCheckbox:SetChecked(LF.GetSelectedFilter().isAutoAddWhenDisenchanting)
    LF.RefreshFilterWindowRuleList()
    FilterWindow:Show()
    return true
end

function LF.hideFilterWindow()
    if FilterWindow then FilterWindow:Hide() end
    LF.hideRuleWindow()
end


local function OnDeleteRuleClicked(self)
    local ruleName = self.ruleName
    if not ruleName then return end

    StaticPopupDialogs["DELETE_RULE_CONFIRM"] = {
        text = "Are you sure you want to delete the " .. ruleName .. " rule?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            LF.DeleteRuleByName(ruleName)
            LF.RefreshFilterWindowRuleList()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }

    StaticPopup_Show("DELETE_RULE_CONFIRM")
end


local function Entry_OnEnter(self)
    if self.highlight then
        self.highlight:Show()
    end
end

local function Entry_OnLeave(self)
    if self.highlight then
        self.highlight:Hide()
    end
end

local function Entry_OnMouseDown(self)
    if self.ruleName then
        LF.currentSelectedRuleName = self.ruleName
        LF.showRuleWindow()
    end
end

function LF.RefreshFilterWindowRuleList()
    if not FilterWindow then return end
    if not LF.GetSelectedFilter() then return end

        -- Clear previous entries
    for _, child in ipairs({ FilterWindow.content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
        child:UnregisterAllEvents()
        child:ClearAllPoints()
    end
    collectgarbage("collect")

    LF.UpdateMacroText(true)
    local verticalGap = 43
    FilterWindow.content:SetSize(450, #LF.GetSelectedFilter().rules * verticalGap) 
    for i, rule in ipairs(LF.GetSelectedFilter().rules) do
        local entry = CreateFrame("Frame", nil, FilterWindow.content)
        entry:SetSize(460, verticalGap)
        entry:SetPoint("TOPLEFT", FilterWindow.content, "TOPLEFT", 0, -((i-1) * verticalGap))

    -- Icon texture
        local icon = entry:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", entry, "LEFT", 5, -2)

        entry.ruleName = rule.name
        entry:SetScript("OnMouseDown", Entry_OnMouseDown)

        icon:SetTexture(LF.GetIconForRuleAction(rule.action))  -- icon:SetTexture("Interface/ICONS/INV_Misc_Bag_07")   Interface\\Icons\\Ability_Creature_Cursed_02

        -- Highlight texture (initially hidden)
        local highlight = entry:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints(entry)
        highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
        highlight:SetVertexColor(unpack(LF.Colors.Overlay))  -- semi-transparent highlight color
        highlight:Hide()

        entry.highlight = highlight
        entry:SetScript("OnEnter", Entry_OnEnter)
        entry:SetScript("OnLeave", Entry_OnLeave)

        entry:EnableMouse(true)  -- important so OnEnter/OnLeave triggers

        -- Name text (bold)
        local name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 8)
        -- Loot alert
        local nameString = rule.name
        if rule.alert ~= "Nothing" then
            local icon = "|TInterface\\Icons\\INV_Misc_Bell_01:14:14|t"
            local text = " • "..rule.alert .." " .. icon
            nameString = nameString.."|cff"..LF.RGBToHex(unpack(LF.Colors.Highlight)).. text.."|r"
        end


        name:SetText(nameString)
        name:SetTextColor(unpack(LF.Colors.Text))

        -- Description text (smaller font)
        local desc = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
        desc:SetWidth(370)  -- wrap text if too long
        desc:SetJustifyH("LEFT")
        desc:SetText(LF.describeRule(rule))
        desc:SetTextColor(unpack(LF.Colors.Highlight))

        -- Delete Button
        local deleteButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        deleteButton:SetSize(38, 19)
        deleteButton:SetText("Delete")
        deleteButton:SetPoint("RIGHT", entry, "RIGHT", 0, 10)
        deleteButton.ruleName = rule.name
        deleteButton:SetScript("OnClick", OnDeleteRuleClicked)

        -- Enabled Checkbox
        local enabledBox = CreateFrame("CheckButton", nil, entry, "UICheckButtonTemplate")
        enabledBox:SetPoint("RIGHT", entry, "RIGHT", 0, -10)
        enabledBox:SetChecked(rule.isEnabled)
        enabledBox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            if checked then
                rule.isEnabled = true
                LF.RefreshFilterWindowRuleList()
            else
                rule.isEnabled = false
                LF.RefreshFilterWindowRuleList()
            end
        end)

        if not rule.isEnabled then
            icon:SetDesaturated(true)
            name:SetAlpha(0.25)
            desc:SetAlpha(0.2)
            icon:SetAlpha(0.5)
        else

        end

    end
end