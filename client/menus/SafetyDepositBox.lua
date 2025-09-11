function OpenSDBListPage(bank, ParentPage)
    local SDBListPage = FeatherBankMenu:RegisterPage('bank:page:sdb:list:' .. tostring(bank.id))
    SDBListPage:RegisterElement('header', {
        value = _U("sdb_list_header"),
        slot  = 'header'
    })
    SDBListPage:RegisterElement('subheader', {
        value = _U("sdb_list_subheader"),
        slot  = 'header'
    })
    SDBListPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })
    local ok, boxes = BccUtils.RPC:CallAsync('Feather:Banks:GetSDBs', { bank = bank.id })
    if not ok or not boxes or #boxes == 0 then
        SDBListPage:RegisterElement('textdisplay', {
            value = _U("no_boxes_found"),
            slot  = 'content'
        })
    else
        for _, box in ipairs(boxes) do
            local label = (box.name or _U("box_default_name", tostring(box.id)))
            SDBListPage:RegisterElement('button', {
                label = label,
                style = {}
            }, function()
                OpenSDBBoxMenu(box, ParentPage, SDBListPage)
            end)
        end
    end
    SDBListPage:RegisterElement('line', {
        style = {}
    })
    SDBListPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    SDBListPage:RegisterElement('button', {
        label = _U("create_new_box_button"),
        slot  = 'footer',
        style = {}
    }, function()
        OpenCreateSDBPage(bank, SDBListPage)
    end)
    SDBListPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    SDBListPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = SDBListPage })
end

function OpenSDBBoxMenu(box, ParentPage, SDBListPage)
    local SDBoxPage = FeatherBankMenu:RegisterPage('bank:page:sdb:box:' .. tostring(box.id))
    SDBoxPage:RegisterElement('header', {
        value = _U("sdb_box_header"),
        slot  = 'header'
    })
    SDBoxPage:RegisterElement('subheader', {
        value = _U("sdb_box_subheader"),
        slot  = 'header'
    })
    SDBoxPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })
    SDBoxPage:RegisterElement('button', {
        label = _U("open_box_button"),
        style = {}
    }, function()
        OpenSDBInventory(box, ParentPage)
    end)
    SDBoxPage:RegisterElement('button', {
        label = _U("manage_access_button"),
        style = {}
    }, function()
        OpenSDBAccessMenu(box, ParentPage, SDBListPage)
    end)
    SDBoxPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    SDBoxPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = 'footer',
        style = {}
    }, function()
        SDBListPage:RouteTo()
    end)
    SDBoxPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = SDBoxPage })
end

function OpenCreateSDBPage(bank, ParentPage, selectedPayWith)
    local CreateSDBPage = FeatherBankMenu:RegisterPage('bank:page:sdb:create:' .. tostring(bank.id))
    CreateSDBPage:RegisterElement('header', {
        value = _U("create_sdb_header"),
        slot  = 'header'
    })
    CreateSDBPage:RegisterElement('subheader', {
        value = _U("create_sdb_subheader"),
        slot  = 'header'
    })
    CreateSDBPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })
    local sdbName = ''
    local sdbSize = nil
    CreateSDBPage:RegisterElement('input', {
        label       = _U("box_name_label"),
        placeholder = _U("box_name_placeholder"),
        style       = {}
    }, function(data)
        sdbName = data.value
    end)
    CreateSDBPage:RegisterElement('line', { style = {} })
    
    -- Choose payment currency
    local payWith = selectedPayWith or 'cash' -- 'cash' or 'gold'
    CreateSDBPage:RegisterElement('textdisplay', {
        value = 'Select payment:',
        slot  = 'content'
    })
    CreateSDBPage:RegisterElement('button', {
        label = 'Pay With Cash',
        style = {}
    }, function()
        Notify('Payment set to Cash', 1500)
        OpenCreateSDBPage(bank, ParentPage, 'cash')
    end)
    CreateSDBPage:RegisterElement('button', {
        label = 'Pay With Gold',
        style = {}
    }, function()
        Notify('Payment set to Gold', 1500)
        OpenCreateSDBPage(bank, ParentPage, 'gold')
    end)
    
    CreateSDBPage:RegisterElement('line', { style = {} })
    CreateSDBPage:RegisterElement('textdisplay', {
        value = _U('select_size_text'),
        slot  = 'content'
    })

    -- Show slot counts per size so players can choose informed
    local sizes = (Config and Config.SafetyDepositBoxes and Config.SafetyDepositBoxes.Sizes) or {}
    local smallSlots  = tonumber(sizes.Small  and sizes.Small.MaxWeight)  or 0
    local mediumSlots = tonumber(sizes.Medium and sizes.Medium.MaxWeight) or 0
    local largeSlots  = tonumber(sizes.Large  and sizes.Large.MaxWeight)  or 0

    local function priceStr(cashVal, goldVal)
        if payWith == 'gold' then
            return tostring(tonumber(goldVal or 0) or 0) .. ' gold'
        else
            return '$' .. tostring(tonumber(cashVal or 0) or 0)
        end
    end

    local smallPriceStr  = priceStr(sizes.Small and sizes.Small.CashPrice,  sizes.Small and sizes.Small.GoldPrice)
    local mediumPriceStr = priceStr(sizes.Medium and sizes.Medium.CashPrice, sizes.Medium and sizes.Medium.GoldPrice)
    local largePriceStr  = priceStr(sizes.Large and sizes.Large.CashPrice,  sizes.Large and sizes.Large.GoldPrice)
    CreateSDBPage:RegisterElement('button', {
        label = _U('size_small_button') .. ' (' .. tostring(smallSlots) .. ' slots, ' .. smallPriceStr .. ')',
        style = {}
    }, function()
        sdbSize = 'Small'
        Notify(_U("size_selected_notify", _U("size_small_button")), 2000)
    end)
    CreateSDBPage:RegisterElement('button', {
        label = _U('size_medium_button') .. ' (' .. tostring(mediumSlots) .. ' slots, ' .. mediumPriceStr .. ')',
        style = {}
    }, function()
        sdbSize = 'Medium'
        Notify(_U("size_selected_notify", _U("size_medium_button")), 2000)
    end)
    CreateSDBPage:RegisterElement('button', {
        label = _U('size_large_button') .. ' (' .. tostring(largeSlots) .. ' slots, ' .. largePriceStr .. ')',
        style = {}
    }, function()
        sdbSize = 'Large'
        Notify(_U("size_selected_notify", _U("size_large_button")), 2000)
    end)
    CreateSDBPage:RegisterElement('line', {
        style = {}
    })
    CreateSDBPage:RegisterElement('button', {
        label = _U("create_box_button"),
        style = {}
    }, function()
        if not sdbName or sdbName == '' then
            Notify(_U("enter_box_name_notify"), 3000)
            return
        end
        if not sdbSize then
            Notify(_U("select_size_notify"), 3000)
            return
        end
        local ok, result = BccUtils.RPC:CallAsync('Feather:Banks:CreateSDB', {
            name = sdbName,
            bank = bank.id,
            size = sdbSize,
            payWith = payWith
        })
        if not ok then return end
        Notify(_U("box_created_notify", sdbName), 3000)
        OpenSDBListPage(bank, ParentPage)
    end)
    CreateSDBPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    CreateSDBPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    CreateSDBPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = CreateSDBPage })
end

function OpenSDBInventory(sdb, ParentPage)
    devPrint('[SDB] OpenSDBInventory called. sdb.id=', tostring(sdb and sdb.id), 'type=', type(sdb and sdb.id))
    -- Close the bank menu and explicitly release NUI focus for inventory UI
    FeatherBankMenu:Close()
    SetNuiFocus(false, false)
    devPrint('[SDB] Bank menu closed, focus released; waiting...')
    Wait(250)
    local sdbIdNum = tonumber(sdb and sdb.id)
    devPrint('[SDB] Converting sdb.id to number ->', tostring(sdbIdNum))
    local ok = BccUtils.RPC:CallAsync('Feather:Banks:OpenSDB', { sdb_id = sdbIdNum })
    devPrint('[SDB] RPC Feather:Banks:OpenSDB returned:', tostring(ok))
    if not ok then
        devPrint('[SDB] OpenSDB RPC failed for id=', tostring(sdbIdNum))
        Notify(_U('error_unable_open_sdb') or 'Unable to open Safety Deposit Box.', 'error', 3500)
    else
        devPrint('[SDB] Opened inventory for id=', tostring(sdbIdNum))
    end
end

function OpenSDBAccessMenu(sdb, ParentPage, SDBListPage)
    local AccessPage = FeatherBankMenu:RegisterPage('sdb:page:access:' .. tostring(sdb.id))
    AccessPage:RegisterElement('header', {
        value = _U("sdb_access_header"),
        slot  = 'header'
    })
    AccessPage:RegisterElement('subheader', {
        value = _U("sdb_access_subheader"),
        slot  = 'header'
    })
    AccessPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })
    AccessPage:RegisterElement('button', {
        label = _U("give_access_button"),
        style = {}
    }, function()
        OpenSDBGiveAccessPage(sdb, AccessPage, SDBListPage)
    end)
    AccessPage:RegisterElement('button', {
        label = _U("remove_access_button"),
        style = {}
    }, function()
        OpenSDBRemoveAccessPage(sdb, AccessPage, SDBListPage)
    end)
    AccessPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    AccessPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = 'footer',
        style = {}
    }, function()
        OpenSDBBoxMenu(sdb, ParentPage, SDBListPage)
    end)
    AccessPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = AccessPage })
end

function OpenSDBGiveAccessPage(sdb, ParentPage, SDBListPage)
    local SDBGiveAccessPage = FeatherBankMenu:RegisterPage('sdb:page:access:give:' .. tostring(sdb.id))
    local charId = nil
    local level  = nil
    SDBGiveAccessPage:RegisterElement('header', {
        value = _U("grant_sdb_access_header"),
        slot  = 'header'
    })
    SDBGiveAccessPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })
    SDBGiveAccessPage:RegisterElement('input', {
        label       = _U("character_id_label"),
        placeholder = _U("character_id_placeholder"),
        style       = {}
    }, function(data)
        charId = tonumber(data.value)
    end)
    SDBGiveAccessPage:RegisterElement('input', {
        label       = _U("access_level_label"),
        placeholder = _U("access_level_placeholder"),
        style       = {}
    }, function(data)
        level = tonumber(data.value)
    end)
    SDBGiveAccessPage:RegisterElement('button', {
        label = _U("grant_access_button"),
        style = {}
    }, function()
        if not charId or not level then
            Notify(_U("invalid_char_id_level"), 4000)
            return
        end
        local ok, res = BccUtils.RPC:CallAsync('Feather:Banks:AddSDBAccess', {
            sdb_id   = sdb.id,
            user_src = charId,
            level    = level
        })
        if ok then OpenSDBAccessMenu(sdb, ParentPage, SDBListPage) end
    end)
    SDBGiveAccessPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    SDBGiveAccessPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = 'footer',
        style = {}
    }, function()
        OpenSDBAccessMenu(sdb, ParentPage, SDBListPage)
    end)
    SDBGiveAccessPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = SDBGiveAccessPage })
end

function OpenSDBRemoveAccessPage(sdb, ParentPage, SDBListPage)
    local SDBRemoveAccessPage = FeatherBankMenu:RegisterPage('sdb:page:access:remove:' .. tostring(sdb.id))
    SDBRemoveAccessPage:RegisterElement('header', {
        value = _U("remove_sdb_access_header"),
        slot  = 'header'
    })
    SDBRemoveAccessPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })
    local ok, result = BccUtils.RPC:CallAsync('Feather:Banks:GetSDBAccessList', { sdb_id = sdb.id })
    local accessList = (ok and result and result.access) or {}
    if #accessList == 0 then
        SDBRemoveAccessPage:RegisterElement('textdisplay', {
            value = _U("no_users_access_box"),
            style = { ['text-align'] = 'center' }
        })
    else
        for _, access in ipairs(accessList) do
            local label = '[' .. tostring(access.character_id) .. '] ' ..
                (access.first_name or _U("unknown")) .. ' ' ..
                (access.last_name  or '') .. ' (' ..
                _U("level") .. ' ' .. tostring(access.level) .. ')'
            SDBRemoveAccessPage:RegisterElement('button', {
                label = label,
                style = {}
            }, function()
                local confirmPage = FeatherBankMenu:RegisterPage('sdb:page:access:remove:confirm:' .. access.character_id)
                confirmPage:RegisterElement('header', {
                    value = _U("confirm_remove_access_header"),
                    slot  = 'header'
                })
                confirmPage:RegisterElement('textdisplay', {
                    value = _U("confirm_remove_access_text", label),
                    style = { ['text-align'] = 'center' }
                })
                confirmPage:RegisterElement('button', {
                    label = _U("confirm_remove_button"),
                    style = {}
                }, function()
                    local ok = BccUtils.RPC:CallAsync('Feather:Banks:RemoveSDBAccess', {
                        sdb_id    = sdb.id,
                        character = access.character_id
                    })
                    OpenSDBRemoveAccessPage(sdb, ParentPage, SDBListPage)
                end)
                confirmPage:RegisterElement('button', {
                    label = _U("cancel_button"),
                    style = {}
                }, function()
                    OpenSDBRemoveAccessPage(sdb, ParentPage, SDBListPage)
                end)
                FeatherBankMenu:Open({ startupPage = confirmPage })
            end)
        end
    end
    SDBRemoveAccessPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    SDBRemoveAccessPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = 'footer',
        style = {}
    }, function()
        OpenSDBAccessMenu(sdb, ParentPage, SDBListPage)
    end)
    SDBRemoveAccessPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = SDBRemoveAccessPage })
end
