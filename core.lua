local name = ...
LF = LF or {}
LF.addonName = name


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_UPDATE")
eventFrame:RegisterEvent("ITEM_LOCK_CHANGED")

local function AddToTooltip(tooltip)
    local _, link = tooltip:GetItem()
    local itemID = tonumber(link:match("item:(%d+)"))
    local action = LF.EvaluateActionForItemIDAgainstRules(itemID)
    if action then
        local actionText = "|cff00ff00["..action.."]|r"
        local actionicon = " |T" .. LF.actions[action].icon ..":16:16:0:0|t"
        tooltip:AddLine(actionicon..actionText)
        tooltip:Show()
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if LF[event] then
        LF[event](self, ...)
    end
end)

function LF:ADDON_LOADED(addonName)
    if addonName == name then
        LootFilterDB = LootFilterDB or {}
        LF.db = LootFilterDB
        LF.db.filters = LF.db.filters or {}
        eventFrame:UnregisterEvent("ADDON_LOADED")

        LF.showMainWindow()
        GameTooltip:HookScript("OnTooltipSetItem", AddToTooltip)
        ItemRefTooltip:HookScript("OnTooltipSetItem", AddToTooltip)

    end
end

local function shouldFilterByRarity(filter, itemRarity)
  local rarityFilter = filter.rarity
  local allTrue, allFalse = true, true

  for _, value in pairs(rarityFilter) do
    if value then allFalse = false else allTrue = false end
    if not allTrue and not allFalse then break end
  end

  -- Ignore filter if all true or all false
  if allTrue or allFalse then
    return true  -- Don't filter out
  end
  return rarityFilter[LF.ItemRarities[itemRarity].name] == true
end

local function checkConditionForRuleAndItem(rule, item)

    --print(item.class, item.subclass, item.name, item.id, item.level, item.requiredLevel, item.sellPrice, item.count)

    if rule.regex and rule.regex ~= "" and string.match(item.name, rule.regex) then
        return true
    end

    if rule.words and #rule.words > 0 then
        for _, word in ipairs(rule.words) do
            if string.find(item.name:lower(), word:lower()) then
                return true
            end
        end
    end

    if rule.itemLevelMin and item.level < rule.itemLevelMin then return false end
    if rule.itemLevelMax and item.level > rule.itemLevelMax then return false end
    if rule.levelRequirementMin and item.requiredLevel < rule.levelRequirementMin then return false end
    if rule.levelRequirementMax and item.requiredLevel > rule.levelRequirementMax then return false end
    if rule.goldValueMin and item.sellPrice < rule.goldValueMin then return false end
    if rule.goldValueMax and item.sellPrice > rule.goldValueMax then return false end
    if rule.countMin and item.count < rule.countMin then return false end
    if rule.countMax and item.count > rule.countMax then return false end



    print("item.class:", item.class, "item.subclass:", item.subClass)
    if rule.equippable ~= "Any" then 
        if rule.equippable == "Yes" then 
            if item.class == "Armour" or item.class == "Weapon" then return false end
        elseif rule.equippable == "No" then
            if item.class == "Armour" or item.class == "Weapon" then return true end
        end
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
    local bestAction = "Nothing"
    local bestPriority = LF.actions[bestAction].priority
    if LF.GetSelectedFilter() == nil then
        return bestAction
    end

    local item = LF.GetItemInfoObject(itemID)
    for _, rule in ipairs(LF.GetSelectedFilter().rules) do
        if rule.isEnabled and RuleMatchesItem(rule, item) then
            local rulePriority = LF.actions[rule.action].priority
            if rulePriority < bestPriority then
                bestAction = rule.action
                bestPriority = rulePriority
            end
        end
    end

    return bestAction
end

function LF:BAG_UPDATE(bagID)
    print("Bag updated: Bag ID =", bagID)
    -- Example: check inventory or update your UI
end

function LF:MERCHANT_SHOW()
    print("Merchant window opened")
    -- Example: auto-sell gray items
end

function LF:MERCHANT_UPDATE()
    print("Merchant inventory updated")
    -- Example: restock items
end

function LF:ITEM_LOCK_CHANGED(bagID, slotID)
    print("Item lock changed in bag", bagID, "slot", slotID)
    -- Useful for tracking item usage (e.g., selling, moving)
end