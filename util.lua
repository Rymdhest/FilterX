LF = LF or {}

function LF.RGBToHex(r, g, b)
    if r <= 1 and g <= 1 and b <= 1 then
        r, g, b = r * 255, g * 255, b * 255
    end
    return string.format("%02X%02X%02X", r, g, b)
end

function LF.isNameAllowed(name)
    if name == nil or name == "" or  string.lower(name) == "nil" then
        return false
    end
    return true
end

function LF.delay(seconds, func)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= seconds then
            self:SetScript("OnUpdate", nil)  -- stop updating
            self:Hide()                     -- hide frame (optional cleanup)
            func()
        end
    end)
end



function LF.createBaseWindow(name, title)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        tileSize = 0, -- ignored since tile = false
        edgeSize = 3,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(unpack(LF.Colors.Background)) 
    frame:SetBackdropBorderColor(unpack(LF.Colors.Border)) 
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        -- Title
    local titleFrame = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleFrame:SetPoint("TOP", frame, "TOP", 0, -10)
    titleFrame:SetText(title)
    titleFrame:SetTextColor(unpack(LF.Colors.Text))

    -- Close button
    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame:SetFrameStrata("MEDIUM"   )
    frame:Hide()
    return frame
end

function LF.GetItemInfo(...)
---@diagnostic disable-next-line: deprecated
    return GetItemInfo(...)
end

function LF.GetItemInfoObject(itemID)
    local itemName, itemLink, quality, itemLevel, requiredLevel, itemClassLocalized, itemSubClassLocalized,
          maxStack, equipSlot, icon, sellPrice = LF.GetItemInfo(itemID)
    
    if not itemLink or not itemID or not itemName then
        return nil
    end

    -- Translate localized class/subclass to internal identifiers
    local internalClass, internalSubClass = nil, nil
    if LF.localizedToInternal[itemClassLocalized] then
        local mapped = LF.localizedToInternal[itemClassLocalized][itemSubClassLocalized]
        if mapped then
            internalClass = mapped.class
            internalSubClass = mapped.subclass
        else 
            return nil
        end
    end

    return {
        id = itemID,
        name = itemName,
        link = itemLink,
        quality = quality,
        level = itemLevel,
        requiredLevel = requiredLevel,
        class = internalClass,       -- internal name here
        subClass = internalSubClass, -- internal name here
        maxStack = maxStack,
        equipSlot = equipSlot,
        icon = icon,
        sellPrice = sellPrice
    }
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

local function BuildMappingForItem(itemID, retryCount)
    retryCount = retryCount or 0
    local meta = LF.referenceLookup[itemID]
    if not meta then return end
    local _, _, _, _, _, localizedClass, localizedSubClass = LF.GetItemInfo(itemID)
    if not localizedClass or not localizedSubClass then
        print("FAILED. TRIED TO BUILD MAPPING TEMPLE WHEN QUERIES ARE NOT DONE")
    end

    LF.localizedToInternal[localizedClass] = LF.localizedToInternal[localizedClass] or {}
    LF.localizedToInternal[localizedClass][localizedSubClass] = {
        class = meta.class,
        subclass = meta.subclass
    }
end

function LF.buildReferenceTable()
    LF.localizedToInternal = LF.localizedToInternal or {}
    for class, subclasses in pairs(LF.referenceItems) do
        for subclass, itemID in pairs(subclasses) do
            if subclass ~= "__class" then
                BuildMappingForItem(itemID)
            end
        end
    end
end




function LF.delayQuery(delay, id)
    table.insert(LF.queryRetries, { delay = delay, id = id })
    LF.waitingForQuery = true
end

 function LF.QueryItemprefetch(itemID)
    local itemName = LF.GetItemInfo(itemID)
    if itemName then
        return true -- Already cached
    else
         LF.delayQuery(1.0, itemID)
        return false
    end
end

function LF.QueryReferences()
    print("start to query :)")
    local queryRate = 60                          -- Max queries per second
    LF.queryInterval = 1 / queryRate          -- Seconds between queries
    LF.queryTimer = 0   
    LF.queryRetries =  LF.queryRetries or {}



    for class, subclasses in pairs(LF.referenceItems) do
        for subclass, itemID in pairs(subclasses) do
            LF.QueryItemprefetch(itemID)
        end
    end

    if #LF.queryRetries == 0 then 
        print("Nothing to query in references:)")
        LF.init()
    else
        LF.chacheWaitingFrame:Show()
    end
end

function LF.QueryAllRulesInFilter()
    if not LF.GetSelectedFilter() then return end
    print("start to query items:)")
    local queryRate = 60                          -- Max queries per second
    LF.queryInterval = 1 / queryRate          -- Seconds between queries
    LF.queryTimer = 0   
    LF.queryRetries =  LF.queryRetries or {}

    for _, rule in ipairs(LF.GetSelectedFilter().rules) do
        for itemID in pairs(rule.itemIDs) do
            LF.QueryItemprefetch(itemID)
        end
    end

    if #LF.queryRetries == 0 then 
        print("Nothing to query in items")
    end
end

 function LF.QueryItemForce(itemID)
    local itemName = LF.GetItemInfo(itemID)
    if itemName then
        return true -- Already cached
    else
        queryTooltip:SetHyperlink("item:"..itemID)
        queryTooltip:Show()
        queryTooltip:Hide()
         LF.delayQuery(1.0, itemID)
         LF.waitingForQuery = true
        return false
    end
end

local function doneQuery()
    LF.waitingForQuery = false
    print("DONE QUERYING")
    if not LF.doneInit then
        LF.init()
        LF.chacheWaitingFrame:Hide()
        LF.chacheWaitingFrame = nil
    end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
    if #LF.queryRetries == 0 then return end
    print(#LF.queryRetries.." queries left")
    LF.queryTimer = LF.queryTimer + elapsed

    -- Number of queries we are allowed to do this frame
    local allowedQueries = math.floor(LF.queryTimer / LF.queryInterval)

    if allowedQueries == 0 then
        return -- Not enough time passed for another query
    end

    for i = #LF.queryRetries, 1, -1 do
        local t = LF.queryRetries[i]
        t.delay = t.delay - elapsed

        if t.delay <= 0 and allowedQueries > 0 then
            table.remove(LF.queryRetries, i)
            if LF.QueryItemForce(t.id) and #LF.queryRetries == 0 then
                doneQuery()
            end
            LF.queryTimer = LF.queryTimer - LF.queryInterval
            allowedQueries = allowedQueries - 1
        end

        if allowedQueries == 0 then
            break -- We’ve sent the max number of queries for this frame
        end
    end
end)

-- Create the frame
local chacheWaitingFrame = CreateFrame("Frame", "chacheWaitingFrame", UIParent)
chacheWaitingFrame:SetSize(210, 70) -- width, height
chacheWaitingFrame:SetPoint("CENTER") -- position on the screen
    chacheWaitingFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        tileSize = 0, -- ignored since tile = false
        edgeSize = 3,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
chacheWaitingFrame:Hide()
chacheWaitingFrame:SetBackdropColor(unpack(LF.Colors.Background)) 
chacheWaitingFrame:SetBackdropBorderColor(unpack(LF.Colors.Border)) 

-- Add text to the frame
local text = chacheWaitingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", chacheWaitingFrame, "CENTER", 0, 0)
text:SetText("Waiting for cache.\nDid you just delete it?\nShould take less than 1 minute.")
chacheWaitingFrame:SetFrameStrata("HIGH")

LF.chacheWaitingFrame = chacheWaitingFrame