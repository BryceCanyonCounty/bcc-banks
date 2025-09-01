function OpenSDBListPage(bank, ParentPage)
    local Page = FeatherBankMenu:RegisterPage('bank:page:sdb:list:' .. tostring(bank.id))

    Page:RegisterElement('header', { value = 'Safety Deposit Boxes', slot = "header" })
    Page:RegisterElement('subheader', { value = "Your boxes at this bank", slot = "header" })
    Page:RegisterElement('line', { slot = "header", style = {} })

    local ok, boxes = Feather.RPC.CallAsync('Feather:Banks:GetSDBs', { bank = bank.id })
    if not ok or not boxes or #boxes == 0 then
        Page:RegisterElement('textdisplay', { value = "No boxes found.", slot = "content" })
    else
        for _, box in ipairs(boxes) do
            local label = (box.name or ("Box #" .. tostring(box.id)))
            Page:RegisterElement('button', { label = label, style = {} }, function()
                OpenSDBInventory(box, Page)
            end)
        end
    end

    Page:RegisterElement('line', { style = {} })
    Page:RegisterElement('button', { label = "Create New Box", style = {} }, function()
        OpenCreateSDBPage(bank, Page)
    end)

    Page:RegisterElement('line', { slot = "footer", style = {} })
    Page:RegisterElement('button', {
        label = "Back",
        slot  = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    Page:RegisterElement('bottomline', { slot = "footer", style = {} })

    FeatherBankMenu:Open({ startupPage = Page })
end

function OpenCreateSDBPage(bank, ParentPage)
    local Page = FeatherBankMenu:RegisterPage('bank:page:sdb:create:' .. tostring(bank.id))

    Page:RegisterElement('header', { value = 'Create Safety Deposit Box', slot = "header" })
    Page:RegisterElement('subheader', { value = "Name and choose a size", slot = "header" })
    Page:RegisterElement('line', { slot = "header", style = {} })

    local sdbName = ''
    local sdbSize = nil

    Page:RegisterElement('input', {
        label       = "Box Name",
        placeholder = "e.g. Family Heirlooms",
        style       = {}
    }, function(data)
        sdbName = data.value
    end)

    Page:RegisterElement('line', { style = {} })
    Page:RegisterElement('textdisplay', { value = "Select a Size:", slot = "content" })

    Page:RegisterElement('button', { label = "Small", style = {} }, function()
        sdbSize = "Small"; Feather.Notify.RightNotify("Selected Small", 2000)
    end)
    Page:RegisterElement('button', { label = "Medium", style = {} }, function()
        sdbSize = "Medium"; Feather.Notify.RightNotify("Selected Medium", 2000)
    end)
    Page:RegisterElement('button', { label = "Large", style = {} }, function()
        sdbSize = "Large"; Feather.Notify.RightNotify("Selected Large", 2000)
    end)

    Page:RegisterElement('line', { style = {} })
    Page:RegisterElement('button', { label = "Create Box", style = {} }, function()
        if not sdbName or sdbName == "" then
            Feather.Notify.RightNotify("Enter a box name.", 3000)
            return
        end
        if not sdbSize then
            Feather.Notify.RightNotify("Select a size.", 3000)
            return
        end

        local ok, result = Feather.RPC.CallAsync('Feather:Banks:CreateSDB', {
            name = sdbName, bank = bank.id, size = sdbSize
        })

        if not ok then
            local msg = (result and result.message) and result.message or "Failed to create box."
            Feather.Notify.RightNotify(msg, 4000)
            return
        end

        Feather.Notify.RightNotify("Box created: " .. sdbName, 3000)
        OpenSDBListPage(bank, ParentPage)
    end)

    Page:RegisterElement('line', { slot = "footer", style = {} })
    Page:RegisterElement('button', { label = "Back", slot = "footer", style = {} }, function()
        ParentPage:RouteTo()
    end)
    Page:RegisterElement('bottomline', { slot = "footer", style = {} })

    FeatherBankMenu:Open({ startupPage = Page })
end

function OpenSDBInventory(sdb, ParentPage)
    local ok, data = Feather.RPC.CallAsync('Feather:Banks:OpenSDB', { sdb_id = tonumber(sdb.id) })
    if not ok then
        local msg = (data and data.message) and data.message or "Unable to open box."
        Feather.Notify.RightNotify(msg, 4000)
        return
    end
    FeatherBankMenu:Close()
end
