LF = LF or {}


function LF.SetSelectedRuleByName(name)
    for _, rule in ipairs(LF.GetSelectedFilter().rules or {}) do
        if rule.name == name then
            LF.currentSelectedRuleName = name
            return true
        end
    end
    print("Could not set selected rule.")
    return false
end

function LF.getRuleByName(name)
    for _, rule in ipairs(LF.GetSelectedFilter().rules or {}) do
        if rule.name == name then
            return rule
        end
    end
    print("Could not find rule.")
end

function LF.GetSelectedRule()
    for _, rule in ipairs(LF.GetSelectedFilter().rules or {}) do
        if rule.name == LF.currentSelectedRuleName then
            return rule
        end
    end
end

local function IsRuleNameUnique(name)
    for _, rule in ipairs(LF.GetSelectedFilter().rules or {}) do
        if rule.name == name then
            return false
        end
    end
    return true
end

function LF.createNewRule()
    local baseName = "New Rule"
    local uniqueName = baseName
    local i = 1

    while not IsRuleNameUnique(uniqueName) do
        i = i + 1
        uniqueName = baseName .. " " .. i
    end

    local rule = {
      name = uniqueName,
      isEnabled = true,
      locked = false,
      itemIDs = {},
      words = {},
      mode = "Items",
      itemLevelMin = nil,
      itemLevelMax = nil,
      levelRequirementMin = nil,
      levelRequirementMax = nil,
      goldValueMin = nil,
      goldValueMax = nil,
      countMin = nil,
      countMax = nil,
      rarity = {
        ["Artifact"] = false,
        ["Legendary"] = false,
        ["Common"] = false,
        ["Epic"] = false,
        ["Heirloom"] = false,
        ["Uncommon"] = false,
        ["Rare"] = false,
        ["Poor"] = false,
      },
      classes = {},
      learned = "Any",
      soulbound = "Any",
      alert = "Nothing",
      action = "Sell",      -- keep, delete, disenchant, sell, nothing
  }
  LF.addRule(LF.GetSelectedFilter(), rule)
  return rule
end

function LF.describeRule(rule)
    local parts = {}

    -- Action and enabled status
    table.insert(parts, "|cff" .. LF.RGBToHex(unpack(LF.actions[rule.action].color)) ..rule.action.. "|r")

    
    if rule.mode == "Items" then

        local count = 0
        local max = 30
        for itemID, value in pairs(rule.itemIDs) do
            count = count+1
        end
        local itemstring = ""
        local count2 = 0
        for itemID, value in pairs(rule.itemIDs) do
            if count2 >= max then 
                itemstring = itemstring.. " + "..count-count2.." more"
                break
            end
            local item = LF.GetItemInfoObject(itemID)
            local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
            if item then icon = item.icon end
            local name = ""
            local color = LF.RGBToHex(unpack(LF.ItemRarities[item.quality].color))
            if count < 4 then name = " |cff"..color..item.name.."|r " end
            itemstring = itemstring.." |T" .. icon ..":13:13:0:0|t"..name
            count2 = count2+1
        end
        table.insert(parts, itemstring)
        
        if count == 0 then
            table.insert(parts, "NOTHING")
        end

    else 
        local moreThanSuffix = " or more"
        local lessThanSuffix = " or less"

        -- Gold Value range
        if rule.goldValueMin and rule.goldValueMax then
            local min = rule.goldValueMin
            local max = rule.goldValueMax
            table.insert(parts, "Value: " .. min .. "-" .. max .. " Gold")
        elseif rule.goldValueMin then
            local min = rule.goldValueMin
            table.insert(parts, "Value: " .. min .. moreThanSuffix .. " Gold")
        elseif rule.goldValueMax then
            local max = rule.goldValueMax
            table.insert(parts, "Value: " .. max .. lessThanSuffix .. " Gold")
        end

        -- Item level range
        if rule.itemLevelMin and rule.itemLevelMax then
            local min = rule.itemLevelMin
            local max = rule.itemLevelMax
            table.insert(parts, "Item Level: " .. min .. "-" .. max)
        elseif rule.itemLevelMin then
            local min = rule.itemLevelMin
            table.insert(parts, "Item Level: " .. min .. moreThanSuffix)
        elseif rule.itemLevelMax then
            local max = rule.itemLevelMax
            table.insert(parts, "Item Level: " .. max .. lessThanSuffix)
        end

        -- Level requirement range
        if rule.levelRequirementMin and rule.levelRequirementMax then
            local min = rule.levelRequirementMin
            local max = rule.levelRequirementMax
            table.insert(parts, "Level Req: " .. min .. "-" .. max)
        elseif rule.levelRequirementMin then
            local min = rule.levelRequirementMin
            table.insert(parts, "Level Req: " .. min .. moreThanSuffix)
        elseif rule.levelRequirementMax then
            local max = rule.levelRequirementMax
            table.insert(parts, "Level Req: " .. max .. lessThanSuffix)
        end

            -- count range
        if rule.countMin and rule.countMax then
            local min = rule.countMin
            local max = rule.countMax
            table.insert(parts, "item Count: " .. min .. "-" .. max)
        elseif rule.countMin then
            local min = rule.countMin
            table.insert(parts, "Item Count: " .. min .. moreThanSuffix)
        elseif rule.countMax then
            local max = rule.countMax
            table.insert(parts, "Item Count: " .. max .. lessThanSuffix)
        end

        -- Rarity
        local temp = {}
        for rarityName, enabled in pairs(rule.rarity) do
            if enabled then
                local data = LF.ItemRaritiesByName[rarityName]
                if data and data.color then
                    table.insert(temp, {
                        id = data.id,
                        name = rarityName,
                        color = data.color
                    })
                end
            end
        end
        -- Sort by rarity ID
        table.sort(temp, function(a, b) return a.id < b.id end)
        -- Build final formatted list
        local rarities = {}
        for _, entry in ipairs(temp) do
            local r, g, b = unpack(entry.color)
            r, g, b = r * 255, g * 255, b * 255
            local colorCode = string.format("|cff%02x%02x%02x", r, g, b)
            table.insert(rarities, colorCode .. entry.name .. "|r")
        end
        if #rarities > 0 and #rarities <= #LF.ItemRarities then
            table.insert(parts, table.concat(rarities, ", "))
        end

            -- item classes
        for className, subClassTable in pairs(rule.classes) do
            local knownSubclasses = LF.referenceItems[className]
            local allEnabled = true
            local enabledSubclasses = {}

            for subClassName, _ in pairs(knownSubclasses) do
                if subClassName ~= "__class" then
                    if subClassTable[subClassName] ~= 1 then
                        allEnabled = false
                    else
                        table.insert(enabledSubclasses, subClassName)
                    end
                end
            end

            if allEnabled then
                table.insert(parts, "All "..className)
            else
                if #enabledSubclasses > 1 then
                    table.insert(parts, table.concat(enabledSubclasses, ", "))
                elseif #enabledSubclasses == 1 then
                    table.insert(parts, enabledSubclasses[1])
                end
                -- if no enabled subclasses, do nothing
            end
        end

        -- words
        if rule.words then
            local wordList = {}
            for word, _ in pairs(rule.words) do
                table.insert(wordList, "\"" .. word .. "\"")
            end

            if #wordList > 0 then
                table.insert(parts, table.concat(wordList, ", "))
            end
        end

            -- Learned
        if rule.learned ~= "Any" then
            local text = "Already Learned"
            if rule.learned == "No" then text = "Not Learned" end
            table.insert(parts, text)
        end

        -- Binds
        if rule.soulbound ~= "Any" then
            local text = "BoP"
            if rule.soulbound == "No" then text = "Not BoP" end
            table.insert(parts, text)
        end

        if #parts < 2 then
            table.insert(parts, "EVERYTHING")
        end
    end

    -- Loot alert
    if rule.alert ~= "Nothing" then
        local icon = "|TInterface\\Icons\\INV_Misc_Bell_01:14:14|t"
        local text = rule.alert .." " .. icon
        table.insert(parts, text)
    end

    return table.concat(parts, " | ")
end

function LF.GetIconForRuleAction(action)
    return LF.actions[action].icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function LF.RenameRuleInCurrentFilter(rule, newName)
    if not IsRuleNameUnique(newName)  then
        print("A rule with that name already exists in the filter.")
        return false
    end
    if not LF.isNameAllowed(newName) then
        print("Name not allowed.")
        return false
    end
    if rule then
        if LF.currentSelectedRuleName == rule.name then
            LF.currentSelectedRuleName = newName
        end
    end
    rule.name = newName
    return true
end

function LF.DeleteRuleByName(nameToDelete)
    for i, rule in ipairs(LF.GetSelectedFilter().rules) do
        if rule.name == nameToDelete then
            table.remove(LF.GetSelectedFilter().rules, i)
            if LF.currentSelectedRuleName == nameToDelete then
                LF.currentSelectedRuleName = nil
                LF.hideRuleWindow()
            end
            return true
        end
    end
    return false
end

function LF.AddItemIDToRule(rule, itemID)
    rule.itemIDs = rule.itemIDs or {}
    if rule.itemIDs[itemID] then
        return false
    else
        rule.itemIDs[itemID] = true
        LF.RefreshRuleWindowItemList()
        LF.RefreshFilterWindowRuleList()
        return true
    end
end



function LF.RemoveItemIDFromRule(rule, itemID)
    if rule.itemIDs and rule.itemIDs[itemID] then
        rule.itemIDs[itemID] = nil
        LF.RefreshRuleWindowItemList()
        LF.RefreshFilterWindowRuleList()
        return true
    else
        return false
    end
end

function LF.HasItemIDInRule(rule, itemID)
    return rule.itemIDs and rule.itemIDs[itemID] or false
end

function LF.AddWordToRule(rule, word)
    rule.words = rule.words or {}
    if rule.words[word] then
        return false
    else
        rule.words[word] = true
        LF.RefreshRuleWindowWordList()
        LF.RefreshFilterWindowRuleList()
        return true
    end
end

function LF.RemoveWordFromRule(rule, word)
    if rule.words and rule.words[word] then
        rule.words[word] = nil
        LF.RefreshRuleWindowWordList()
        LF.RefreshFilterWindowRuleList()
        return true
    else
        return false
    end
end