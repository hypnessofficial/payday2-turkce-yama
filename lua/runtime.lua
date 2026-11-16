-- This file is loaded by BeardLib from assets/mod_overrides. No second BLT mod.
-- Current game archives include hash-only IDs which cannot be addressed by a
-- normal localization JSON file. Resolve those IDs to registered JSON aliases.
local root = ModPath
log('[Consistent Turkish] Loading localization support tables (native Lua).')
local function load_data(name)
    local loader = blt and blt.vm and blt.vm.dofile or dofile
    local ok, data = pcall(loader, root .. name .. '.lua')
    if ok and type(data) == 'table' then
        return data
    end
    log('[Consistent Turkish] Could not load ' .. name .. ': ' .. tostring(data))
    return {}
end
-- SuperBLT's legacy JSON parser repeatedly scans/copies the full input. Native
-- Lua data tables avoid stalling startup on the multi-megabyte text catalogs.
local aliases = load_data('hash_aliases')
local upper = load_data('uppercase')
local function load_chunks(files)
    local values = {}
    for _, name in ipairs(files or {}) do
        for key, value in pairs(load_data(name)) do
            values[key] = value
        end
    end
    return values
end
local upper_ids = load_chunks(upper.ids)
local upper_values = load_chunks(upper.values)
log('[Consistent Turkish] Support tables ready; no startup JSON parsing.')

local function install(loc)
    local cls = LocalizationManager
    if not cls or cls._consistent_turkish_installed then
        return
    end
    cls._consistent_turkish_installed = true
    local resolved = {}
    local function resolve(self, id)
        if type(id) ~= 'string' then
            return id
        end
        local alias = resolved[id]
        if alias == nil then
            alias = aliases[Idstring(id):key()] or false
            resolved[id] = alias
        end
        if alias and self._custom_localizations and self._custom_localizations[alias] then
            return alias
        end
        return id
    end
    local original_text = cls.text
    function cls:text(id, ...)
        local selected = resolve(self, id)
        local text = original_text(self, selected, ...)
        -- Keep this installation's casing_mode_plus carry interactions working.
        if type(text) == 'string' and type(id) == 'string' and id:find('^hud_int_')
            and self._custom_localizations and self._custom_localizations[selected]
            and _G.PD25 and PD25.carry_selecting and managers and managers.player
            and managers.player:current_state() == 'mask_off' then
            text = text:gsub(' için ', ' için maskeni tak ve ', 1)
        end
        return text
    end
    local original_exists = cls.exists
    function cls:exists(id, ...)
        return original_exists(self, resolve(self, id), ...)
    end
    -- Uppercase authored literals before macro substitution: player/weapon names
    -- use their own casing, while already-localized macro values use Turkish.
    local original_upper = cls.to_upper_text
    function cls:to_upper_text(id, macros)
        local selected = resolve(self, id)
        local template = upper_ids[selected]
        if template and self._custom_localizations and self._custom_localizations[selected] then
            local alias = '__consistent_tr_caps_' .. Idstring(selected):key()
            self._custom_localizations[alias] = template
            local upper_macros = {}
            for name, value in pairs(type(macros) == 'table' and macros or {}) do
                upper_macros[name] = type(value) == 'string' and (upper_values[value] or utf8.to_upper(value)) or value
            end
            local text = original_text(self, alias, upper_macros)
            if type(id) == 'string' and id:find('^hud_int_')
                and _G.PD25 and PD25.carry_selecting and managers and managers.player
                and managers.player:current_state() == 'mask_off' then
                text = text:gsub(' İÇİN ', ' İÇİN MASKENİ TAK VE ', 1)
            end
            return utf8.to_upper(text)
        end
        return original_upper(self, id, macros)
    end
    log('[Consistent Turkish] Localization loaded; hash aliases and Turkish uppercase active.')
end

if managers and managers.localization then
    install(managers.localization)
else
    Hooks:Add('LocalizationManagerPostInit', 'ConsistentTurkish_HashAliases', install)
end
