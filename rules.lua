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
      isUseIDs = false,
      itemIDs = {},
      regex = "",
      minCount = 0,
      itemLevelMin = 10,
      itemLevelMax = 100,
      levelRequirementMin = -1,
      levelRequirementMax = -1,
      rarity = {
          uncommon = true,
          common = true,
          magic = true,
          rare = true,
          epic = true,
          legendary = true,
      },
      isRecipe = "any",
      recipeLearned = "any",
      consumable = "any",
      equippable = "yes",
      weapon = "yes",
      mount = "no",
      mountLearned = "any",
      lootAlert = false,
      action = "Sell",      -- keep, delete, disenchant, sell, nothing
  }
  LF.addRule(LF.GetSelectedFilter(), rule)
  return rule
end

function LF.describeRule(rule)
    local parts = {}

    -- Name and enabled status
    table.insert(parts, rule.isEnabled and ("|cff00ff00" .. rule.name .. "|r") or ("|cffff0000" .. rule.name .. "|r"))

    -- Regex or itemIDs
    if rule.isUseIDs and #rule.itemIDs > 0 then
        table.insert(parts, "IDs: " .. table.concat(rule.itemIDs, ", "))
    elseif rule.regex ~= "" then
        table.insert(parts, "Name match: \"" .. rule.regex .. "\"")
    end

    -- Count
    if rule.minCount > 0 then
        table.insert(parts, "Min Count: " .. rule.minCount)
    end

    -- Item level range
    if rule.itemLevelMin > -1 or rule.itemLevelMax > -1 then
        local min = rule.itemLevelMin > -1 and rule.itemLevelMin or "?"
        local max = rule.itemLevelMax > -1 and rule.itemLevelMax or "?"
        table.insert(parts, "Item Level: " .. min .. "-" .. max)
    end

    -- Level requirement range
    if rule.levelRequirementMin > -1 or rule.levelRequirementMax > -1 then
        local min = rule.levelRequirementMin > -1 and rule.levelRequirementMin or "?"
        local max = rule.levelRequirementMax > -1 and rule.levelRequirementMax or "?"
        table.insert(parts, "Req Level: " .. min .. "-" .. max)
    end

    -- Rarity
    local rarities = {}
    for rarity, enabled in pairs(rule.rarity) do
        if enabled then table.insert(rarities, rarity) end
    end
    if #rarities > 0 and #rarities < 6 then
        table.insert(parts, "Rarity: " .. table.concat(rarities, ", "))
    end

    -- Type filters
    local function addType(desc, value)
        if value ~= "any" then
            table.insert(parts, desc .. ": " .. value)
        end
    end
    addType("Recipe", rule.isRecipe)
    addType("Recipe Known", rule.recipeLearned)
    addType("Consumable", rule.consumable)
    addType("Equippable", rule.equippable)
    addType("Weapon", rule.weapon)
    addType("Mount", rule.mount)
    addType("Mount Known", rule.mountLearned)

    -- Loot alert
    if rule.lootAlert then
        table.insert(parts, "🔔 Alert")
    end

    -- Action
    if rule.action and rule.action ~= "nothing" then
        table.insert(parts, "Action: " .. rule.action)
    end

    return table.concat(parts, " | ")
end

function LF.GetIconForRuleAction(action)
    return LF.actions[action] or "Interface\\Icons\\INV_Misc_QuestionMark"
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