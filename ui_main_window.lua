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
    MainWindow = LF.createBaseWindow("mainWindow", LF.addonName .. " by " .. "|cffffff00OpenTTD|r")
    LF.MainWindow = MainWindow
    MainWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideMainWindow()
    end)

    -- active filter text
    local activeFilterText = MainWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    activeFilterText:SetPoint("TOPLEFT", MainWindow, "TOPLEFT", 20, -100)
    activeFilterText:SetText("Active filter:")
    activeFilterText:SetTextColor(unpack(LF.Colors.Text))

    -- dropdown
    MainWindow.dropdown = CreateFrame("Frame", "LootFilterDropdown", MainWindow, "UIDropDownMenuTemplate")
    MainWindow.dropdown:SetPoint("LEFT", activeFilterText, "RIGHT", -10, 0)
    UIDropDownMenu_SetSelectedID(MainWindow.dropdown, 1)
    UIDropDownMenu_SetWidth(MainWindow.dropdown, 100)
    UIDropDownMenu_SetText(MainWindow.dropdown, "")

    -- new filter button
    local newFilterButton = CreateFrame("Button", "LF_newFilterButton", MainWindow, "UIPanelButtonTemplate")
    newFilterButton:SetSize(100, 22)
    newFilterButton:SetText("New Filter")
    newFilterButton:SetPoint("TOPLEFT", MainWindow, "TOPLEFT", 10, -50)
    newFilterButton:SetScript("OnClick", function()
        local newFilter = LF.CreateNewFilter()
        LF.SetSelectedFilterByName(newFilter.name)
        UIDropDownMenu_Initialize(MainWindow.dropdown, LF.InitializeDropdown)
        UIDropDownMenu_SetSelectedName(MainWindow.dropdown, newFilter.name)
        LF.showFilterWindow()
    end)

    -- import filter button
    local importFilterButton = CreateFrame("Button", "LF_importFilterButton", MainWindow, "UIPanelButtonTemplate")
    importFilterButton:SetSize(100, 22)
    importFilterButton:SetText("Import Filter")
    importFilterButton:SetPoint("LEFT", newFilterButton, "RIGHT", 0, 0)
    importFilterButton:SetScript("OnClick", function()
        LF.showImporttWindow(true, "Paste here...")
    end)

    -- edit filter button
    local editFilterButton = CreateFrame("Button", "LF_EditFilterButton", MainWindow, "UIPanelButtonTemplate")
    editFilterButton:SetSize(100, 22)
    editFilterButton:SetText("Edit Filter")
    editFilterButton:SetPoint("LEFT", MainWindow.dropdown, "RIGHT", -10, 0)
    editFilterButton:SetScript("OnClick", function()
            LF.showFilterWindow()
    end)

        -- export filter button
    local exportFilterButton = CreateFrame("Button", "LF_exportFilterButton", MainWindow, "UIPanelButtonTemplate")
    exportFilterButton:SetSize(100, 22)
    exportFilterButton:SetText("Export Filter")
    exportFilterButton:SetPoint("LEFT", editFilterButton, "RIGHT", 0, 0)
    exportFilterButton:SetScript("OnClick", function()

        local LibDeflate = LibStub("LibDeflate")
        local serializer = LibStub("LibSerialize")
        local data = LF.GetSelectedFilter()
        local serialized = serializer:Serialize(data)
        local compressed = LibDeflate:CompressDeflate(serialized)
        local encoded = LibDeflate:EncodeForPrint(compressed)
        LF.showImporttWindow(false, encoded)

    end)

            -- delete filter button
    local deleteFilterButton = CreateFrame("Button", "LF_deleteFilterButton", MainWindow, "UIPanelButtonTemplate")
    deleteFilterButton:SetSize(100, 22)
    deleteFilterButton:SetText("Delete Filter")
    deleteFilterButton:SetPoint("TOPLEFT", activeFilterText, "BOTTOMLEFT", 0, -20)
    deleteFilterButton:SetScript("OnClick", function()
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

                -- copy filter button
    local copyFilterButton = CreateFrame("Button", "LF_copyFilterButton", MainWindow, "UIPanelButtonTemplate")
    copyFilterButton:SetSize(100, 22)
    copyFilterButton:SetText("Copy Filter")
    copyFilterButton:SetPoint("LEFT", deleteFilterButton, "RIGHT", 0, 0)
    copyFilterButton:SetScript("OnClick", function()
            LF.CopyFilter(LF.GetSelectedFilter())
    end)

    MainWindow:SetFrameStrata("LOW")
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



