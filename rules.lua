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
      itemIDs = {},
      words = {},
      regex = "",
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
        ["Artifact"] = true,
        ["Legendary"] = true,
        ["Common"] = true,
        ["Epic"] = true,
        ["Heirloom"] = true,
        ["Uncommon"] = true,
        ["Rare"] = true,
        ["Poor"] = true,
      },
      classes = {},
      learned = "Any",
      lootAlert = false,
      action = "Sell",      -- keep, delete, disenchant, sell, nothing
  }
  LF.addRule(LF.GetSelectedFilter(), rule)
  return rule
end

function LF.describeRule(rule)
    local parts = {}

    local moreThanSuffix = " or more"
    local lessThanSuffix = " or less"

    -- Action and enabled status
    table.insert(parts, rule.isEnabled and ("|cff00ff00" .. rule.action .. "|r") or ("|cffff0000" .. rule.action .. "|r"))

    -- Regex or itemIDs
    if rule.isUseIDs and #rule.itemIDs > 0 then
        table.insert(parts, "IDs: " .. table.concat(rule.itemIDs, ", "))
    elseif rule.regex ~= "" then
        table.insert(parts, "Name match: \"" .. rule.regex .. "\"")
    end

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
        table.insert(parts, "Rarity: " .. table.concat(rarities, ", "))
    end

    -- Type filters
    local function addType(desc, value)
        if value ~= "Any" then
            table.insert(parts, desc .. ": " .. value)
        end
    end
    --addType("Recipe", rule.recipe)

    -- Loot alert
    if rule.lootAlert then
        table.insert(parts, "🔔 Alert")
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
    rule.itemIDs[itemID] = true
end

function LF.RemoveItemIDFromRule(rule, itemID)
    if rule.itemIDs then
        rule.itemIDs[itemID] = nil
    end
end

function LF.HasItemIDInRule(rule, itemID)
    return rule.itemIDs and rule.itemIDs[itemID] or false
end