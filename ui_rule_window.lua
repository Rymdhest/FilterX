LF = LF or {}


-- Limit how many times we retry (e.g., 5 times)
local MAX_RETRIES = 5
local RETRY_DELAY = 0.5
-- Hidden tooltip for triggering server queries
local queryTooltip = CreateFrame("GameTooltip", "LFHiddenTooltip", UIParent, "GameTooltipTemplate")
queryTooltip:SetOwner(UIParent, "ANCHOR_NONE")
queryTooltip:Hide()

-- Function to validate inputs and update rule
local function ValidateAndUpdateMinMaxRule(minInput, maxInput, rule, minFieldName, maxFieldName)
    local minVal = tonumber(minInput:GetText())
    local maxVal = tonumber(maxInput:GetText())

    -- Treat empty or invalid as no limit (nil)
    if not minVal or minVal < 0 then minVal = nil end
    if not maxVal or maxVal < 0 then maxVal = nil end

    -- Validation: max >= min if both are set
    if minVal and maxVal and maxVal < minVal then
        -- Show error or fix automatically - here we just reset maxInput
        maxInput:SetText(minVal)
        maxVal = minVal
    end
    if rule then
        rule[minFieldName] = minVal or nil  -- or nil if your code supports
        rule[maxFieldName] = maxVal or nil
        LF.RefreshFilterWindowRuleList()
    end
end

local function TryAddItemByInput(inputText, retryCount)
    retryCount = retryCount or 0
    local rule = LF.GetSelectedRule()
    if not rule then return end

    local itemID

    -- From item link
    local linkID = inputText:match("item:(%d+)")
    if linkID then
        itemID = tonumber(linkID)
    elseif tonumber(inputText) then
        itemID = tonumber(inputText)
    end

    if itemID then
        local name = LF.GetItemInfo(itemID)
        if name then
            LF.AddItemIDToRule(rule, itemID)
            LF.RefreshRuleWindowItemList()
        elseif retryCount < MAX_RETRIES then
            queryTooltip:SetHyperlink("item:" .. itemID)
            queryTooltip:Show()
            queryTooltip:Hide()
            C_Timer.After(RETRY_DELAY, function()
                TryAddItemByInput(inputText, retryCount + 1)
            end)
        else
            print("|cffff0000[LF]|r Item not found or not cached after several attempts.")
        end
        return
    end

    -- Assume it's a name
    local foundID
    for i = 1, 300000 do
        local name = LF.GetItemInfo(i)
        if name and name:lower() == inputText:lower() then
            foundID = i
            break
        end
    end

    if foundID then
        LF.AddItemIDToRule(rule, foundID)
        LF.RefreshRuleWindowItemList()
    else
        print("|cffff0000[LF]|r Item not found or not cached. Try shift-clicking it or typing an item ID.")
    end
end

local function createNameEdit()
    local nameText = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", RuleWindow, "TOPLEFT", 10, -40)
    nameText:SetText("Name:")
    nameText:SetTextColor(unpack(LF.Colors.Text))

    local nameInputBox = CreateFrame("EditBox", "MyEditableTextField2", RuleWindow, "InputBoxTemplate")
    nameInputBox:SetSize(90, 30)
    nameInputBox:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    nameInputBox:SetAutoFocus(false) -- prevent it from stealing focus immediately
    nameInputBox:SetMaxLetters(30)
    nameInputBox:SetFontObject("GameFontHighlightSmall")
    nameInputBox:SetScript("OnEnterPressed", function(self)
        if LF.RenameRuleInCurrentFilter(LF.GetSelectedRule(), self:GetText()) then
            LF.RefreshFilterWindowRuleList()
        else 
            nameInputBox:SetText(LF.GetSelectedRule().name)
        end
        self:ClearFocus() -- unfocus after pressing Enter
    end)
    nameInputBox:SetScript("OnEscapePressed", function(self)
        nameInputBox:SetText(LF.GetSelectedFilter().name)
        self:ClearFocus()
    end)
    return nameInputBox
end

local function setShowOrHideFram(frame, show)
    if show then
        frame:Show()
    else
        frame:Hide()
    end
end

local function handleModeChange(mode)
    local isItemListMode = (mode == "Items")
    setShowOrHideFram(RuleWindow.itemList, isItemListMode)
    
    isItemListMode = (mode == "Conditions")
    setShowOrHideFram(RuleWindow.goldValue, isItemListMode)
    setShowOrHideFram(RuleWindow.itemLevel, isItemListMode)
    setShowOrHideFram(RuleWindow.levelReq, isItemListMode)
    setShowOrHideFram(RuleWindow.itemCount, isItemListMode)
    setShowOrHideFram(RuleWindow.rarityBoxes, isItemListMode)
    setShowOrHideFram(RuleWindow.equippable, isItemListMode)
    setShowOrHideFram(RuleWindow.recipe, isItemListMode)
    setShowOrHideFram(RuleWindow.mount, isItemListMode)
    setShowOrHideFram(RuleWindow.pet, isItemListMode)

end

local function createModeSelect()
    local nameText = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPRIGHT", RuleWindow, "TOPRIGHT", -320, -40)
    nameText:SetText("Mode:")
    nameText:SetTextColor(unpack(LF.Colors.Text))
    local modeDropdown = CreateFrame("Frame", "LFModelDropdown", RuleWindow, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("LEFT", nameText, "RIGHT", -10, 0)
    UIDropDownMenu_SetWidth(modeDropdown, 100)
    UIDropDownMenu_Initialize(modeDropdown, function(self, level)
        for modeName in pairs(LF.modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = LF.modes[modeName]
            info.func = function()
                -- When clicked, save selection and update dropdown text
                modeDropdown.selectedMode = modeName
                UIDropDownMenu_SetText(modeDropdown, LF.modes[modeName])
                
                -- Here update the rule's action to this selection
                if LF.GetSelectedRule() then
                    LF.GetSelectedRule().mode = modeName
                    handleModeChange(modeName)
                    LF.RefreshFilterWindowRuleList()
                end
            end
            info.checked = (modeDropdown.selectedMode == modeName)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    return modeDropdown
end

local function createActionSelect()
    local nameText = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPRIGHT", RuleWindow, "TOPRIGHT", -140, -40)
    nameText:SetText("Outcome:")
    nameText:SetTextColor(unpack(LF.Colors.Text))
    local actionDropdown = CreateFrame("Frame", "LFActionDropdown", RuleWindow, "UIDropDownMenuTemplate")
    actionDropdown:SetPoint("LEFT", nameText, "RIGHT", -10, 0)
    UIDropDownMenu_SetWidth(actionDropdown, 100)
    UIDropDownMenu_Initialize(actionDropdown, function(self, level)
        for actionName, iconPath in pairs(LF.actions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = actionName
            info.func = function()
                -- When clicked, save selection and update dropdown text
                actionDropdown.selectedAction = actionName
                UIDropDownMenu_SetText(actionDropdown, actionName.." |T" .. LF.actions[actionName].icon ..":16:16:0:0|t")
                
                -- Here update the rule's action to this selection
                if LF.GetSelectedRule() then
                    LF.GetSelectedRule().action = actionName
                    LF.RefreshFilterWindowRuleList()
                end
            end
            info.checked = (actionDropdown.selectedAction == actionName)
            info.icon = LF.actions[actionName].icon
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    return actionDropdown
end

local function createItemList()
    local itemListFrame = CreateFrame("Frame", "itemListFrame", RuleWindow)
    itemListFrame:SetPoint("TOPLEFT", RuleWindow, "TOPLEFT", 10, -80)
    itemListFrame:SetPoint("BOTTOMRIGHT", RuleWindow, "BOTTOMRIGHT", -250, 50)

    -- Add a scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", "ruleItemScrollFrame", itemListFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()

    itemListFrame.itemListContent = CreateFrame("Frame", "ruleItemListContent", scrollFrame)
    itemListFrame.itemListContent:SetSize(200, 1) -- Width fixed, height will expand
    scrollFrame:SetScrollChild(itemListFrame.itemListContent)

    -- Create a border frame just behind the scrollFrame
    local border = CreateFrame("Frame", nil, itemListFrame)
    border:SetPoint("TOPLEFT", scrollFrame, -1, 1)
    border:SetPoint("BOTTOMRIGHT", scrollFrame, 1, -1)
    border:SetFrameLevel(scrollFrame:GetFrameLevel() - 1) -- place behind
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8", 
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(unpack(LF.Colors.Border))

    -- Input box
    local inputBox = CreateFrame("EditBox", "addItemIDbox", itemListFrame, "InputBoxTemplate")
    inputBox:SetSize(180, 20)
    inputBox:SetPoint("TOPLEFT", itemListFrame, "BOTTOMLEFT", 10, -10)
    inputBox:SetAutoFocus(false)
    inputBox:SetFontObject("GameFontHighlightSmall")
    -- Allow shift-clicking item links into the box
    ChatEdit_InsertLink = function(link)
        if inputBox:HasFocus() then
            inputBox:Insert(link)
            return true
        end
    end
    -- Handle pressing Enter
    inputBox:SetScript("OnEnterPressed", function(self)
        local input = self:GetText()
        self:SetText("")
        if input and input:len() > 0 then
            TryAddItemByInput(input)
        end
    end)
    -- Add button
    local addButton = CreateFrame("Button", nil, itemListFrame, "UIPanelButtonTemplate")
    addButton:SetSize(45, 20)
    addButton:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
    addButton:SetText("Add")

    -- Add button handler
    addButton:SetScript("OnClick", function()
        local input = inputBox:GetText()
        inputBox:SetText("")
        if input and input:len() > 0 then
            TryAddItemByInput(input)
        end
    end)

    return itemListFrame
end
local function createMinMaxInput(labelText, yOffset, minVarName, maxVarName, frameNamePrefix)
    local frame = CreateFrame("Frame", frameNamePrefix .. "SelectFrame", RuleWindow)
    local function createInput(name)
        local input = CreateFrame("EditBox", name, frame, "InputBoxTemplate")
        input:SetSize(35, 20)
        input:SetAutoFocus(false)
        input:SetNumeric(true)
        input:SetMaxLetters(4)
        input:SetText("")
        return input
    end

    local function setValidationScripts(input, minInput, maxInput, minVar, maxVar)
        local function onFocusLost(self)
            ValidateAndUpdateMinMaxRule(minInput, maxInput, LF.GetSelectedRule(), minVar, maxVar)
            self:ClearFocus()
        end
        input:SetScript("OnEnterPressed", onFocusLost)
        input:SetScript("OnEscapePressed", onFocusLost)
        input:SetScript("OnEditFocusLost", onFocusLost)
    end

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPRIGHT", RuleWindow, "TOP", 95, yOffset)
    frame.title:SetText(labelText)
    frame.title:SetTextColor(unpack(LF.Colors.Text))

    -- Min label and input
    local minLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minLabel:SetPoint("LEFT", frame.title, "RIGHT", 5, 0)
    minLabel:SetText("Min")
    minLabel:SetTextColor(unpack(LF.Colors.Text))

    local minInput = createInput("min" .. frameNamePrefix .. "Input")
    minInput:SetPoint("LEFT", minLabel, "RIGHT", 10, 0)

    -- Max label and input
    local maxLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maxLabel:SetPoint("LEFT", minInput, "RIGHT", 10, 0)
    maxLabel:SetText("Max")
    maxLabel:SetTextColor(unpack(LF.Colors.Text))

    local maxInput = createInput("max" .. frameNamePrefix .. "Input")
    maxInput:SetPoint("LEFT", maxLabel, "RIGHT", 10, 0)

    -- Scripts
    setValidationScripts(minInput, minInput, maxInput, minVarName, maxVarName)
    setValidationScripts(maxInput, minInput, maxInput, minVarName, maxVarName)

    frame.min = minInput
    frame.max = maxInput
    return frame
end

local function createRarityCheckboxes()
    local rarityContainer = CreateFrame("Frame", nil, RuleWindow)
    rarityContainer:SetSize(100, 150)
    rarityContainer:SetPoint("TOPLEFT", RuleWindow, "TOPLEFT", 10, -100)

    local rarityCheckboxes = {}
    for id, data in pairs(LF.ItemRarities) do
        local checkbox = CreateFrame("CheckButton", nil, rarityContainer, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 0, -20 * id)

        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
        label:SetText(data.name)
        label:SetTextColor(unpack(data.color))

        checkbox:SetScript("OnClick", function(self)
            local selectedRule = LF.GetSelectedRule()
            if self:GetChecked() then 
                selectedRule.rarity[LF.ItemRarities[id].name] = true
            else
                selectedRule.rarity[LF.ItemRarities[id].name] = false
            end
            LF.RefreshFilterWindowRuleList()
        end)

        rarityCheckboxes[id] = checkbox
    end
    rarityContainer.rarityCheckboxes = rarityCheckboxes
    return rarityContainer
end

-- Utility: Show/hide suboptions
local function UpdateSubOptionVisibility(fieldValue, frame)
    if fieldValue == "Any" then
        frame.dropDown2:Hide()
        frame.label2:Hide()
    else
        frame.dropDown2:Show()
        frame.label2:Show()
    end
end

-- Utility: Create a dropdown initializer
local function CreateDropdownInitializer(fieldName, onChange, updateVisibility)
    return function(self, level)
        local function CreateOption(value, id)
            local info = UIDropDownMenu_CreateInfo()
            info.text = value   
            info.func = function()
                UIDropDownMenu_SetSelectedID(self, id)

                local rule = LF.GetSelectedRule()

                LF.GetSelectedRule()[fieldName] = value
                LF.RefreshFilterWindowRuleList()
                if updateVisibility then
                    updateVisibility(LF.GetSelectedRule()[fieldName], self:GetParent())
                end
                if onChange then
                    onChange(value)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end

        CreateOption("Any", 1)
        CreateOption("Yes", 2)
        CreateOption("No", 3)

        local selected = LF.GetSelectedRule()[fieldName]
        if selected == "Yes" then
            UIDropDownMenu_SetSelectedID(self, 2)
        elseif selected == "No" then
            UIDropDownMenu_SetSelectedID(self, 3)
        else
            UIDropDownMenu_SetSelectedID(self, 1)
        end

        if updateVisibility then
            updateVisibility(selected, self:GetParent())
        end
    end
end

-- Generic UI section creator
local function CreateSelectionFrame(config)
    local frame = CreateFrame("Frame", config.name .. "SelectionFrame", RuleWindow)

    -- Label 1
    frame.label1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.label1:SetPoint("TOPRIGHT", RuleWindow, "TOPRIGHT", unpack(config.offset or {-170, -300}))
    frame.label1:SetText(config.label1)
    frame.label1:SetTextColor(unpack(LF.Colors.Text))
    frame.field1 = config.field1
    frame.field2 = config.field2

    -- Dropdown 1
    frame.dropDown1 = CreateFrame("Frame", config.name .. "Dropdown1", frame, "UIDropDownMenuTemplate")
    frame.dropDown1:SetPoint("LEFT", frame.label1, "RIGHT", -10, 0)
    UIDropDownMenu_SetWidth(frame.dropDown1, 50)

    if config.hasSubOptions then
        -- Label 2
        frame.label2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.label2:SetPoint("LEFT", frame.dropDown1, "RIGHT", -10, 0)
        frame.label2:SetText(config.label2)
        frame.label2:SetTextColor(unpack(LF.Colors.Text))

        -- Dropdown 2
        frame.dropDown2 = CreateFrame("Frame", config.name .. "Dropdown2", frame, "UIDropDownMenuTemplate")
        frame.dropDown2:SetPoint("LEFT", frame.label2, "RIGHT", -10, 0)
        UIDropDownMenu_SetWidth(frame.dropDown2, 50)

        -- Initialize dropdown2 initializer *before* calling Initialize
        frame.initialize2 = CreateDropdownInitializer(frame.field2)
        UIDropDownMenu_Initialize(frame.dropDown2, frame.initialize2)
    end

    -- Initialize dropdown1 initializer *before* calling Initialize
    frame.initialize1 = CreateDropdownInitializer(frame.field1, nil, UpdateSubOptionVisibility)
    UIDropDownMenu_Initialize(frame.dropDown1, frame.initialize1)

    return frame
end

function LF.createRuleWindow()
    RuleWindow = LF.createBaseWindow("RuleWindow", "Edit Rule")
    LF.RuleWindow = RuleWindow
    RuleWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideRuleWindow()
    end)

    RuleWindow.nameInput = createNameEdit()
    RuleWindow.actionSelect = createActionSelect()
    RuleWindow.modeSelect = createModeSelect()
    RuleWindow.itemList = createItemList()
    RuleWindow.goldValue = createMinMaxInput("Value (Gold):", -100, "goldValueMin", "goldValueMax", "GoldValue")
    RuleWindow.itemLevel = createMinMaxInput("Item Level:", -120, "itemLevelMin", "itemLevelMax", "ItemLevel")
    RuleWindow.levelReq = createMinMaxInput("Level Req:", -140, "levelRequirementMin", "levelRequirementMax", "LevelReq")
    RuleWindow.itemCount = createMinMaxInput("Item Count:", -160, "countMin", "countMax", "ItemCount")
    RuleWindow.rarityBoxes = createRarityCheckboxes()

    RuleWindow.equippable = CreateSelectionFrame({
        name = "Equippable",
        label1 = "Gear?",
        label2 = "Weapon?",
        field1 = "equippable",
        field2 = "weapon",
        hasSubOptions = true,
        offset = {-210, -280}
    })
    RuleWindow.recipe = CreateSelectionFrame({
        name = "Recipe",
        label1 = "Recipe?",
        label2 = "Learned?",
        field1 = "recipe",
        field2 = "recipeLearned",
        hasSubOptions = true,
        offset = {-210, -310}
    })
        RuleWindow.mount = CreateSelectionFrame({
        name = "Mount",
        label1 = "Mount?",
        label2 = "Learned?",
        field1 = "mount",
        field2 = "mountLearned",
        hasSubOptions = true,
        offset = {-210, -340}
    })
        RuleWindow.pet = CreateSelectionFrame({
        name = "Pet",
        label1 = "Pet?",
        label2 = "Learned?",
        field1 = "pet",
        field2 = "petLearned",
        hasSubOptions = true,
        offset = {-210, -370}
    })
    RuleWindow:SetFrameStrata("HIGH")
end


function LF.showRuleWindow()
    if not RuleWindow then
        LF.createRuleWindow()
    end

    local rule = LF.GetSelectedRule()
    RuleWindow:ClearAllPoints()
    RuleWindow:SetPoint("CENTER", LF.FilterWindow, "CENTER", 20, -20)
    RuleWindow.nameInput:SetText(rule.name)
    LF.RefreshRuleWindowItemList()

    RuleWindow.actionSelect.selectedAction = rule.action
    UIDropDownMenu_SetText(RuleWindow.actionSelect, rule.action.." |T" .. LF.actions[rule.action].icon ..":16:16:0:0|t")
    UIDropDownMenu_Refresh(RuleWindow.actionSelect)

    RuleWindow.modeSelect.selectedMode = rule.mode
    UIDropDownMenu_SetText(RuleWindow.modeSelect, LF.modes[rule.mode])
    UIDropDownMenu_Refresh(RuleWindow.modeSelect)

    RuleWindow.goldValue.min:SetText(rule.goldValueMin or "")
    RuleWindow.goldValue.max:SetText(rule.goldValueMax or "")
    RuleWindow.itemLevel.min:SetText(rule.itemLevelMin or "")
    RuleWindow.itemLevel.max:SetText(rule.itemLevelMax or "")
    RuleWindow.levelReq.min:SetText(rule.levelRequirementMin or "")
    RuleWindow.levelReq.max:SetText(rule.levelRequirementMax or "")
    RuleWindow.itemCount.min:SetText(rule.countMin or "")
    RuleWindow.itemCount.max:SetText(rule.countMax or "")

    UIDropDownMenu_Initialize(RuleWindow.equippable.dropDown1, RuleWindow.equippable.initialize1)
    UIDropDownMenu_Initialize(RuleWindow.equippable.dropDown2, RuleWindow.equippable.initialize2)

    UIDropDownMenu_Initialize(RuleWindow.recipe.dropDown1, RuleWindow.recipe.initialize1)
    UIDropDownMenu_Initialize(RuleWindow.recipe.dropDown2, RuleWindow.recipe.initialize2)

    for id, checkbox in pairs(RuleWindow.rarityBoxes.rarityCheckboxes) do
        checkbox:SetChecked(rule.rarity and rule.rarity[LF.ItemRarities[id].name] or false)
    end

    handleModeChange(rule.mode)
    RuleWindow:Show()
end


function LF.hideRuleWindow()
    if RuleWindow then RuleWindow:Hide() end
end

local DelayedCalls = {}
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
    for i = #DelayedCalls, 1, -1 do
        local t = DelayedCalls[i]
        t.delay = t.delay - elapsed
        if t.delay <= 0 then
            t.func()
            table.remove(DelayedCalls, i)
        end
    end
end)

LF.refreshScheduled = false

function LF.DelayCall(delay, func)
    table.insert(DelayedCalls, { delay = delay, func = func })
end

local queryTooltip = CreateFrame("GameTooltip", "MyHiddenTooltip", UIParent, "GameTooltipTemplate")
queryTooltip:SetOwner(UIParent, "ANCHOR_NONE")
queryTooltip:Hide()

function LF.QueryItemInfo(itemID)
    local itemName = LF.GetItemInfo(itemID)
    if itemName then
        return true -- Already cached
    else
        queryTooltip:SetHyperlink("item:"..itemID)
        queryTooltip:Show()
        queryTooltip:Hide()
        return false
    end
end

local function OnItemButtonClick(self)
    local rule = self.rule
    local itemID = self.itemID
    local itemName = self.itemName

    if IsShiftKeyDown() or IsControlKeyDown() then
        LF.RemoveItemIDFromRule(rule, itemID)
        LF.RefreshRuleWindowItemList()
    else
        StaticPopup_Show("LOOTFILTER_CONFIRM_REMOVE_ITEM", itemName, nil, itemID)
    end
end



local function ShowItemTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if self.itemLink then
        GameTooltip:SetHyperlink(self.itemLink)
    else
        GameTooltip:SetText(self.itemName or "Unknown Item")
    end
    GameTooltip:Show()
end

local function HideItemTooltip()
    GameTooltip:Hide()
end

function LF.OnDelayedRefreshRuleWindowItemList()
    LF.refreshScheduled = false
    LF.RefreshRuleWindowItemList()
end


function LF.RefreshRuleWindowItemList()

    if not RuleWindow or not LF.GetSelectedRule() then return end

    local rule = LF.GetSelectedRule()
    -- Clear previous entries
    for _, child in ipairs({ RuleWindow.itemList.itemListContent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    collectgarbage("collect")

    local allCached = true

    local i = 0
    for itemID in pairs(rule.itemIDs) do
        i = i + 1
        local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemIcon = LF.GetItemInfo(itemID)
        

        if not itemName then
            -- Trigger server query
            LF.QueryItemInfo(itemID)
            allCached = false
            itemName = "Loading..."
---@diagnostic disable-next-line: cast-local-type
            itemIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
---@diagnostic disable-next-line: cast-local-type
            itemLink = nil
        end
        local itemButton = CreateFrame("Button", nil, RuleWindow.itemList.itemListContent)
        itemButton:SetSize(245, 20)
        itemButton:SetPoint("TOPLEFT", 5, -(i - 1) * 22)
        itemButton.rule = rule
        itemButton.itemID = itemID
        itemButton.itemName = itemName
        itemButton:SetScript("OnClick", OnItemButtonClick)


        local icon = itemButton:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetTexture(itemIcon)
        icon:SetPoint("LEFT")

        -- Set the item button
        local label = itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetText(itemName)
        if itemRarity and ITEM_QUALITY_COLORS[itemRarity] then
            local color = ITEM_QUALITY_COLORS[itemRarity]
            label:SetTextColor(color.r, color.g, color.b)
        else
            label:SetTextColor(1, 1, 1) -- default white if unknown
        end
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)

        -- Highlight on hover
        local highlight = itemButton:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
---@diagnostic disable-next-line: param-type-mismatch
        highlight:SetTexture(1, 1, 1, 0.15)

        itemButton.itemLink = itemLink
        itemButton.itemName = itemName
        itemButton:SetScript("OnEnter", ShowItemTooltip)
        itemButton:SetScript("OnLeave", HideItemTooltip)

    end

    RuleWindow.itemList.itemListContent:SetHeight(i * 22)

    if not allCached then
        if not LF.refreshScheduled then
            LF.refreshScheduled = true
            LF.DelayCall(0.5, LF.OnDelayedRefreshRuleWindowItemList)

        end
    end
end

StaticPopupDialogs["LOOTFILTER_CONFIRM_REMOVE_ITEM"] = {
    text = "Remove %s from the rule?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        local itemID = self.data
        local rule = LF.GetSelectedRule()
        LF.RemoveItemIDFromRule(rule, itemID)
        LF.RefreshRuleWindowItemList()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
