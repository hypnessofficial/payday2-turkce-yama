if not ExtendedPanel or not ExtendedPanel.text or ExtendedPanel._turkce_yama_native_text then return end

local original_text = ExtendedPanel.text
function ExtendedPanel:text(config, ...)
    local loc = managers and managers.localization
    if type(config) == 'table' and config.text == nil and type(config.text_id) == 'string'
        and loc and loc._custom_localizations and type(loc._custom_localizations[config.text_id]) == 'string' then
        local translated = {}
        for key, value in pairs(config) do translated[key] = value end
        translated.text = loc:text(config.text_id, config.macros)
        translated.text_id = nil
        return original_text(self, translated, ...)
    end
    return original_text(self, config, ...)
end
ExtendedPanel._turkce_yama_native_text = true
