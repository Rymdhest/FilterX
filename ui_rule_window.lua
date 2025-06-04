LF = LF or {}


-- Limit how many times we retry (e.g., 5 times)
local MAX_RETRIES = 5
local RETRY_DELAY = 0.5


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
        elseif retryCount < MAX_RETRIES then
            LF.QueryItemInfo(itemID)
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
    --ssetShowOrHideFram(RuleWindow.itemCount, isItemListMode)
    setShowOrHideFram(RuleWindow.rarityBoxes, isItemListMode)
    setShowOrHideFram(RuleWindow.classSelect, isItemListMode)
    setShowOrHideFram(RuleWindow.learnedSelect, isItemListMode)
    setShowOrHideFram(RuleWindow.soulboundSelect, isItemListMode)
    setShowOrHideFram(RuleWindow.wordList, isItemListMode)
    

end
function LF.CreateDropdown(params)
    local dropdown = CreateFrame("Frame", params.labelText.."Dropdown", RuleWindow, "UIDropDownMenuTemplate")

    local label = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPRIGHT", RuleWindow, "TOPRIGHT", params.labelX or -100, params.labelY or -40)
    label:SetText(params.labelText or "Dropdown:")
    label:SetTextColor(unpack(LF.Colors.Text))

    dropdown:SetPoint("LEFT", label, "RIGHT", -10, 0)
    UIDropDownMenu_SetWidth(dropdown, params.width or 100)

    -- Keep track of selected value and update text accordingly
    dropdown.selectedValue = dropdown.selectedValue or nil

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for key, value in pairs(params.optionsTable) do
            local displayText = params.getText and params.getText(key, value) or value
            local info = UIDropDownMenu_CreateInfo()
            info.text = displayText
            info.icon = params.getIcon and params.getIcon(key, value) or nil
            info.func = function()
                dropdown.selectedValue = key
                UIDropDownMenu_SetText(dropdown, displayText)

                if LF.GetSelectedRule() and params.onSelect then
                    params.onSelect(LF.GetSelectedRule(), key)
                    LF.RefreshFilterWindowRuleList()
                end
            end
            info.checked = (dropdown.selectedValue == key)
            UIDropDownMenu_AddButton(info, level)
        end

        -- Refresh selected display after init
        if dropdown.selectedValue then
            local selectedText = params.getText and params.getText(dropdown.selectedValue, params.optionsTable[dropdown.selectedValue]) or dropdown.selectedValue
            UIDropDownMenu_SetText(dropdown, selectedText)
        end
    end)

    return dropdown
end

local function createModeSelect()
    return LF.CreateDropdown({
        labelText = "Mode:",
        labelX = -320,
        labelY = -40,
        width = 100,
        optionsTable = LF.modes,
        getText = function(key, value) return value end,
        onSelect = function(rule, selectedKey)
            rule.mode = selectedKey
            handleModeChange(selectedKey)
        end
    })
end

local function createSoulboundSelect()
    return LF.CreateDropdown({
        labelText = "Binds:",
        labelX = -210,
        labelY = -330,
        width = 80,
        optionsTable = LF.bindingOptions,
        getText = function(key) return key end,
        onSelect = function(rule, selectedKey)
            rule.soulbound = selectedKey
        end
    })
end

local function createAlertSelect()
    return LF.CreateDropdown({
        labelText = "Alert:",
        labelX = -100,
        labelY = -360,
        width = 70,
        optionsTable = LF.alerts,
        getText = function(key) return key end,
        onSelect = function(rule, selectedKey)
            rule.alert = selectedKey
        end
    })
end

local function createLearnedSelect()
    return LF.CreateDropdown({
        labelText = "Learned:",
        labelX = -210,
        labelY = -360,
        width = 50,
        optionsTable = LF.basicOptions,
        getText = function(key) return key end,
        onSelect = function(rule, selectedKey)
            rule.learned = selectedKey
        end
    })
end

local function createActionSelect()
    return LF.CreateDropdown({
        labelText = "Outcome:",
        labelX = -140,
        labelY = -40,
        width = 100,
        optionsTable = LF.actions,
        getText = function(key, val)
            return  "|T" .. val.icon .. ":14:14:0:0|t "..key
        end,
        onSelect = function(rule, selectedKey)
            rule.action = selectedKey
            if rule.action == "Delete" then rule.isEnabled = false end
        end
    })
end

local function createWordList()
    local wordListFrame = CreateFrame("Frame", "wordListFrame", RuleWindow)
    wordListFrame:SetPoint("TOPLEFT", RuleWindow, "TOPLEFT", 235, -160)
    wordListFrame:SetPoint("BOTTOMRIGHT", RuleWindow, "BOTTOMRIGHT", -145, 170)

    -- Add a scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", "ruleWordScrollFrame", wordListFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()

    wordListFrame.itemListContent = CreateFrame("Frame", "ruleWordListContent", scrollFrame)
    wordListFrame.itemListContent:SetSize(70, 1) -- Width fixed, height will expand
    scrollFrame:SetScrollChild(wordListFrame.itemListContent)

    -- Create a border frame just behind the scrollFrame
    local border = CreateFrame("Frame", nil, wordListFrame)
    border:SetPoint("TOPLEFT", scrollFrame, -1, 1)
    border:SetPoint("BOTTOMRIGHT", scrollFrame, 1, -1)
    border:SetFrameLevel(scrollFrame:GetFrameLevel() - 1) -- place behind
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8", 
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(unpack(LF.Colors.Border))

    -- Input box
    local inputBox = CreateFrame("EditBox", "addWordDbox", wordListFrame, "InputBoxTemplate")
    inputBox:SetSize(80, 20)
    inputBox:SetPoint("TOPLEFT", wordListFrame, "BOTTOMLEFT", 10, -10)
    inputBox:SetAutoFocus(false)
    inputBox:SetFontObject("GameFontHighlightSmall")
    -- Handle pressing Enter
    inputBox:SetScript("OnEnterPressed", function(self)
        local input = self:GetText()
        self:SetText("")
        if input and input:len() > 0 then
            LF.AddWordToRule(LF.GetSelectedRule(), input)
        end
    end)
    -- Add button
    local addButton = CreateFrame("Button", nil, wordListFrame, "UIPanelButtonTemplate")
    addButton:SetSize(45, 20)
    addButton:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
    addButton:SetText("Add")

    -- Add button handler
    addButton:SetScript("OnClick", function()
        local input = inputBox:GetText()
        inputBox:SetText("")
        if input and input:len() > 0 then
            LF.AddWordToRule(LF.GetSelectedRule(), input)
        end
    end)

    return wordListFrame
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
    local Original_ChatEdit_InsertLink = ChatEdit_InsertLink
    -- Override with custom behavior
    function ChatEdit_InsertLink(link)
        if inputBox:HasFocus() then
            inputBox:Insert(link)
            return true
        end
        -- Fallback to original behavior
        return Original_ChatEdit_InsertLink(link)
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
    frame.title:SetPoint("TOPRIGHT", RuleWindow, "TOP", 85, yOffset)
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
    rarityContainer:SetSize(200, #LF.ItemRarities*20)
    rarityContainer:SetPoint("BOTTOMRIGHT", RuleWindow, "BOTTOMRIGHT", -30, 90)

    local rarityCheckboxes = {}
    for id, data in pairs(LF.ItemRarities) do
        -- Create a row frame for label + checkbox
        local row = CreateFrame("Frame", nil, rarityContainer)
        row:SetSize(180, 20)
        row:SetPoint("TOPLEFT", rarityContainer, "TOPLEFT", 0, -20 * (id - 1))

        -- Create label first, aligned left
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        label:SetText(data.name)
        label:SetTextColor(unpack(data.color))

        -- Create checkbox to the right of the label
        local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkbox:SetPoint("LEFT", label, "RIGHT", 8, 0)

        checkbox:SetScript("OnClick", function(self)
            local selectedRule = LF.GetSelectedRule()
            selectedRule.rarity[data.name] = self:GetChecked() or false
            LF.RefreshFilterWindowRuleList()
        end)

        rarityCheckboxes[id] = checkbox
    end

    rarityContainer.rarityCheckboxes = rarityCheckboxes
    return rarityContainer
end

function LF.createRuleWindow()
    RuleWindow = LF.createBaseWindow("RuleWindow", "Edit Rule")
    LF.RuleWindow = RuleWindow
    RuleWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideRuleWindow()
    end)

    RuleWindow.nameInput = createNameEdit()
    RuleWindow.actionSelect = createActionSelect()
    RuleWindow.learnedSelect = createLearnedSelect()
    RuleWindow.alertSelect = createAlertSelect()
    RuleWindow.soulboundSelect = createSoulboundSelect()
    RuleWindow.modeSelect = createModeSelect()
    RuleWindow.wordList = createWordList()
    RuleWindow.itemList = createItemList()
    RuleWindow.goldValue = createMinMaxInput("Value (Gold):", -80, "goldValueMin", "goldValueMax", "GoldValue")
    RuleWindow.itemLevel = createMinMaxInput("Item Level:", -100, "itemLevelMin", "itemLevelMax", "ItemLevel")
    RuleWindow.levelReq = createMinMaxInput("Level Req:", -120, "levelRequirementMin", "levelRequirementMax", "LevelReq")
    --RuleWindow.itemCount = createMinMaxInput("Item Count:", -160, "countMin", "countMax", "ItemCount")
    RuleWindow.rarityBoxes = createRarityCheckboxes()

    RuleWindow.classSelect = LF.createClassSelect()

    RuleWindow:SetFrameStrata("HIGH")
end


function LF.showRuleWindow()
    if not RuleWindow then
        LF.createRuleWindow()
    end
    RuleWindow:Show()

    local rule = LF.GetSelectedRule()
    RuleWindow:ClearAllPoints()
    RuleWindow:SetPoint("CENTER", LF.FilterWindow, "CENTER", 20, -20)
    RuleWindow.nameInput:SetText(rule.name)
    LF.RefreshRuleWindowItemList()
    LF.RefreshRuleWindowWordList()
    for _, rowData in ipairs(RuleWindow.classSelect.rows) do
        if rowData.type == "class" then
            rowData.expanded = false
             rowData.expandButton:SetText("+")
        end
    end
    LF.refreshClassSelect()

    RuleWindow.actionSelect.selectedValue = rule.action
    UIDropDownMenu_SetText(RuleWindow.actionSelect, "|T" .. LF.actions[rule.action].icon ..":14:14:0:0|t "..rule.action)
    UIDropDownMenu_Refresh(RuleWindow.actionSelect)

    RuleWindow.learnedSelect.selectedValue = rule.learned
    UIDropDownMenu_SetText(RuleWindow.learnedSelect, rule.learned)
    UIDropDownMenu_Refresh(RuleWindow.learnedSelect)

    RuleWindow.alertSelect.selectedValue = rule.alert
    UIDropDownMenu_SetText(RuleWindow.alertSelect, rule.alert)
    UIDropDownMenu_Refresh(RuleWindow.alertSelect)

    RuleWindow.soulboundSelect.selectedValue = rule.soulbound
    UIDropDownMenu_SetText(RuleWindow.soulboundSelect, rule.soulbound)
    UIDropDownMenu_Refresh(RuleWindow.soulboundSelect)

    RuleWindow.modeSelect.selectedValue = rule.mode
    UIDropDownMenu_SetText(RuleWindow.modeSelect, LF.modes[rule.mode])
    UIDropDownMenu_Refresh(RuleWindow.modeSelect)

    RuleWindow.goldValue.min:SetText(rule.goldValueMin or "")
    RuleWindow.goldValue.max:SetText(rule.goldValueMax or "")
    RuleWindow.itemLevel.min:SetText(rule.itemLevelMin or "")
    RuleWindow.itemLevel.max:SetText(rule.itemLevelMax or "")
    RuleWindow.levelReq.min:SetText(rule.levelRequirementMin or "")
    RuleWindow.levelReq.max:SetText(rule.levelRequirementMax or "")
    --RuleWindow.itemCount.min:SetText(rule.countMin or "")
    --RuleWindow.itemCount.max:SetText(rule.countMax or "")

    for id, checkbox in pairs(RuleWindow.rarityBoxes.rarityCheckboxes) do
        checkbox:SetChecked(rule.rarity and rule.rarity[LF.ItemRarities[id].name] or false)
    end

    handleModeChange(rule.mode)

    if rule.locked then
        UIDropDownMenu_DisableDropDown(RuleWindow.modeSelect)
        UIDropDownMenu_DisableDropDown(RuleWindow.actionSelect) 
        RuleWindow.nameInput:EnableMouse(false)
        RuleWindow.nameInput:SetAutoFocus(false)
        RuleWindow.nameInput:ClearFocus()
        RuleWindow.nameInput:SetTextColor(0.6, 0.6, 0.6) -- optional: gray out text
    else
        UIDropDownMenu_EnableDropDown(RuleWindow.modeSelect)
        UIDropDownMenu_EnableDropDown(RuleWindow.actionSelect) 
        RuleWindow.nameInput:EnableMouse(true)
        RuleWindow.nameInput:SetTextColor(1.0, 1.0, 1.0) -- optional: gray out text
    end
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

local function OnItemButtonClick(self)
    local rule = self.rule
    local itemID = self.itemID
    local itemName = self.itemName

    if IsShiftKeyDown() or IsControlKeyDown() then
        LF.RemoveItemIDFromRule(rule, itemID)
    else
        StaticPopup_Show("LOOTFILTER_CONFIRM_REMOVE_ITEM", itemName, nil, itemID)
    end
end

local function OnWordButtonClick(self)
    local rule = self.rule
    local word = self.word
    LF.RemoveWordFromRule(rule, word)
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


function LF.RefreshRuleWindowWordList()
    if not RuleWindow or not LF.GetSelectedRule() then return end
    if not RuleWindow:IsShown() then return end
    local rule = LF.GetSelectedRule()
    -- Clear previous entries
    for _, child in ipairs({ RuleWindow.wordList.itemListContent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    collectgarbage("collect")
    local i = 0
    for word in pairs(rule.words) do
        i = i + 1
        local itemButton = CreateFrame("Button", nil, RuleWindow.wordList.itemListContent)
        itemButton:SetSize(110, 15)
        itemButton:SetPoint("TOPLEFT", 5, -(i - 1) * 17)
        itemButton.rule = rule
        itemButton.word = word
        itemButton:SetScript("OnClick", OnWordButtonClick)

        -- Set the item button
        local label = itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetText(word)
        label:SetTextColor(unpack(LF.Colors.Text)) -- default white if unknown
        label:SetPoint("LEFT")
        -- Highlight on hover
        local highlight = itemButton:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
---@diagnostic disable-next-line: param-type-mismatch
        highlight:SetTexture(1, 1, 1, 0.15)
        itemButton.word = word
    end
    RuleWindow.wordList.itemListContent:SetHeight(i * 17)
end

function LF.RefreshRuleWindowItemList()

    if not RuleWindow or not LF.GetSelectedRule() then return end
    if not RuleWindow:IsShown() then return end
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
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function LF.createClassSelect()
    local classSelectFrame = CreateFrame("Frame", "ClassSelectFrame", RuleWindow)
    classSelectFrame:SetPoint("TOPLEFT", RuleWindow, "TOPLEFT", 10, -80)
    classSelectFrame:SetPoint("BOTTOMRIGHT", RuleWindow, "BOTTOMLEFT", 210, 10)

    local scrollFrame = CreateFrame("ScrollFrame", "ScrollFramecc", classSelectFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(200, 1)
    scrollFrame:SetScrollChild(content)

    classSelectFrame.content = content
    classSelectFrame.rows = {} -- unified rows table

    for className, data in pairs(LF.referenceItems) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(200, 20)

        -- Expand/Collapse Button
        local expandButton = CreateFrame("Button", nil, row)
        expandButton:SetSize(20, 20)
        expandButton:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        expandButton:SetNormalFontObject("GameFontNormal")
        expandButton:SetText("—")

        local rowMeta = {
            frame = row,
            type = "class",
            name = className,
            expanded = true,
            children = {},
            expandButton = expandButton,
        }
        row.meta = rowMeta

        -- Toggle expanded state when button clicked
        expandButton:SetScript("OnClick", function()
            rowMeta.expanded = not rowMeta.expanded
            expandButton:SetText(rowMeta.expanded and "—" or "+")
            LF.refreshClassSelect()
        end)

        -- Checkbox for the class row
        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetPoint("LEFT", expandButton, "RIGHT", 2, 0)
        rowMeta.check = check -- store reference

        -- Label for class name
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 2, 0)
        label:SetText(" |T" .. LF.GetItemInfoObject(LF.referenceItems[className].__class).icon ..":15:15:0:0|t "..className)
        label:SetTextColor(1, 1, 1, 1)

        table.insert(classSelectFrame.rows, rowMeta)

        -- Create sub-class rows
        for subClassName, iconID in pairs(data) do
            if subClassName ~= "__class" then
                local subRow = CreateFrame("Frame", nil, content)
                local subCheck = CreateFrame("CheckButton", nil, subRow, "UICheckButtonTemplate")
                subCheck:SetPoint("LEFT", subRow, "LEFT", 30, 0)

                local subLabel = subRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                subLabel:SetPoint("LEFT", subCheck, "RIGHT", 4, 0)
                subLabel:SetText(" |T" .. LF.GetItemInfoObject(LF.referenceItems[className][subClassName]).icon ..":15:15:0:0|t "..subClassName)
                subLabel:SetTextColor(1, 1, 1, 1)

                local subMeta = {
                    frame = subRow,
                    type = "subclass",
                    parent = row.meta,
                    check = subCheck,
                    name = subClassName
                }
                subRow.meta = subMeta

                table.insert(row.meta.children, subMeta)
                table.insert(classSelectFrame.rows, subMeta)

                subCheck:SetScript("OnClick", function()
                    local isChecked = subCheck:GetChecked()
                    local parentMeta = subMeta.parent

                    -- Update saved data for this subclass only
                    local selectedRuleClasses = LF.GetSelectedRule().classes
                    selectedRuleClasses[parentMeta.name] = selectedRuleClasses[parentMeta.name] or {}
                    selectedRuleClasses[parentMeta.name][subMeta.name] = isChecked or nil

                    -- Update parent checkbox based on any checked subclasses
                    local anyChecked = false
                    for _, childMeta in ipairs(parentMeta.children) do
                        if childMeta.check:GetChecked() then
                            anyChecked = true
                            break
                        end
                    end

                    parentMeta.check:SetChecked(anyChecked)
                    if not anyChecked then
                        selectedRuleClasses[parentMeta.name] = nil
                        end

                    LF.refreshClassSelect()
                end)
            end
        end

        check:SetScript("OnClick", function()
            local isChecked = check:GetChecked()

            --rowMeta.expanded = isChecked
            --rowMeta.expandButton:SetText(isChecked and "—" or "+")

            LF.GetSelectedRule().classes[className] = LF.GetSelectedRule().classes[className] or {}
            for subClassName, _ in pairs(LF.referenceItems[className]) do
                if subClassName ~= "__class" then
                    LF.GetSelectedRule().classes[className][subClassName] = isChecked or nil
                end
            end
            -- Set all subclass checkboxes to match
            for _, childMeta in ipairs(rowMeta.children) do
                childMeta.check:SetChecked(isChecked)
            end
            if not isChecked then LF.GetSelectedRule().classes[className] = nil end

            LF.refreshClassSelect()
        end)
    end

    RuleWindow.classSelect = classSelectFrame
    LF.refreshClassSelect()
    return classSelectFrame
end
function LF.refreshClassSelect()
    local selectedRule = LF.GetSelectedRule()

    local ySize = 20
    local yOffset = 0
    local content = RuleWindow.classSelect.content

    for _, rowData in ipairs(RuleWindow.classSelect.rows) do
        local frame = rowData.frame
        frame:ClearAllPoints()

        if rowData.type == "class" then
            frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
            frame:SetSize(200, ySize)
            frame:Show()
            yOffset = yOffset + ySize

            local className = rowData.name
            local hasAnySubclass = false
            if selectedRule.classes[className] then
                for subClassName, value in pairs(selectedRule.classes[className]) do
                    if subClassName ~= "__class" and value then
                        hasAnySubclass = true
                        break
                    end
                end
            end

            if rowData.check then
                rowData.check:SetChecked(hasAnySubclass)
            end

        elseif rowData.type == "subclass" then
            if rowData.parent.expanded then
                frame:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -yOffset)
                frame:SetSize(200, ySize)
                frame:Show()
                yOffset = yOffset + ySize

                local className = rowData.parent.name
                local subClassName = rowData.name
                local isChecked = selectedRule.classes[className] and selectedRule.classes[className][subClassName]


                if rowData.check then
                    rowData.check:SetChecked(isChecked and true or false)
                end
            else
                frame:Hide()
            end
        else
            frame:Hide()
        end
    end

    LF.RefreshFilterWindowRuleList()
    content:SetHeight(yOffset)
end