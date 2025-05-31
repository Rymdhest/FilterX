LF = LF or {}

function LF.SetSelectedFilterByName(name)
    for _, filter in ipairs(LF.db.filters or {}) do
        if filter.name == name then
            LF.db.selectedFilterName = name
            return true
        end
    end
    print("Could not set selected filter.")
    return false
end

function LF.GetSelectedFilter()
    for _, filter in ipairs(LF.db.filters or {}) do
        if filter.name == LF.db.selectedFilterName then
            return filter
        end
    end
    return nil
end

local function IsFilterNameUnique(name)
    for _, filter in ipairs(LF.db.filters or {}) do
        if filter.name == name then
            return false
        end
    end
    return true
end

function LF.CreateNewFilter()
    local baseName = "New Filter"
    local uniqueName = baseName
    local i = 1

    while not IsFilterNameUnique(uniqueName) do
        i = i + 1
        uniqueName = baseName .. " " .. i
    end

    local filter = {
        name = uniqueName,
        rules = {},
        isAutoAddWhenVendoring = false
    }

    table.insert(LF.db.filters, filter)
    return filter
end

function LF.DeleteFilterByName(nameToDelete)
    for i, filter in ipairs(LF.db.filters) do
        if filter.name == nameToDelete then
            table.remove(LF.db.filters, i)
            if LF.db.selectedFilterName == nameToDelete then
                LF.db.selectedFilterName = nil
            end
            return true
        end
    end
    return false
end

function LF.setAutoAddVendor(setTo)
    if LF.GetSelectedFilter() then
        LF.GetSelectedFilter().isAutoAddWhenVendoring = setTo
    end
end

function LF.addRule(filter, rule)
    if not filter.rules then
        filter.rules = {}
    end
    table.insert(filter.rules, rule)
end

function LF.RenameFilter(filter, newName)
    if not IsFilterNameUnique(newName)  then
        print("A filter with that name already exists.")
        return false
    end
    if not LF.isNameAllowed(newName) then
        print("Name not allowed.")
        return false
    end
    if LF.GetSelectedFilter()then
        if LF.GetSelectedFilter().name == filter.name then
            LF.db.selectedFilterName = newName
        end
    end
    filter.name = newName
    return true
end

local function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for k, v in next, orig, nil do
            copy[DeepCopy(k)] = DeepCopy(v)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function LF.CopyFilter(originalFilter)
    local newFilter = DeepCopy(originalFilter)
    newFilter.name = originalFilter.name.." (copy)"
    table.insert(LootFilterDB.filters, newFilter)
    LF.SetSelectedFilterByName(newFilter.name)
    return newFilter
end