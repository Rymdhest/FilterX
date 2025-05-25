LF = LF or {}


-- Limit how many times we retry (e.g., 5 times)
local MAX_RETRIES = 5
local RETRY_DELAY = 0.5
-- Hidden tooltip for triggering server queries
local queryTooltip = CreateFrame("GameTooltip", "LFHiddenTooltip", UIParent, "GameTooltipTemplate")
queryTooltip:SetOwner(UIParent, "ANCHOR_NONE")
queryTooltip:Hide()

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


function LF.createRuleWindow()
    RuleWindow = LF.createBaseWindow("RuleWindow", "Edit Rule")
    LF.RuleWindow = RuleWindow
    RuleWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideRuleWindow()
    end)

    local nameText = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", RuleWindow, "TOPLEFT", 20, -30)
    nameText:SetText("Name:")
    nameText:SetTextColor(unpack(LF.Colors.Text))

    RuleWindow.nameInputBox = CreateFrame("EditBox", "MyEditableTextField2", RuleWindow, "InputBoxTemplate")
    RuleWindow.nameInputBox:SetSize(150, 30)
    RuleWindow.nameInputBox:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    RuleWindow.nameInputBox:SetAutoFocus(false) -- prevent it from stealing focus immediately
    RuleWindow.nameInputBox:SetMaxLetters(30)
    RuleWindow.nameInputBox:SetFontObject("GameFontHighlightSmall")
    RuleWindow.nameInputBox:SetScript("OnEnterPressed", function(self)
        if LF.RenameRuleInCurrentFilter(LF.GetSelectedRule(), self:GetText()) then
            LF.RefreshFilterWindowRuleList()
        else 
            RuleWindow.nameInputBox:SetText(LF.GetSelectedRule().name)
        end
        self:ClearFocus() -- unfocus after pressing Enter
    end)
    RuleWindow.nameInputBox:SetScript("OnEscapePressed", function(self)
        RuleWindow.nameInputBox:SetText(LF.GetSelectedFilter().name)
        self:ClearFocus()
    end)


    -- Action
    RuleWindow.actionDropdown = CreateFrame("Frame", "LFActionDropdown", RuleWindow, "UIDropDownMenuTemplate")
    RuleWindow.actionDropdown:SetPoint("TOPLEFT", RuleWindow, "TOPRIGHT", -170, -30)
        UIDropDownMenu_Initialize(RuleWindow.actionDropdown, function(self, level)
        for actionName, iconPath in pairs(LF.actions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = actionName
            info.func = function()
                -- When clicked, save selection and update dropdown text
                RuleWindow.actionDropdown.selectedAction = actionName
                UIDropDownMenu_SetText(RuleWindow.actionDropdown, actionName.." |T" .. LF.actions[actionName] ..":16:16:0:0|t")
                
                -- Here update the rule's action to this selection
                if LF.GetSelectedRule() then
                    LF.GetSelectedRule().action = actionName
                    LF.RefreshFilterWindowRuleList()
                end
            end
            info.checked = (RuleWindow.actionDropdown.selectedAction == actionName)
            info.icon = iconPath
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local itemListFrame = CreateFrame("Frame", "itemListFrame", RuleWindow)
    itemListFrame:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -20)
    itemListFrame:SetPoint("BOTTOMRIGHT", RuleWindow, "BOTTOMRIGHT", -200, 60)

    -- Add a scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", "ruleItemScrollFrame", itemListFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()

    RuleWindow.itemListContent = CreateFrame("Frame", "ruleItemListContent", scrollFrame)
    RuleWindow.itemListContent:SetSize(200, 1) -- Width fixed, height will expand
    scrollFrame:SetScrollChild(RuleWindow.itemListContent)

    -- Create a border frame just behind the scrollFrame
    local border = CreateFrame("Frame", nil, RuleWindow)
    border:SetPoint("TOPLEFT", scrollFrame, -1, 1)
    border:SetPoint("BOTTOMRIGHT", scrollFrame, 1, -1)
    border:SetFrameLevel(scrollFrame:GetFrameLevel() - 1) -- place behind

    -- Input box
    local inputBox = CreateFrame("EditBox", "addItemIDbox", RuleWindow, "InputBoxTemplate")
    inputBox:SetSize(180, 24)
    inputBox:SetPoint("BOTTOMLEFT", RuleWindow, "BOTTOMLEFT", 20, 20)
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
    local addButton = CreateFrame("Button", nil, RuleWindow, "UIPanelButtonTemplate")
    addButton:SetSize(60, 24)
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
    -- Label for item level title Level
    local ilvlTitle = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlTitle:SetPoint("TOP", 120, -80)
    ilvlTitle:SetText("item level:")

    -- Label for Min Item Level
    local minLabel = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minLabel:SetPoint("TOPLEFT", ilvlTitle, "BOTTOMLEFT", 0, -10)
    minLabel:SetText("Min")

    -- EditBox for Min Item Level
    local minInput = CreateFrame("EditBox", "minilvlinput", RuleWindow, "InputBoxTemplate")
    minInput:SetSize(30, 20)
    minInput:SetPoint("LEFT", minLabel, "RIGHT", 10, 0)
    minInput:SetAutoFocus(false)
    minInput:SetNumeric(true)  -- Allows only numbers
    minInput:SetMaxLetters(3)
    minInput:SetText("")

    -- Label for Max Item Level
    local maxLabel = RuleWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maxLabel:SetPoint("LEFT", minInput, "RIGHT", 10, 0)
    maxLabel:SetText("Max")

    -- EditBox for Max Item Level
    local maxInput = CreateFrame("EditBox", "maxilvlinput", RuleWindow, "InputBoxTemplate")
    maxInput:SetSize(30, 20)
    maxInput:SetPoint("LEFT", maxLabel, "RIGHT", 10, 0)
    maxInput:SetAutoFocus(false)
    maxInput:SetNumeric(true)
    maxInput:SetMaxLetters(3)
    maxInput:SetText("")

    -- Add a solid border using backdrop
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8", -- solid texture
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(unpack(LF.Colors.Border)) -- white border (r, g, b, alpha)

    RuleWindow:SetFrameStrata("HIGH")
end

function LF.showRuleWindow()
    if not RuleWindow then
        LF.createRuleWindow()
    end
    RuleWindow:ClearAllPoints()
    RuleWindow:SetPoint("CENTER", LF.FilterWindow, "CENTER", 20, -20)
    RuleWindow.nameInputBox:SetText(LF.GetSelectedRule().name)
    LF.RefreshRuleWindowItemList()

    RuleWindow.actionDropdown.selectedAction = LF.GetSelectedRule().action
    UIDropDownMenu_SetText(RuleWindow.actionDropdown, LF.GetSelectedRule().action.." |T" .. LF.actions[LF.GetSelectedRule().action] ..":16:16:0:0|t")
    UIDropDownMenu_Refresh(RuleWindow.actionDropdown)
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
    for _, child in ipairs({ RuleWindow.itemListContent:GetChildren() }) do
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
        local itemButton = CreateFrame("Button", nil, RuleWindow.itemListContent)
        itemButton:SetSize(230, 20)
        itemButton:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
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

    --RuleWindow.itemListContent:SetHeight(#rule.itemIDs * 22)
    RuleWindow.itemListContent:SetHeight(i * 22)

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
