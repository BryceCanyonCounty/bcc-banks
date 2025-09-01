function OpenAccessMenu(account, ParentPage)
    local AccessMenuPage = FeatherBankMenu:RegisterPage("account:page:access:" .. tostring(account.id))


    AccessMenuPage:RegisterElement("header", {
        value = "Account Access",
        slot = "header"
    })


    AccessMenuPage:RegisterElement("subheader", {
        value = "Manage access to this account",
        slot = "header"
    })


    AccessMenuPage:RegisterElement("line", { slot = "header", style = {} })

    AccessMenuPage:RegisterElement("button", {
        label = "Give Access",
        style = {}
    }, function()
        OpenGiveAccessPage(account, AccessMenuPage)
    end)


    AccessMenuPage:RegisterElement("button", {
        label = "Remove Access",
        style = {}
    }, function()
        OpenRemoveAccessPage(account, AccessMenuPage)
    end)


    AccessMenuPage:RegisterElement("line", {
        slot = "footer",
        style = {}
    })

    AccessMenuPage:RegisterElement("button", {
        label = "Back",
        slot = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)

    AccessMenuPage:RegisterElement("bottomline", {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = AccessMenuPage })
end

-- Give access
function OpenGiveAccessPage(account, ParentPage)
    local GiveAccessPage = FeatherBankMenu:RegisterPage("account:page:access:give:" .. tostring(account.id))

    -- Header
    GiveAccessPage:RegisterElement("header", {
        value = "Give Access",
        slot = "header"
    })
    GiveAccessPage:RegisterElement("line", {
        slot = "header",
        style = {}
    })

    local charId = nil
    local level = nil

    GiveAccessPage:RegisterElement("input", {
        label = "Character ID",
        placeholder = "Enter character ID",
        style = {}
    }, function(data)
        charId = tonumber(data.value)
    end)

    GiveAccessPage:RegisterElement("input", {
        label = "Access Level",
        placeholder = "Enter level (1-4)",
        style = {}
    }, function(data)
        level = tonumber(data.value)
    end)

    TextDisplay = GiveAccessPage:RegisterElement("textdisplay", {
        value = "Access Levels:\n1 = Admin (full access)\n2 = Withdraw/Deposit\n3 = Deposit only\n4 = View only",
        slot = "content"
    })

    GiveAccessPage:RegisterElement("line", {
        slot = "footer",
        style = {}
    })

    GiveAccessPage:RegisterElement("button", {
        label = "Grant Access",
        slot = "footer",
        style = {}
    }, function()
        if not charId or charId < 1 then
            Notify("Please enter a valid Character ID.", 4000)
            return
        end

        if not level or level < 1 or level > 4 then
            Notify("Access level must be between 1 and 4.", 4000)
            return
        end

        local ok, result = Feather.RPC.CallAsync("Feather:Banks:GiveAccountAccess", {
            account = account.id,
            character = charId,
            level = level
        })

        if not ok then
            devPrint("Failed to give access:", result)
            return
        end

        Notify("Access granted successfully.", 3000)
        OpenAccessMenu(account, ParentPage)
    end)

    GiveAccessPage:RegisterElement("button", {
        label = "Back",
        slot = "footer",
        style = {}
    }, function()
        OpenAccessMenu(account, ParentPage)
    end)

    GiveAccessPage:RegisterElement("bottomline", {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = GiveAccessPage })
end

function OpenRemoveAccessPage(account, ParentPage)
    local RemoveAccessPage = FeatherBankMenu:RegisterPage("account:page:access:remove:" .. tostring(account.id))
    RemoveAccessPage:RegisterElement("header", {
        value = "Remove Access",
        slot = "header"
    })

    RemoveAccessPage:RegisterElement("line", {
        slot = "header",
        style = {}
    })

    local ok, response = Feather.RPC.CallAsync("Feather:Banks:GetAccountAccessList", {
        account = account.id
    })

    if not ok or not response or type(response) ~= "table" then
        Notify("Failed to load access list.", 4000)
        return
    end

    local accessList = response.access or {}

    if #accessList == 0 then
        RemoveAccessPage:RegisterElement("textdisplay", {
            value = "No characters currently have access.",
            style = { ["text-align"] = "center", color = "gray" }
        })
    else
        for _, access in ipairs(accessList) do
            local fullName = string.format("%s %s", access.first_name or "Unknown", access.last_name or "")
            local label = string.format("[%d] %s (Level %d)", access.character_id, fullName, access.level)

            RemoveAccessPage:RegisterElement("button", {
                label = label,
                style = {}
            }, function()
                local ConfirmPage = FeatherBankMenu:RegisterPage("account:page:access:remove:confirm:" ..
                    tostring(access.character_id))

                ConfirmPage:RegisterElement("header", {
                    value = "Confirm Removal",
                    slot = "header"
                })

                ConfirmPage:RegisterElement("textdisplay", {
                    value = "Are you sure you want to remove access for:\n" ..
                        fullName .. "[ " .. access.character_id .. "]",
                    style = { ["text-align"] = "center" }
                })

                ConfirmPage:RegisterElement("button", {
                    label = "Yes, Remove",
                    style = {}
                }, function()
                    local ok = Feather.RPC.CallAsync("Feather:Banks:RemoveAccountAccess", {
                        account = account.id,
                        character = access.character_id
                    })

                    if ok then
                        devPrint("Access removed for character ID:", access.character_id)
                    else
                        devPrint("Failed to remove access for character ID:", access.character_id)
                    end
                    OpenRemoveAccessPage(account, ParentPage)
                end)

                ConfirmPage:RegisterElement("button", {
                    label = "No, Go Back",
                    style = {}
                }, function()
                    OpenRemoveAccessPage(account, ParentPage)
                end)

                FeatherBankMenu:Open({ startupPage = ConfirmPage })
            end)
        end
    end

    RemoveAccessPage:RegisterElement("button", {
        label = "Back",
        slot = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)

    FeatherBankMenu:Open({ startupPage = RemoveAccessPage })
end
