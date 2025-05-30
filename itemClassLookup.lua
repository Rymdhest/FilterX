LF = LF or {}
local MAX_RETRIES = 10
local RETRY_DELAY = 1.0

local function BuildMappingForItem(itemID, retryCount)
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
        class = meta.class,
        subclass = meta.subclass
    }
end

local function buildReferenceTable()
    for class, subclasses in pairs(LF.referenceItems) do
        for subclass, itemID in pairs(subclasses) do
            if subclass ~= "__class" then
                BuildMappingForItem(itemID)
            end
        end
    end
end 

local function forceQuery(ID, retryCount)
    retryCount = retryCount or 0

    local _, _, _, _, _, localizedClass, localizedSubClass = LF.GetItemInfo(ID)
    if not localizedClass or not localizedSubClass then
        if retryCount < MAX_RETRIES then
            LF.QueryItemInfo(ID)
            C_Timer.After(RETRY_DELAY, function()
                forceQuery(ID, retryCount + 1)
            end)
        else
            print("Failed to retrieve item info for itemID:", ID, "after", MAX_RETRIES, "retries.")
        end
        return
    end
end

function LF.InitializeItemClassLookup()
    buildReferenceTable()

    for class, subclasses in pairs(LF.referenceItems) do
        for subclass, itemID in pairs(subclasses) do
            if subclass == "__class" then
                forceQuery(itemID)
            end
        end
    end
end
