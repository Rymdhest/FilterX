LF = LF or {}

local MainWindow
local FilterWindow
local RuleWindow


local function UpdateMainUI()

end

local function OnFilterSelected(self)
    local selectedName = self.value 
    if LF.SetSelectedFilterByName(selectedName) then
        UIDropDownMenu_SetSelectedName(MainWindow.dropdown, selectedName)
        LF.hideFilterWindow()
        LF.UpdateMacroText(true)
    end
end

function LF.InitializeDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for i, filter in ipairs(LF.db.filters) do
        info.text = filter.name
        info.func = OnFilterSelected
        info.checked = (filter.name == LF.db.selectedFilterName)
        UIDropDownMenu_AddButton(info, level)
    end
    if LF.GetSelectedFilter() then
        UIDropDownMenu_SetSelectedName(self, LF.GetSelectedFilter().name)
    end
  end



function LF.createMainWindow()
    MainWindow = LF.createBaseWindow("mainWindow", "".. LF.fancyName .. " by " .. "|cffffff00OpenTTD|r")
    LF.MainWindow = MainWindow
    MainWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideMainWindow()
    end)

    -- active filter text
    local activeFilterText = MainWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    activeFilterText:SetPoint("TOPLEFT", MainWindow, "TOPLEFT", 20, -60)
    activeFilterText:SetText("Active filter:")
    activeFilterText:SetTextColor(unpack(LF.Colors.Text))

    -- dropdown
    MainWindow.dropdown = CreateFrame("Frame", "LootFilterDropdown", MainWindow, "UIDropDownMenuTemplate")
    MainWindow.dropdown:SetPoint("LEFT", activeFilterText, "RIGHT", -10, 0)
    UIDropDownMenu_SetSelectedID(MainWindow.dropdown, 1)
    UIDropDownMenu_SetWidth(MainWindow.dropdown, 110)
    UIDropDownMenu_SetText(MainWindow.dropdown, "")

    -- new filter button
    local newFilterButton = CreateFrame("Button", "LF_newFilterButton", MainWindow, "UIPanelButtonTemplate")
    newFilterButton:SetSize(100, 22)
    newFilterButton:SetText("New Filter")
    newFilterButton:SetPoint("TOPLEFT", MainWindow, "TOPLEFT", 10, -80)
    newFilterButton:SetScript("OnClick", function()
        local newFilter = LF.CreateNewFilter()
        LF.SetSelectedFilterByName(newFilter.name)
        LF.showFilterWindow()
    end)





                -- copy filter button
    local copyFilterButton = CreateFrame("Button", "LF_copyFilterButton", MainWindow, "UIPanelButtonTemplate")
    copyFilterButton:SetSize(100, 22)
    copyFilterButton:SetText("Copy Filter")
    copyFilterButton:SetPoint("LEFT", newFilterButton, "RIGHT", 10, 0)
    copyFilterButton:SetScript("OnClick", function()
            LF.CopyFilter(LF.GetSelectedFilter())
    end)

            -- import filter button
    local importFilterButton = CreateFrame("Button", "LF_importFilterButton", MainWindow, "UIPanelButtonTemplate")
    importFilterButton:SetSize(100, 22)
    importFilterButton:SetText("Import Filter")
    importFilterButton:SetPoint("LEFT", copyFilterButton, "RIGHT", 10, 0)
    importFilterButton:SetScript("OnClick", function()
        LF.showImporttWindow(true, "Paste here...")
    end)

        -- export filter button
    local exportFilterButton = CreateFrame("Button", "LF_exportFilterButton", MainWindow, "UIPanelButtonTemplate")
    exportFilterButton:SetSize(100, 22)
    exportFilterButton:SetText("Export Filter")
    exportFilterButton:SetPoint("LEFT", importFilterButton, "RIGHT", 10, 0)
    exportFilterButton:SetScript("OnClick", function()

        local LibDeflate = LibStub("LibDeflate")
        local serializer = LibStub("LibSerialize")
        if not LF.GetSelectedFilter() then return end
        local data = LF.GetSelectedFilter()
        local serialized = serializer:Serialize(data)
        local compressed = LibDeflate:CompressDeflate(serialized)
        local encoded = LibDeflate:EncodeForPrint(compressed)
        LF.showImporttWindow(false, encoded)

    end)

        -- edit filter button
    local editFilterButton = CreateFrame("Button", "LF_EditFilterButton", MainWindow, "UIPanelButtonTemplate")
    editFilterButton:SetSize(100, 22)
    editFilterButton:SetText("Edit Filter")
    editFilterButton:SetPoint("BOTTOM", importFilterButton, "TOP", 0, 5)
    editFilterButton:SetScript("OnClick", function()
            LF.showFilterWindow()
    end)



            -- delete filter button
    local deleteFilterButton = CreateFrame("Button", "LF_deleteFilterButton", MainWindow, "UIPanelButtonTemplate")
    deleteFilterButton:SetSize(100, 22)
    deleteFilterButton:SetText("Delete Filter")
    deleteFilterButton:SetPoint("LEFT", editFilterButton, "RIGHT", 10, 0)
    deleteFilterButton:SetScript("OnClick", function()
        if not LF.GetSelectedFilter() then return end
        StaticPopupDialogs["DELETE_RULE_CONFIRM"] = {
            text = "Are you sure you want to delete the "..LF.GetSelectedFilter().name.." filter?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                if (LF.DeleteFilterByName(LF.GetSelectedFilter().name)) then
                    UIDropDownMenu_Initialize(MainWindow.dropdown, LF.InitializeDropdown)
                    UIDropDownMenu_SetText(MainWindow.dropdown, "")
                    LF.hideFilterWindow()
                else
                    print("Failed to delete filter.")
                end
            end,
            timeout = 0,
            whileDead = true,   
            hideOnEscape = true,
            preferredIndex = 3
        }
        StaticPopup_Show("DELETE_RULE_CONFIRM")

    end)

    function CreateCheckbox(parent, x, y, labelText, dbTable, dbKey)
        local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        checkbox:SetSize(26, 26)
        checkbox:SetChecked(dbTable[dbKey])

        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
        label:SetText(labelText)
        label:SetTextColor(unpack(LF.Colors.Text)) -- Example text color

        checkbox:SetScript("OnClick", function(self)
            dbTable[dbKey] = self:GetChecked() and true or false
        end)

        return checkbox
    end


    
    local settings = CreateFrame("Frame", "Global Settings", MainWindow)
    settings:SetPoint("BOTTOM", MainWindow, "BOTTOM", 0, 20)
    settings:SetSize(450, 200)

    local settingsLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    settingsLabel:SetPoint("BOTTOM", settings, "TOP", 0, -5)
    settingsLabel:SetText("Global Settings")
    settingsLabel:SetTextColor(unpack(LF.Colors.Text))

    local autoLootCheckbox = CreateCheckbox(settings, 10, -10, "Auto sell at vendor", LF.db.globals, "autoVendor")
    autoLootCheckbox:SetScript("OnClick", function(self)
        LF.db.globals["autoVendor"] = self:GetChecked() and true or false
        if self:GetChecked() then LF.merchantButton:Hide() else LF.merchantButton:Show() end
    end)
    local alwaysShowDisenchantCheckbox = CreateCheckbox(settings, 10, -30, "Always show disenchant window", LF.db.globals, "alwaysShowDisenchant")
        alwaysShowDisenchantCheckbox:SetScript("OnClick", function(self)
        LF.db.globals["alwaysShowDisenchant"] = self:GetChecked() and true or false
        if self:GetChecked() then LF.disenchantWindow:Show() else LF.refreshDisenchantWindow() end
    end)

    CreateCheckbox(settings, 300, -10, "Alert loot", LF.db.globals, "alertLoot")
    CreateCheckbox(settings, 300, -30, "Alert recieve", LF.db.globals, "alertContainers")
    CreateCheckbox(settings, 300, -50, "Alert created", LF.db.globals, "alertCrafting")
    CreateCheckbox(settings, 300, -70, "Alert gold", LF.db.globals, "alertGoldVendoring")


    local border = CreateFrame("Frame", nil, settings)
    border:SetPoint("TOPLEFT", settings, -1, 1)
    border:SetPoint("BOTTOMRIGHT", settings, 1, -1)
    border:SetFrameLevel(settings:GetFrameLevel() - 1) -- place behind
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8", 
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(unpack(LF.Colors.Border))



    MainWindow:SetFrameLevel(10)
end



function LF.showMainWindow()
    if not MainWindow then
        LF.createMainWindow()
    end
    UIDropDownMenu_Initialize(MainWindow.dropdown, LF.InitializeDropdown)
    MainWindow:ClearAllPoints()
    MainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    MainWindow:Show()
end

function LF.hideMainWindow()
    if MainWindow then MainWindow:Hide() end
    LF.hideFilterWindow()
end



