LF = LF or {}
local MAX_RETRIES = 10
local RETRY_DELAY = 1.0

local function BuildMappingForItem(itemID, retryCount)
    if itemID == 0 then return end -- Skip invalid itemID for debug
    retryCount = retryCount or 0
    LF.localizedToInternal = LF.localizedToInternal or {}
    local meta = LF.referenceLookup[itemID]
    if not meta then return end
    local _, _, _, _, _, localizedClass, localizedSubClass = LF.GetItemInfo(itemID)
    if not localizedClass or not localizedSubClass then
        if retryCount < MAX_RETRIES then
            LF.QueryItemInfo(itemID)
            C_Timer.After(RETRY_DELAY, function()
                BuildMappingForItem(itemID, retryCount + 1)
            end)
        else
            print("Failed to retrieve item info for itemID:", itemID, "after", MAX_RETRIES, "retries.")
        end
        return
    end

    -- Item is ready, store mapping
    LF.localizedToInternal[localizedClass] = LF.localizedToInternal[localizedClass] or {}
    LF.localizedToInternal[localizedClass][localizedSubClass] = {
        class = meta.class.." TEST",
        subclass = meta.subclass.." TEST"
    }
end

local function buildReferenceTable()
    for class, subclasses in pairs(LF.referenceItems) do
        for subclass, itemID in pairs(subclasses) do
            BuildMappingForItem(itemID)
        end
    end
end

function LF.InitializeItemClassLookup()
    buildReferenceTable()
end
