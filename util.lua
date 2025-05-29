LF = LF or {}

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

function LF.NormalizeColor(color)
    return {color[1] / 255, color[2] / 255, color[3] / 255, color[4] / 255}
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
    frame:Hide()
    return frame
end

function LF.GetItemInfo(...)
---@diagnostic disable-next-line: deprecated
    return GetItemInfo(...)
end

function LF.GetItemInfoObject(itemID)
    local itemName, itemLink, quality, itemLevel, requiredLevel, itemClass, itemSubClass, maxStack, equipSlot, icon, sellPrice = LF.GetItemInfo(itemID)
    if not itemLink or not itemID or not itemName then
        print("Invalid item data provided.")
        return nil
    end
    return {
        id = itemID,
        name = itemName,
        link = itemLink,
        quality = quality,
        level = itemLevel,
        requiredLevel = requiredLevel,
        class = itemClass,
        subClass = itemSubClass,
        maxStack = maxStack,
        equipSlot = equipSlot,
        icon = icon,
        sellPrice = sellPrice
    }
end