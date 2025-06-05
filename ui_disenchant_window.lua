LF = LF or {}

local disenchantWindow


function LF.UpdateMacroText(first)
        local bag1, slot1, bag2, slot2, count = LF.FindNextDisenchantableItem()
        local bag = bag1
        local slot = slot1
        if not first then
            bag = bag2
            slot = slot2
        end
        if bag and slot then 
            local link = GetContainerItemLink(bag, slot)
            local macroText = string.format("/cast Disenchant\n/use %d %d", bag, slot)
            disenchantWindow.button:SetAttribute("macrotext", macroText)
            LF.disenchantWindow.count = count
            LF.updateNextDisenchantitem(link)
        else
            disenchantWindow.button:SetAttribute("macrotext", "/run print('No more items to disenchant')")
            LF.updateNextDisenchantitem(nil)
        end
    end

function LF.updateNextDisenchantitem(item)

    if disenchantWindow.count == 0 or not item then
        disenchantWindow.nextItemLabel:Hide()
        disenchantWindow.nextItemIcon:Hide()
        disenchantWindow.countLabel:SetText("No Items Left")
    else
        disenchantWindow.nextItemLabel:Show()
        disenchantWindow.nextItemIcon:Show()
        disenchantWindow.nextItemLabel:SetText(item)
        disenchantWindow.nextItemIcon:SetTexture(select(10, GetItemInfo(item)))
        disenchantWindow.countLabel:SetText(LF.disenchantWindow.count.. " Items left")
    end
end

function LF.createDisenchantWindow()
    disenchantWindow = CreateFrame("Frame", "DisenchantFrame", UIParent)
    LF.disenchantWindow = disenchantWindow
    LF.disenchantWindow.count = 0
    disenchantWindow:SetSize(120, 65)

    if LF.db.enchantWindowPos then
        local p, _, rp, x, y = LF.db.enchantWindowPos.point, nil, LF.db.enchantWindowPos.relativePoint, LF.db.enchantWindowPos.x, LF.db.enchantWindowPos.y
        disenchantWindow:ClearAllPoints()
        disenchantWindow:SetPoint(p, UIParent, rp, x, y)
    else
        disenchantWindow:SetPoint("CENTER")
    end

    disenchantWindow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        tileSize = 0, -- ignored since tile = false
        edgeSize = 3,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    disenchantWindow:SetBackdropColor(unpack(LF.Colors.Background)) 
    disenchantWindow:SetBackdropBorderColor(unpack(LF.Colors.Border)) 
    disenchantWindow:SetClampedToScreen(true)

    disenchantWindow:EnableMouse(true)
    disenchantWindow:SetMovable(true)
    disenchantWindow:RegisterForDrag("LeftButton")
    disenchantWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    disenchantWindow:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing() 
        local point, _, relativePoint, x, y = self:GetPoint()
        LF.db.enchantWindowPos = {point = point, relativePoint = relativePoint, x = x, y = y}
    end)
    LF.disenchantWindow = disenchantWindow
    disenchantWindow:SetFrameStrata("HIGH")




    disenchantWindow.countLabel = disenchantWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disenchantWindow.countLabel:SetText("Count")
    disenchantWindow.countLabel:SetPoint("TOP", disenchantWindow, "TOP", 0, -2)

    disenchantWindow.nextItemIcon = disenchantWindow:CreateTexture(nil, "ARTWORK")
    disenchantWindow.nextItemIcon:SetSize(16, 16)
    disenchantWindow.nextItemIcon:SetPoint("TOPLEFT", disenchantWindow, "TOPLEFT", 2, -20)

    disenchantWindow.nextItemLabel = disenchantWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disenchantWindow.nextItemLabel:SetText("Item")
    disenchantWindow.nextItemLabel:SetPoint("LEFT", disenchantWindow.nextItemIcon, "RIGHT", 6, 0)



    local button = CreateFrame("Button", "DisenchantNextButton", disenchantWindow, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    button:SetSize(100, 25)
    button:SetPoint("TOP", disenchantWindow, "TOP", 0, -40)
    button:SetText("Disenchant")

    -- Set initial macro text (will be updated dynamically) 
    button:SetAttribute("type", "macro")
    button:SetScript("PreClick", function(self)
        if UnitAffectingCombat("player") then
            print("Can not auto disenchant in combat")
            return
        end
        local disenchant = GetSpellInfo("13262")
        local start, duration, enabled = GetSpellCooldown(disenchant)
        local onCooldown = (enabled == 1 and (start > 0 and duration > 0))
        local casting = UnitCastingInfo("player")
        local looting = LootFrame:IsVisible()
        local usable = IsUsableSpell(disenchant)
        local moving = GetUnitSpeed("player")
        local channeling = UnitChannelInfo("player")
        if moving > 0 or casting or not usable or onCooldown or looting or channeling then
            disenchantWindow.button:SetAttribute("macrotext", "")
            return
        end
        LF.UpdateMacroText(false)
    end)

    button:SetScript("PostClick", function(self)
        LF.lastAtoDisenchantClickTime = GetTime()
    end)

    disenchantWindow.button = button
    LF.UpdateMacroText(true)

    disenchantWindow.disenchantButton = disenchantButton
end




function LF.showDisenchantWindow()
    if not disenchantWindow then
        LF.createDisenchantWindow()
    end
    disenchantWindow:ClearAllPoints()
    disenchantWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    disenchantWindow:Show()
end

function LF.hideDisenchantWindow()
    if disenchantWindow then disenchantWindow:Hide() end
end



