local addonName = ...
LF = LF or {}
LF.addonName = addonName


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LootFilterDB = LootFilterDB or {}
        LF.db = LootFilterDB
        LF.db.filters = LF.db.filters or {}

        LF.showMainWindow()
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)