LF = LF or {}

LF.fancyName = "|cffFFee33Filter|r|cffff0000X|r"

function LF.NormalizeColor(color)
    return {color[1] / 255, color[2] / 255, color[3] / 255, color[4] / 255}
end
LF.Colors = {
    Background = LF.NormalizeColor({13, 27, 42, 255}),
    Border     = LF.NormalizeColor({27, 38, 59, 255}),
    Text       = LF.NormalizeColor({224, 225, 221, 255}),
    Highlight  = LF.NormalizeColor({119, 141, 169, 255}),
    Overlay    = LF.NormalizeColor({65, 90, 119, 255}),
}

LF.defaults = {
    globals = {
        autoVendor = true,
        alwaysShowDisenchant = false,

        
        alertGoldVendoring = true,
        alertLoot = true,
        alertContainers = true,
        alertCrafting = true,
    }
}

LF.actions = {
    ["Keep"]       = {priority = 1, icon = "Interface\\Icons\\INV_Misc_Bag_07", color = {0.10, 1.00, 0.10}},
    ["Delete"]     = {priority = 2, icon = "Interface\\Icons\\Ability_Creature_Cursed_02", color = {1.00, 0.10, 0.10}},
    ["Disenchant"] = {priority = 3, icon = "Interface\\Icons\\Spell_Holy_RemoveCurse", color = {0.00, 0.44, 0.87}},
    ["Sell"]       = {priority = 4, icon = "Interface\\Icons\\INV_Misc_Coin_02", color = {1.00, 1.00, 0.00}},
    ["Nothing"]    = {priority = 5, icon = "Interface\\Icons\\Spell_Nature_Sleep", color = {1.00, 1.00, 1.00}},
}
LF.actionsKeys = { "Keep", "Delete", "Disenchant", "Sell", "Nothing" }

LF.alerts = {
    ["Nothing"]= {toast = "", priority = 5},
    ["Small"]  = {toast = "commontoast", priority = 4},
    ["Medium"] = {toast = "defaulttoast", priority = 3},
    ["Large"]  = {toast = "heroictoast", priority = 2},
    ["Huge"]   = {toast = "legendarytoast", priority = 1},
}
LF.alertKeys = { "Huge", "Large", "Medium", "Small", "Nothing" }

LF.modes = {
    ["Conditions"]  = "Conditions",
    ["Items"]   = "Exact Items",
}
LF.modesKeys = { "Items", "Conditions"}

LF.basicOptions = {
    ["Any"]   = {ID = 1, color = {1.00, 1.00, 1.00}},
    ["Yes"]   = {ID = 2, color = {0.10, 1.00, 0.10}},
    ["No"]    = {ID = 3, color = {1.00, 0.10, 0.10}},
}
LF.basicOptionKeys = { "Any", "Yes", "No" }

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

LF.referenceItems = {
    ["Consumable"] = {
        __class = 22854,
        ["Consumable"]= 835,
        ["Potion"]       = 118,
        ["Elixir"]      = 9187,
        ["Flask"]     = 13512,
        ["Scroll"]     = 43466,
        ["Food & Drink"]     = 4457,
        ["Item Enhancement"]     = 24276,
        ["Bandage"]     = 14530,
        ["Other"]     = 49633,
    },
    ["Container"] = {
        __class = 4500  ,
        ["Bag"]     = 14046,
        ["Soul Bag"]   = 21340,
        ["Herb Bag"]      = 22248,
        ["Enchanting Bag"]     = 22246,
        ["Engineering Bag"]     = 30745,
        ["Gem Bag"]     = 30747,
        ["Mining Bag"]     = 30746,
        ["Leatherworking Bag"]     = 34482,
        ["Inscription Bag"]     = 39489,
    },
    ["Weapon"] = {
        __class = 15250,
        ["One-handed Axe"]     = 1459,
        ["Two-handed Axe"]       = 12784,
        ["Bow"]      = 3039    ,
        ["Gun"]      = 16004,
        ["One-handed Mace"]      = 7736,
        ["Two-handed Mace"]      = 13047,
        ["Polearm"]      = 13055,
        ["One-handed Sword"]      = 5191,
        ["Two-handed Sword"]      = 13052,
        ["Staff"]      = 873,
        ["Fist Weapon"]      = 11744,
        ["Dagger"]      = 2632,
        ["Thrown"]      = 39138,
        ["Crossbow"]      = 13038,
        ["Wand"]      = 5244,
        ["Fishing Pole"]      = 6367,
        ["Miscellaneous"]      = 2901,
    },
    ["Gem"] = {
        __class = 32231,
        ["Red"]     = 23436,
        ["Blue"]       = 23438,
        ["Yellow"]      = 23440,
        ["Purple"]      = 23441,
        ["Green"]      = 23437,
        ["Orange"]      = 23439,
        ["Meta"]      = 41398,
        ["Prismatic"]      = 49110,
        ["Simple"]      = 3864,
    },
    ["Armor"] = {
        __class = 2986,
        ["Cloth"]     = 16605,
        ["Leather"]       = 27552,
        ["Mail"]      = 15487,
        ["Plate"]      = 7939,
        ["Shield"]      = 15014,
        ["Libram"]      = 23203,
        ["Idol"]      = 22398,
        ["Totem"]      = 22396,
        ["Sigil"]      = 39208,
        ["Miscellaneous"] = 7673,
    },
    ["Reagent"] = {
        __class = 17056,
        ["Reagent"]     = 17056,
    },
    ["Projectile"] = {
        __class = 28060,
        ["Arrow"]     = 3464,
        ["Bullet"]       = 11630,
    },
    ["Trade Goods"] = {
        __class = 4291,
        ["Parts"]       = 4382,
        ["Devices"]      = 22728,
        ["Jewelcrafting"]      = 21752,
        ["Cloth"]      = 4306,
        ["Leather"]      = 8170,
        ["Metal & Stone"]      = 3575,
        ["Herb"]      = 2447,
        ["Meat"]      = 769,
        ["Explosives"]      = 10586,
        ["Elemental"]      = 7078,
        ["Enchanting"]      = 16204,
        ["Materials"]      = 23572,
        ["Armor Enchantment"]      = 38682,
        ["Weapon Enchantment"]      = 39349,
        ["Other"]      = 17010,
    },
    ["Recipe"] = {   
        __class = 42176, 
        ["Book"]     = 44956,
        ["Leatherworking"]       = 44552,
        ["Tailoring"]      = 42176,
        ["Engineering"]      = 44918,
        ["Blacksmithing"]      = 44937,
        ["Cooking"]      = 5484    ,
        ["Alchemy"]      = 22910,
        ["First Aid"]      = 39152,
        ["Enchanting"]      = 44484,
        ["Fishing"]      = 16083,
        ["Jewelcrafting"]      = 41718,
    },
    ["Quiver"] = {
        __class = 29143,
        ["Quiver"]     = 11362,
        ["Ammo Pouch"]       = 11363,
    },
    ["Quest"] = {
        __class = 49643,
        ["Quest"]     = 49643,
    },
    ["Key"] = {
        __class = 7146,
        ["Key"]     = 7146,
    },
    ["Miscellaneous"] = {
        __class = 18796,
        ["Junk"]     = 16882,
        ["Pet"]      = 8491,
        ["Holiday"]      = 17202,
        ["Mount"]      = 18776,
        ["Other"]      = 32897,
    },
    ["Glyph"] = {
        __class = 43415,
        ["Warrior"]     = 43415,
        ["Paladin"]       = 41105,
        ["Hunter"]      = 42897,
        ["Rogue"]      = 42964,
        ["Priest"]      = 42400,
        ["Death Knight"]      = 43533,
        ["Shaman"]      = 41532,
        ["Mage"]      = 42734,
        ["Warlock"]      = 42465,
        ["Druid"]      = 40922,
    },
}

LF.referenceLookup = {}
for class, subclasses in pairs(LF.referenceItems) do
    for subclass, itemID in pairs(subclasses) do
        if subclass ~= "__class" then
            LF.referenceLookup[itemID] = { class = class, subclass = subclass }
        end
    end
end

