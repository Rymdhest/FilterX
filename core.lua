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

function LF:ADDON_LOADED(addonName)
    if addonName == name then
        LootFilterDB = LootFilterDB or {}
        LF.db = LootFilterDB
        LF.db.filters = LF.db.filters or {}

        LF.db.isAutoVendoring = true

        eventFrame:UnregisterEvent("ADDON_LOADED")

        LF.InitializeItemClassLookup()
        LF.showMainWindow()
        GameTooltip:HookScript("OnTooltipSetItem", AddToTooltip)
        ItemRefTooltip:HookScript("OnTooltipSetItem", AddToTooltip)
        GameTooltip:HookScript("OnTooltipCleared", function(self)
            self.__LF_CustomLineAdded = false
        end)
    end
end

local function checkConditionForRuleAndItem(rule, item)

    if not item then
        print("Item is nil, cannot check rule.")
        return false
    end
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

    local numRarities = 0
    for rarity, data in pairs(rule.rarity) do
        if not data==false then numRarities = numRarities+1 end
    end

    if numRarities > 0 then 
        if not rule.rarity[LF.ItemRarities[item.quality].name] then return false end
    end


    --print(item.class.."  |  "..item.subClass)

    local numClasses = 0
    for class, subclasses in pairs(rule.classes) do
        numClasses = numClasses+1
    end

if numClasses > 0 then
    if not rule.classes[item.class] then return false end
    if not rule.classes[item.class][item.subClass] then return false end
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
    if not item then return end
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

function LF.PerformDeleteCheckInventory()
    local currPrice

    for bag = -2,4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag,slot)
            if link then
                local itemID = tonumber(link:match("item:(%d+)"))
                local action = LF.EvaluateActionForItemIDAgainstRules(itemID)
                if action == "Delete" then
                    PickupContainerItem(bag, slot)
                    DeleteCursorItem()
                    print("|cffff0000Deleted:|r "..link)
                end
            end
        end
    end
end

function LF.PerformSellInventory()
  local currPrice

  for bag = 0,4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item then
        local itemID = tonumber(item:match("item:(%d+)"))
        local action = LF.EvaluateActionForItemIDAgainstRules(itemID)
        if action == "Sell" then
          currPrice = select(11, LF.GetItemInfo(item)) * select(2, GetContainerItemInfo(bag, slot))
          if currPrice > 0 then
            PickupContainerItem(bag, slot)
            PickupMerchantItem()
            print("SOLD".." "..item)

          end
        end
      end
    end
  end
end

function LF:BAG_UPDATE(bagID)
    LF.PerformDeleteCheckInventory()
end

function LF:MERCHANT_SHOW()
    if LF.db.   isAutoVendoring then
        LF.PerformSellInventory()
    end
end

function LF:MERCHANT_UPDATE()
    -- Example: restock items
end

function LF:ITEM_LOCK_CHANGED(bagID, slotID)
    -- Useful for tracking item usage (e.g., selling, moving)
end