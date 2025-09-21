function OpenAccessMenu(account, ParentPage)
    local AccessMenuPage = FeatherBankMenu:RegisterPage("account:page:access:" .. tostring(account.id))

    AccessMenuPage:RegisterElement("header", {
        value = _U("account_access_header"),
        slot  = "header"
    })

    AccessMenuPage:RegisterElement("subheader", {
        value = _U("account_access_subheader"),
        slot  = "header"
    })

    AccessMenuPage:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    AccessMenuPage:RegisterElement("button", {
        label = _U("give_access_button"),
        style = {}
    }, function()
        OpenGiveAccessPage(account, ParentPage)
    end)

    AccessMenuPage:RegisterElement("button", {
        label = _U("remove_access_button"),
        style = {}
    }, function()
        OpenRemoveAccessPage(account, ParentPage)
    end)

    AccessMenuPage:RegisterElement("line", {
        slot  = "footer",
        style = {}
    })

    AccessMenuPage:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        OpenAccountDetails(account, ParentPage)
    end)

    AccessMenuPage:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = AccessMenuPage })
end

function OpenGiveAccessPage(account, ParentPage)
    local GiveAccessPage = FeatherBankMenu:RegisterPage("account:page:access:give:" .. tostring(account.id))

    GiveAccessPage:RegisterElement("header", {
        value = _U("give_access_header"),
        slot  = "header"
    })

    GiveAccessPage:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    local charId = nil
    local level  = nil

    GiveAccessPage:RegisterElement("input", {
        label       = _U("character_id_label"),
        placeholder = _U("character_id_placeholder"),
        style       = {}
    }, function(data)
        charId = tonumber(data.value)
    end)

    GiveAccessPage:RegisterElement("input", {
        label       = _U("access_level_label"),
        placeholder = _U("access_level_placeholder"),
        style       = {}
    }, function(data)
        level = tonumber(data.value)
    end)

    GiveAccessPage:RegisterElement("textdisplay", {
        value = _U("access_levels_description"),
        slot  = "content"
    })

    GiveAccessPage:RegisterElement("line", {
        slot  = "footer",
        style = {}
    })

    GiveAccessPage:RegisterElement("button", {
        label = _U("grant_access_button"),
        slot  = "footer",
        style = {}
    }, function()
        if not charId or charId < 1 then
            Notify(_U("invalid_character_id"), 4000)
            return
        end

        if not level or level < 1 or level > 4 then
            Notify(_U("invalid_access_level"), 4000)
            return
        end

        local ok, result = BccUtils.RPC:CallAsync("Feather:Banks:GiveAccountAccess", {
            account   = account.id,
            character = charId,
            level     = level
        })

        if not ok then
            devPrint("Failed to give access:", result)
            return
        end
        OpenAccessMenu(account, ParentPage)
    end)
    
    GiveAccessPage:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        OpenAccessMenu(account, ParentPage)
    end)

    GiveAccessPage:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = GiveAccessPage })
end

function OpenRemoveAccessPage(account, ParentPage)
    local RemoveAccessPage = FeatherBankMenu:RegisterPage("account:page:access:remove:" .. tostring(account.id))

    RemoveAccessPage:RegisterElement("header", {
        value = _U("remove_access_header"),
        slot  = "header"
    })

    RemoveAccessPage:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    local accountId = NormalizeId(account.id)

    local ok, response = BccUtils.RPC:CallAsync("Feather:Banks:GetAccountAccessList", {
        account = accountId
    })

    if not ok or not response or type(response) ~= "table" then return end

    local accessList = response.access or {}

    if #accessList == 0 then
        RemoveAccessPage:RegisterElement("textdisplay", {
            value = _U("no_access_characters"),
            style = {
                ["text-align"] = "center",
                color           = "gray"
            }
        })
    else
        for _, access in ipairs(accessList) do
            local fullName = (access.first_name or _U("unknown")) .. " " .. (access.last_name or "")
            local label    = "[" .. tostring(access.character_id) .. "] " .. fullName .. " (" .. _U("level") .. " " .. tostring(access.level) .. ")"

            RemoveAccessPage:RegisterElement("button", {
                label = label,
                style = {}
            }, function()
                local ConfirmPage = FeatherBankMenu:RegisterPage("account:page:access:remove:confirm:" .. tostring(access.character_id))

                ConfirmPage:RegisterElement("header", {
                    value = _U("confirm_removal_header"),
                    slot  = "header"
                })

                ConfirmPage:RegisterElement("textdisplay", {
                    value = _U("confirm_removal_text") .. "\n" .. fullName .. " [" .. tostring(access.character_id) .. "]",
                    style = { ["text-align"] = "center" }
                })

                ConfirmPage:RegisterElement("button", {
                    label = _U("confirm_removal_button"),
                    style = {}
                }, function()
                    local ok = BccUtils.RPC:CallAsync("Feather:Banks:RemoveAccountAccess", {
                        account   = accountId,
                        character = access.character_id
                    })

                    if ok then devPrint(_U("access_removed_log"), access.character_id)
                    else devPrint(_U("failed_remove_access_log"), access.character_id) end
                    OpenRemoveAccessPage(account, ParentPage)
                end)

                ConfirmPage:RegisterElement("button", {
                    label = _U("cancel_removal_button"),
                    style = {}
                }, function()
                    OpenRemoveAccessPage(account, ParentPage)
                end)

                FeatherBankMenu:Open({ startupPage = ConfirmPage })
            end)
        end
    end

    RemoveAccessPage:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)

    FeatherBankMenu:Open({ startupPage = RemoveAccessPage })
end
