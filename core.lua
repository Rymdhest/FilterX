local name = ...
LF = LF or {}
LF.addonName = name


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_UPDATE")
eventFrame:RegisterEvent("ITEM_LOCK_CHANGED")
eventFrame:RegisterEvent("ITEM_PUSH")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")

eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")


local lastSoldItem = nil
SLASH_LOOTFILTER1 = "/LF"
SLASH_LOOTFILTER2 = "/LootFilter"
local MAX_AT_ONCE = 80
local isAutoing = false

local pendingDisenchantItem = nil
local UseContainerItemTime = 0
local startDisenchantTime = 0
local suceedDisenchantTime = 0

local lastAtoDisenchantClickTime = 0


SlashCmdList["LOOTFILTER"] = function(msg)
    LF.showMainWindow()
end

local function AddToTooltip(tooltip)
    -- Avoid adding multiple times
    if tooltip.__LF_CustomLineAdded then return end

    local _, link = tooltip:GetItem()
    if not link then return end

    local itemID = tonumber(link:match("item:(%d+)"))
    if not itemID then return end

    local action = LF.EvaluateActionForItemIDAgainstRules(itemID)
    if action then
        local actionText = "|cff00ff00["..action.."]|r"
        local actionicon = " |T" .. LF.actions[action].icon .. ":16:16:0:0|t"
        tooltip:AddLine(actionicon .. actionText)
        tooltip.__LF_CustomLineAdded = true
        tooltip:Show()
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if LF[event] then
        LF[event](self, ...)
    end
end)

-- Create once at addon load time
if not LF.ScanTooltip then
    LF.ScanTooltip = CreateFrame("GameTooltip", "LFScanTooltip", UIParent, "GameTooltipTemplate")
    LF.ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
end

function LF.searchTooltipForString(itemLink, searchString)
    local tooltip = LF.ScanTooltip
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink.link)

    for i = 1, tooltip:NumLines() do
        local text = _G["LFScanTooltipTextLeft" .. i] and _G["LFScanTooltipTextLeft" .. i]:GetText()
        if text then
            -- print("Line", i, ":", text)
            if text:lower():find(searchString:lower(), 1, true) then
                return true
            end
        end
    end

    return false
end

local function removeItemAutoSell(itemLink)
    if not LF.GetSelectedFilter() then return end
    local autoAddRule = LF.getRuleByName("Auto Add From Vendoring")
    if not autoAddRule then return end
    if LF.RemoveItemIDFromRule(autoAddRule, tonumber(itemLink:match("item:(%d+)"))) then
        print("removed "..itemLink.." from auto sell")
    end
end

function LF:ADDON_LOADED(addonName)
    if addonName == name then
        LootFilterDB = LootFilterDB or {}
        LF.db = LootFilterDB
        LF.db.filters = LF.db.filters or {}
        LF.db.isAutoVendoring = true

        LF.isAutoDisenchanting = false

        eventFrame:UnregisterEvent("ADDON_LOADED")

        LF.InitializeItemClassLookup()
        LF.showMainWindow()
        GameTooltip:HookScript("OnTooltipSetItem", AddToTooltip)
        ItemRefTooltip:HookScript("OnTooltipSetItem", AddToTooltip)
        GameTooltip:HookScript("OnTooltipCleared", function(self)
            self.__LF_CustomLineAdded = false
        end)
        -- Hook into Buyback function
        hooksecurefunc("BuybackItem", function(index)
            if not LF.GetSelectedFilter().isAutoAddWhenVendoring then return end
            local itemLink = GetBuybackItemLink(index)
            if itemLink then
                removeItemAutoSell(itemLink)
            end
        end)

        LF.showDisenchantWindow()

        hooksecurefunc("UseContainerItem", function(bag, slot)
            pendingDisenchantItem = GetContainerItemLink(bag, slot)
            UseContainerItemTime = GetTime()
        end)

    end
end



local function checkConditionForRuleAndItem(rule, item)
    --print(item.class, item.subclass, item.name, item.id, item.level, item.requiredLevel, item.sellPrice, item.count)
    --print(item.class.."  |  "..item.subClass)


    if not item then
        print("Item is nil, cannot check rule.")
        return false
    end

        ------------------ WORDS ------------------------
    if rule.words then
        local found = false
        local empty = true
        for word, _ in pairs(rule.words) do
            empty = false
            local pattern = "%f[%w]" .. word:lower() .. "%f[%W]"
            if string.find(item.name:lower(), pattern) then
                found = true
            end
        end
        if not found and not empty then return false end
    end



    ------------------ MIN-MAX ------------------------
    if rule.itemLevelMin and item.level < rule.itemLevelMin then return false end
    if rule.itemLevelMax and item.level > rule.itemLevelMax then return false end
    if rule.levelRequirementMin and item.requiredLevel < rule.levelRequirementMin then return false end
    if rule.levelRequirementMax and item.requiredLevel > rule.levelRequirementMax then return false end
    if rule.goldValueMin and item.sellPrice < rule.goldValueMin then return false end
    if rule.goldValueMax and item.sellPrice > rule.goldValueMax then return false end
    --if rule.countMin and item.count < rule.countMin then return false end
    --if rule.countMax and item.count > rule.countMax then return false end


    ------------------ RARITY ------------------------
    local numRarities = 0
    for rarity, data in pairs(rule.rarity) do
        if not data==false then numRarities = numRarities+1 end
    end
    if numRarities > 0 then 
        if not rule.rarity[LF.ItemRarities[item.quality].name] then return false end
    end



    ------------------ CLASSES ------------------------
    local numClasses = 0
    for class, subclasses in pairs(rule.classes) do
        numClasses = numClasses+1
    end
    if numClasses > 0 then
        if not rule.classes[item.class] then return false end
        if not rule.classes[item.class][item.subClass] then return false end
    end 


    ------------------ LEARNED ------------------------
    local isKnown = LF.searchTooltipForString(item, "already known.")
    if rule.learned == "Yes" and not isKnown then return false end
    if rule.learned == "No" and isKnown then return false end

    
        ------------------ BINDS ------------------------
    if rule.soulbound ~= "Any" then
        local bindOnPickup = LF.searchTooltipForString(item, ITEM_BIND_ON_PICKUP)
        local bindOnEquip = LF.searchTooltipForString(item, ITEM_BIND_ON_EQUIP )
        if rule.soulbound == "when picked up" and not bindOnPickup then return false end
        if rule.soulbound == "when equipped" and not bindOnEquip then return false end
        if rule.soulbound == "never bound" and (bindOnEquip or bindOnPickup) then return false end
    end

    return true
end



function RuleMatchesItem(rule, item)
    if rule.mode == "Items" then
        if rule.itemIDs[item.id] then return true end
    else
        if checkConditionForRuleAndItem(rule, item) then return true end
    end

    return false
end

function LF.EvaluateActionForItemIDAgainstRules(itemID)
    local action = "Nothing"
    local alert = "Nothing"
    local bestActionPriority = LF.actions[action].priority
    local bestAlertPriority = LF.alerts[alert].priority
    if LF.GetSelectedFilter() == nil then
        return action
    end

    local item = LF.GetItemInfoObject(itemID)
    if not item then return end
    for _, rule in ipairs(LF.GetSelectedFilter().rules) do
        if rule.isEnabled and RuleMatchesItem(rule, item) then
            local ruleActionPriority = LF.actions[rule.action].priority
            if ruleActionPriority < bestActionPriority then
                action = rule.action
                bestActionPriority = ruleActionPriority
            end
            local ruleAlertPriority = LF.alerts[rule.alert].priority
            if ruleAlertPriority < bestAlertPriority then
                alert = rule.alert
                bestAlertPriority = ruleAlertPriority
            end
        end
    end

    return action, alert
end

local function deleteItemBagSlot(bag, slot, link)
    PickupContainerItem(bag, slot)
    DeleteCursorItem()
    print("|cffff0000Deleted:|r "..link)
end
local function deleteItemByLink(itemLink)
    for bag = -2, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link == itemLink then
                deleteItemBagSlot(bag, slot, itemLink)
                return
            end
        end
    end
end

function LF.FindNextDisenchantableItem()
    local found = 0
    local bag1, slot1
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemID = tonumber(link:match("item:(%d+)"))
                local action = LF.EvaluateActionForItemIDAgainstRules(itemID)
                if (action == "Disenchant") then
                    found = found+1
                    if found < 2 then
                        bag1 = bag
                        slot1 = slot
                    end
                    if found >= 2 then 
                        return bag1, slot1, bag, slot end
                end
            end
        end
    end                 
    if found >= 1 then 
    return bag1, slot1, bag1, slot1 end
    return nil -- no item found
end

function LF.PerformSellInventory(startBag, startSlot, startEarned, totalSoldStart)
    local currPrice
    local earned = startEarned or 0
    isAutoing = true
    local numItemsAffect = 0
    local totalSoldCount = totalSoldStart or 0

    for bag = startBag or -2,NUM_BAG_SLOTS do
        for slot = startSlot or 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag,slot)
        if link then
            local itemID = tonumber(link:match("item:(%d+)"))
            local action = LF.EvaluateActionForItemIDAgainstRules(itemID)
            if action == "Sell" then
                currPrice = select(11, LF.GetItemInfo(link)) * select(2, GetContainerItemInfo(bag, slot))
                if currPrice > 0 then
                    PickupContainerItem(bag, slot)
                    PickupMerchantItem()
                    print("Sold".." "..link)
                    numItemsAffect = numItemsAffect +1
                    earned = earned+currPrice
                    totalSoldCount = totalSoldCount+1
                end
                elseif action == "Delete" then 
                    deleteItemBagSlot(bag, slot, link)
                    numItemsAffect = numItemsAffect +1
                end
            end
        end
    end
    if numItemsAffect > MAX_AT_ONCE then 
            C_Timer.After(1.0, function()
                LF.PerformSellInventory(bag, slot, earned, totalSoldCount)
            end)
            return
        end
    C_Timer.After(1, function()
        isAutoing = false
    end)


    local amount = GetMoneyString(earned, true);
    if earned > 0 then
        if totalSoldCount == 1 then print ("Sold "..totalSoldCount.." item worth: "..amount)
        else print ("Sold "..totalSoldCount.." items worth: "..amount) end

        LF.AddAlert(amount, false, LF.ItemRaritiesByName["Artifact"].id, false, false, "test", "moneytoast", false, false, false, earned)
    end
end
-- Function to track sold items based on locked items
local function DetectSoldItem()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            local _, _, locked = GetContainerItemInfo(bag, slot)
            if locked and itemLink then
                lastSoldItem = itemLink
                return
            end
        end
    end
end


local function addItemAutoSell(lastSoldItem)
    if not LF.GetSelectedFilter() then return end
    if isAutoing then return end
    local rule = LF.getRuleByName("Auto Add From Vendoring")
    if not rule then
        rule = LF.createNewRule()
        rule.name = "Auto Add From Vendoring"
        rule.mode = "Items"
        rule.action = "Sell"
        rule.locked = false
    end
    if LF.AddItemIDToRule(rule, tonumber(lastSoldItem:match("item:(%d+)"))) then
        print("Added "..lastSoldItem.." to auto sell")
    end
end

local function addItemAutoDisenchant(item)
    if not LF.GetSelectedFilter() then return end
    if LF.isAutoDisenchanting then return end
    local rule = LF.getRuleByName("Auto Add From Disenchanting")
    if not rule then
        rule = LF.createNewRule()
        rule.name = "Auto Add From Disenchanting"
        rule.mode = "Items"
        rule.action = "Disenchant"
        rule.locked = false
    end
    if LF.AddItemIDToRule(rule, tonumber(item:match("item:(%d+)"))) then
        print("Added "..item.." to auto Disenchant")
    end
end

function LF:BAG_UPDATE(bagID)
    --LF.PerformDeleteCheckInventory()
end

function LF:MERCHANT_SHOW()
    lastSoldItem = nil -- Reset on vendor open
    if LF.db.   isAutoVendoring then
        LF.PerformSellInventory()
    end
end

function LF:MERCHANT_UPDATE()
    if not LF.GetSelectedFilter().isAutoAddWhenVendoring then return end
    if lastSoldItem then
        addItemAutoSell(lastSoldItem)
        lastSoldItem = nil -- Reset after processing sale
    end
end

function LF:ITEM_LOCK_CHANGED(bagID, slotID)
    DetectSoldItem()
end

function LF:ITEM_PUSH(bagID, icon)
    C_Timer.After(0.1, function()
        --LF.PerformDeleteCheckInventory()
    end)
end

function LF:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, type, lineID)
    if unit == "player" and spellName == GetSpellInfo(13262) then
        local time = GetTime()
        if time - startDisenchantTime < 4 and pendingDisenchantItem then
            suceedDisenchantTime = time
        else 
            pendingDisenchantItem = nil
        end
    end
end

function LF:LOOT_OPENED(autoLoot)
        local time = GetTime()
        if time - suceedDisenchantTime < 1 and pendingDisenchantItem then
            if time - LF.lastAtoDisenchantClickTime > 4 then
                addItemAutoDisenchant(pendingDisenchantItem)
            end
        end
        pendingDisenchantItem = nil
end



function LF:UNIT_SPELLCAST_START(unit)
    if unit == "player" and UnitCastingInfo("player") == GetSpellInfo(13262) then
        local time = GetTime()
        if time - UseContainerItemTime < 1 and pendingDisenchantItem then
            startDisenchantTime = time
            if time-LF.lastAtoDisenchantClickTime > 1 then
                LF.lastAtoDisenchantClickTime = 0
            end
        else 
            pendingDisenchantItem = nil
        end
    end
end

function LF:CURRENT_SPELL_CAST_CHANGED()
end


function LF:UNIT_SPELLCAST_INTERRUPTED()
    LF.lastAtoDisenchantClickTime = 0
end

function LF:UNIT_SPELLCAST_STOP()
end

function LF:UNIT_SPELLCAST_FAILED()
    LF.lastAtoDisenchantClickTime = 0
end

function LF:UNIT_SPELLCAST_FAILED_QUIET()
    LF.lastAtoDisenchantClickTime = 0
end


function LF:CHAT_MSG_LOOT(msg)
    local itemLink, count = msg:match("You receive item: (.+)x(%d+)%.")

    if not itemLink then
        itemLink = msg:match("You receive item: (.+)%.")
        count = 1
    else
        count = tonumber(count)
    end
    if itemLink then
        local itemID = tonumber(itemLink:match("item:(%d+):"))
        local item = LF.GetItemInfoObject(itemID)

        local action, alert = LF.EvaluateActionForItemIDAgainstRules(itemID)
        if action == "Delete" then
            C_Timer.After(0.1, function()
                deleteItemByLink(itemLink) 
            end)
        end
        if alert ~= "Nothing" then LF.AddAlert(item.name, item.link, item.quality, item.icon, count, true, LF.alerts[alert].toast, false, false, false, false) end
    end
end
