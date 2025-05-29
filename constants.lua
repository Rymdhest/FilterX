LF = LF or {}

LF.Colors = {
    Background = LF.NormalizeColor({13, 27, 42, 255}),
    Border     = LF.NormalizeColor({27, 38, 59, 255}),
    Text       = LF.NormalizeColor({224, 225, 221, 255}),
    Highlight  = LF.NormalizeColor({119, 141, 169, 255}),
    Overlay    = LF.NormalizeColor({65, 90, 119, 255}),
}

LF.actions = {
    ["Keep"]       = {priority = 1, icon = "Interface\\Icons\\INV_Misc_Bag_07"},
    ["Delete"]     = {priority = 2, icon = "Interface\\Icons\\Ability_Creature_Cursed_02"},
    ["Disenchant"] = {priority = 3, icon = "Interface\\Icons\\Spell_Holy_RemoveCurse"},
    ["Sell"]       = {priority = 4, icon = "Interface\\Icons\\INV_Misc_Coin_02"},
    ["Nothing"]    = {priority = 5, icon = "Interface\\Icons\\INV_Misc_QuestionMark"},
}

LF.modes = {
    Conditions  = "Conditions",
    Items     =  "Exact items",
}

LF.ItemRarities = {
    [0] = { name = "Poor",      color = {0.62, 0.62, 0.62}},
    [1] = { name = "Common",    color = {1.00, 1.00, 1.00}},
    [2] = { name = "Uncommon",  color = {0.12, 1.00, 0.00}},
    [3] = { name = "Rare",      color = {0.00, 0.44, 0.87}},
    [4] = { name = "Epic",      color = {0.64, 0.21, 0.93}},
    [5] = { name = "Legendary", color = {1.00, 0.50, 0.00}},
    [6] = { name = "Artifact",  color = {0.90, 0.80, 0.50}},
    [7] = { name = "Heirloom",  color = {0.90, 0.80, 0.50}},
}

LF.ItemRaritiesByName = {}
for id, data in pairs(LF.ItemRarities) do
    LF.ItemRaritiesByName[data.name] = { id = id, color = data.color }
end
