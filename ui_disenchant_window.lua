LF = LF or {}

local disenchantWindow


function LF.UpdateMacroText(first)
        local bag1, slot1, bag2, slot2 = LF.FindNextDisenchantableItem()
        local bag = bag1
        local slot = slot1
        if not first then
            bag = bag2
            slot = slot2
        end
        if bag and slot then 
            local macroText = string.format("/cast Disenchant\n/use %d %d", bag, slot)
            disenchantWindow.button:SetAttribute("macrotext", macroText)
        else 
            disenchantWindow.button:SetAttribute("macrotext", "/run print('No more items to disenchant')")
        end
    end


function LF.createDisenchantWindow()
    disenchantWindow = CreateFrame("Frame", "DisenchantFrame", UIParent)
    LF.disenchantWindow = disenchantWindow
    disenchantWindow:SetSize(100, 100)
    disenchantWindow:SetPoint("CENTER")

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

    disenchantWindow:EnableMouse(true)
    disenchantWindow:SetMovable(true)
    disenchantWindow:RegisterForDrag("LeftButton")
    disenchantWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    disenchantWindow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    LF.disenchantWindow = disenchantWindow
    disenchantWindow:SetFrameStrata("HIGH")


    local button = CreateFrame("Button", "DisenchantNextButton", disenchantWindow, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    button:SetSize(100, 30)
    button:SetPoint("CENTER")
    button:SetText("Disenchant Next")

    -- Set initial macro text (will be updated dynamically) 
    button:SetAttribute("type", "macro")
    button:SetScript("PreClick", function(self)
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



