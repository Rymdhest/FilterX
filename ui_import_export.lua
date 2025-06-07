LF = LF or {}

local importWindow

local function import()
        local LibDeflate = LibStub("LibDeflate")
        local serializer = LibStub("LibSerialize")
        local encoded = importWindow.editBox:GetText()
        local decoded = LibDeflate:DecodeForPrint(encoded)
        if not decoded then return nil, "Decoding failed" end

        local decompressed = LibDeflate:DecompressDeflate(decoded)
        if not decompressed then return nil, "Decompression failed" end

        local success, data = serializer:Deserialize(decompressed)
        if not success then return nil, "Deserialization failed" end

        data.name = LF.createBestAvailableFilterName(data.name)

        table.insert(LF.db.filters, data)
        LF.SetSelectedFilterByName(data.name)
        LF.hideExportWindow()
end

function LF.createImportWindow()
    importWindow = LF.createBaseWindow("importExportFrame", "Share Filter")
    LF.importWindow = importWindow
    importWindow.closeButton:SetScript("OnClick", function(self)
        LF.hideExportWindow()
    end)

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "MyScrollFrame", importWindow, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetSize(450, 330)

    -- EditBox
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetWidth(420)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetText("")

    -- Required to allow scrolling and selection
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:HighlightText(0, 0) 
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        import()
    end)
    -- Set min height to avoid disappearing content
    editBox:SetHeight(1000)  -- big enough to always hold long strings

    scrollFrame:SetScrollChild(editBox)

    importWindow.editBox = editBox
    importWindow.scrollFrame = scrollFrame;

        -- import button
    local importButton = CreateFrame("Button", "LF_newFilterButton", importWindow, "UIPanelButtonTemplate")
    importButton:SetSize(100, 22)
    importButton:SetText("Import")
    importButton:SetPoint("BOTTOM", importWindow, "BOTTOM", 0, 10)
    importButton:SetScript("OnClick", function()
        import()
    end)
    importWindow.importButton = importButton
    importWindow:SetFrameLevel(40)
end

function LF.showImporttWindow(import, text)
    if not importWindow then
        LF.createImportWindow()
    end
    importWindow:ClearAllPoints()
    importWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    importWindow.editBox:SetText(text)

    C_Timer.After(0.1, function()
        importWindow.scrollFrame:SetVerticalScroll(1) -- Scroll to top
    end)
    importWindow:Show()
    importWindow.editBox:HighlightText()
    importWindow.editBox:SetFocus()

    if import then importWindow.importButton:Show()
    else importWindow.importButton:Hide() end

end

function LF.hideExportWindow()
    if importWindow then importWindow:Hide() end
end



