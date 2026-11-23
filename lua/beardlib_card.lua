local mod = ModInstance
local function install()
    local menu_class = BeardLibModsMenu
    if not mod or not menu_class then return false end
    if menu_class._turkce_yama_version_card then return true end
    menu_class._turkce_yama_version_card = true
    Hooks:PostHook(menu_class, 'AddMod', 'TurkceYama_ReadableVersion', function(menu, added)
        if added ~= mod then return end
        local card = menu._list and menu._list:GetItemByLabel(mod)
        if not card then return end
        local titles = 0
        for _, item in ipairs(card:Items()) do
            if item.name == 'Title' then
                titles = titles + 1
                if titles == 2 then
                    item:SetText(managers.localization:text('beardlib_version', {
                        version = tostring(mod._config.version)
                    }))
                    break
                end
            end
        end
    end)
    return true
end
if not install() then
    Hooks:Add('BeardLibPostInit', 'TurkceYama_InstallVersionCard', install)
end
