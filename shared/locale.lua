Locales = {}

local translationCache = {} -- Cache for translations

function _(str, ...) -- Translate string
    -- Check cache first
    if translationCache[str] then
        if select('#', ...) > 0 then
            local ok, out = pcall(string.format, translationCache[str], ...)
            if ok then return out end
        end
        return translationCache[str]
    end

    local lang = Config.defaultlang
    local defaultLang = "en_lang" -- Set your fallback language here (e.g., 'en')

    if Locales[lang] ~= nil then
        if Locales[lang][str] ~= nil then
            translationCache[str] = Locales[lang][str] -- Cache the translation for faster future access
            if select('#', ...) > 0 then
                local ok, out = pcall(string.format, Locales[lang][str], ...)
                if ok then return out end
            end
            return Locales[lang][str]
        elseif Locales[defaultLang] ~= nil and Locales[defaultLang][str] ~= nil then
            translationCache[str] = Locales[defaultLang][str]
            if select('#', ...) > 0 then
                local ok, out = pcall(string.format, Locales[defaultLang][str], ...)
                if ok then return out end
            end
            return Locales[defaultLang][str]
        else
            return 'Translation [' .. lang .. '][' .. str .. '] and fallback [' .. defaultLang .. '] do not exist'
        end
    else
        return 'Locale [' .. lang .. '] does not exist'
    end
end

function _U(str, ...) -- Translate string first char uppercase
    -- Use cached translation if available
    local translation = _(str, ...)
    return translation:sub(1, 1):upper() .. translation:sub(2)
end
