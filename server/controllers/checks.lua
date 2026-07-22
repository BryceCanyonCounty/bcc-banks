local function useItem()
    return Config.Checks and Config.Checks.UseItem == true
end

local function checkItemName()
    return (Config.Checks and Config.Checks.ItemName) or 'bank_check'
end

-- Give a check item to a player with check metadata embedded
local function giveCheckItem(src, checkId, amount, issuerFirst, issuerLast, recipientFirst, recipientLast)
    local meta = {
        check_id    = checkId,
        amount      = amount,
        issuer      = issuerFirst .. ' ' .. issuerLast,
        recipient   = recipientFirst .. ' ' .. recipientLast,
        description = ('Check for $%s — to %s %s'):format(tostring(amount), recipientFirst, recipientLast),
    }
    exports.vorp_inventory:addItem(src, checkItemName(), 1, meta, function(result)
        if not result then
            devPrint('[Checks] Warning: failed to give check item to src=', src)
        end
    end)
end

-- Scan player inventory for all bank_check items and return list of {item_id, check_id, metadata}
local function getCheckItemsFromInventory(src)
    local results = {}
    exports.vorp_inventory:getUserInventoryItems(src, function(items)
        if not items then return end
        for _, item in pairs(items) do
            if (item.name or '') == checkItemName() then
                -- metadata may be a JSON string
                local meta = item.metadata
                if type(meta) == 'string' then
                    local ok, parsed = pcall(json.decode, meta)
                    meta = (ok and type(parsed) == 'table') and parsed or {}
                elseif type(meta) ~= 'table' then
                    meta = {}
                end
                if meta.check_id then
                    table.insert(results, {
                        item_id  = item.mainid or item.id,
                        check_id = tostring(meta.check_id),
                        metadata = meta,
                    })
                end
            end
        end
    end)
    return results
end

-- Remove a specific check item by its instance ID
local function removeCheckItem(src, itemId)
    exports.vorp_inventory:subItemById(src, itemId, function(result)
        if not result then
            devPrint('[Checks] Warning: failed to remove check item id=', tostring(itemId))
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
--  Write a check
-- ─────────────────────────────────────────────────────────────
BccUtils.RPC:Register('Feather:Banks:WriteCheck', function(params, cb, src)
    if not (Config.Checks and Config.Checks.Enabled == true) or not IsPlayerNearBank(src) then
        NotifyClient(src, _U('error_not_at_bank'), 'error', 4000)
        cb(false)
        return
    end
    local accountId = NormalizeId(params and params.account)
    local firstName = tostring((params and params.first_name) or ''):match('^%s*(.-)%s*$')
    local lastName  = tostring((params and params.last_name)  or ''):match('^%s*(.-)%s*$')
    local amount    = tonumber(params and params.amount)
    local memo      = tostring((params and params.memo) or '')

    if not accountId or not IsFinitePositiveNumber(amount) or firstName == '' or lastName == '' then
        NotifyClient(src, _U('invalid_check_recipient'), 'error', 4000)
        cb(false)
        return
    end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then cb(false) return end
    local char   = user.getUsedCharacter
    local charId = NormalizeId(char.charIdentifier)

    local access = GetAccountAccess(accountId, charId)
    if access == 0 or access > Config.AccessLevels.Withdraw_Deposit then
        NotifyClient(src, _U('error_insufficient_access'), 'error', 4000)
        cb(false)
        return
    end

    local recipientCharId = GetCharacterByName(firstName, lastName)
    if not recipientCharId then
        NotifyClient(src, _U('invalid_check_recipient'), 'error', 4000)
        cb(false)
        return
    end

    if IdsEqual(charId, recipientCharId) then
        NotifyClient(src, _U('error_invalid_check'), 'error', 4000)
        cb(false)
        return
    end

    local result = CreateCheck(accountId, charId, recipientCharId, amount, memo)

    if not result.status then
        local key = result.message and result.message:find('Insufficient')
            and 'error_insufficient_funds_check'
            or  'error_unable_write_check'
        NotifyClient(src, _U(key), 'error', 4000)
        cb(false)
        return
    end

    -- Physical item mode: give check item to the issuer to hand over in RP
    if useItem() then
        local issuerFirst, issuerLast = GetCharacterName(charId)
        giveCheckItem(
            src,
            result.check_id,
            amount,
            issuerFirst or '?', issuerLast or '?',
            firstName, lastName
        )
    end

    NotifyClient(src, _U('check_written_notify', tostring(amount)), 'success', 4000)
    cb(true)
end)

-- ─────────────────────────────────────────────────────────────
--  Get pending checks for the calling character
--  DB-only mode : query bcc_checks by recipient_character_id
--  Item mode    : scan inventory, validate each check_id in DB
-- ─────────────────────────────────────────────────────────────
BccUtils.RPC:Register('Feather:Banks:GetMyChecks', function(params, cb, src)
    if not (Config.Checks and Config.Checks.Enabled == true) or not IsPlayerNearBank(src) then cb(false, {}) return end
    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then cb(false, {}) return end
    local char   = user.getUsedCharacter
    local charId = NormalizeId(char.charIdentifier)

    if not useItem() then
        local checks = GetPendingChecksForRecipient(charId)
        cb(true, checks)
        return
    end

    -- Item mode: only show checks the player physically holds
    local inventoryItems = getCheckItemsFromInventory(src)
    local found = {}

    for _, entry in ipairs(inventoryItems) do
        local check = GetCheck(entry.check_id)
        if check
            and tostring(check.status) == 'pending'
            and IdsEqual(check.recipient_character_id, charId)
        then
            local iFirst, iLast = GetCharacterName(check.issuer_character_id)
            check.issuer_first      = iFirst or '?'
            check.issuer_last       = iLast  or '?'
            check.inventory_item_id = entry.item_id
            table.insert(found, check)
        end
    end

    cb(true, found)
end)

-- ─────────────────────────────────────────────────────────────
--  Get pending checks issued from an account (for voiding)
-- ─────────────────────────────────────────────────────────────
BccUtils.RPC:Register('Feather:Banks:GetIssuedChecks', function(params, cb, src)
    if not (Config.Checks and Config.Checks.Enabled == true) or not IsPlayerNearBank(src) then cb(false, {}) return end
    local accountId = NormalizeId(params and params.account)
    if not accountId then cb(false, {}) return end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then cb(false, {}) return end
    local char   = user.getUsedCharacter
    local charId = NormalizeId(char.charIdentifier)

    local access = GetAccountAccess(accountId, charId)
    if access == 0 then cb(false, {}) return end

    local checks = GetPendingChecksFromAccount(accountId)
    cb(true, checks)
end)

-- ─────────────────────────────────────────────────────────────
--  Cash a check
-- ─────────────────────────────────────────────────────────────
BccUtils.RPC:Register('Feather:Banks:CashCheck', function(params, cb, src)
    if not (Config.Checks and Config.Checks.Enabled == true) or not IsPlayerNearBank(src) then
        NotifyClient(src, _U('error_not_at_bank'), 'error', 4000)
        cb(false)
        return
    end

    local checkId = params and params.check_id
    if not checkId then
        NotifyClient(src, _U('error_invalid_check'), 'error', 4000)
        cb(false)
        return
    end

    local check = GetCheck(checkId)
    local sourceAccount = check and GetAccount(check.account_id)
    if not sourceAccount or not IsPlayerNearBank(src, sourceAccount.bank_id) then
        NotifyClient(src, _U('error_not_at_bank'), 'error', 4000)
        cb(false)
        return
    end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then cb(false) return end
    local char   = user.getUsedCharacter
    local charId = NormalizeId(char.charIdentifier)

    -- Item mode: verify the player physically holds the check item
    local foundItemId = nil
    if useItem() then
        local inventoryItems = getCheckItemsFromInventory(src)
        for _, entry in ipairs(inventoryItems) do
            if entry.check_id == tostring(checkId) then
                foundItemId = entry.item_id
                break
            end
        end
        if not foundItemId then
            NotifyClient(src, _U('error_invalid_check'), 'error', 4000)
            cb(false)
            return
        end
    end

    if not AcquirePlayerFinancialLock(src) then
        NotifyClient(src, _U('error_financial_operation_busy'), 'error', 4000)
        cb(false)
        return
    end
    local result = CashCheck(checkId, charId)

    if not result.status then
        ReleasePlayerFinancialLock(src)
        local keyMap = {
            already_cashed = 'error_check_already_cashed',
            already_voided = 'error_check_voided',
            not_yours      = 'error_check_not_yours',
        }
        local key = keyMap[result.message] or 'error_invalid_check'
        NotifyClient(src, _U(key), 'error', 4000)
        cb(false)
        return
    end

    local credited = pcall(function() char.addCurrency(0, result.amount) end)
    if not credited then
        MySQL.update.await('UPDATE `bcc_checks` SET `status` = "pending", `cashed_at` = NULL WHERE `id` = ? AND `status` = "cashed"', { checkId })
        ReleasePlayerFinancialLock(src)
        cb(false)
        return
    end

    -- Remove the physical item after a successful cash
    if useItem() and foundItemId then removeCheckItem(src, foundItemId) end
    ReleasePlayerFinancialLock(src)

    NotifyClient(src, _U('check_cashed_notify', tostring(result.amount)), 'success', 4000)
    cb(true, { amount = result.amount })
end)

-- ─────────────────────────────────────────────────────────────
--  Void a check (issuer or account admin, refunds account)
-- ─────────────────────────────────────────────────────────────
BccUtils.RPC:Register('Feather:Banks:VoidCheck', function(params, cb, src)
    if not (Config.Checks and Config.Checks.Enabled == true) or not IsPlayerNearBank(src) then
        NotifyClient(src, _U('error_not_at_bank'), 'error', 4000)
        cb(false)
        return
    end
    local checkId = params and params.check_id
    if not checkId then
        NotifyClient(src, _U('error_invalid_check'), 'error', 4000)
        cb(false)
        return
    end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then cb(false) return end
    local char   = user.getUsedCharacter
    local charId = NormalizeId(char.charIdentifier)

    local result = VoidCheck(checkId, charId)

    if not result.status then
        local key = result.message == 'no_permission'
            and 'error_check_no_permission_void'
            or  'error_invalid_check'
        NotifyClient(src, _U(key), 'error', 4000)
        cb(false)
        return
    end

    NotifyClient(src, _U('check_voided_notify'), 'success', 4000)
    cb(true)
end)

-- ─────────────────────────────────────────────────────────────
--  Usable item registration
--  Double-clicking the bank_check item cashes it directly.
--  Proximity to a bank is enforced server-side.
-- ─────────────────────────────────────────────────────────────
AddEventHandler('Feather:Banks:DatabaseReady', function(checkItemReady)
if checkItemReady and Config.Checks and Config.Checks.Enabled == true and useItem() then
    exports.vorp_inventory:registerUsableItem(checkItemName(), function(data)
    local src = data.source

    if not (Config.Checks and Config.Checks.Enabled == true) then return end

    -- VORP passes the full item as a JSON string under data.item
    local itemObj = {}
    if type(data.item) == 'string' then
        local ok, parsed = pcall(json.decode, data.item)
        itemObj = (ok and type(parsed) == 'table') and parsed or {}
    elseif type(data.item) == 'table' then
        itemObj = data.item
    end

    -- Instance ID is mainid inside the item object
    local itemId = itemObj.mainid or itemObj.id

    -- Metadata is nested inside the item object, also may be a JSON string
    local meta = itemObj.metadata
    if type(meta) == 'string' then
        local ok, parsed = pcall(json.decode, meta)
        meta = (ok and type(parsed) == 'table') and parsed or {}
    elseif type(meta) ~= 'table' then
        meta = {}
    end

    local checkId = meta.check_id

    if not checkId then
        NotifyClient(src, _U('error_invalid_check'), 'error', 4000)
        return
    end

    -- Must be near a bank
    if not IsPlayerNearBank(src) then
        NotifyClient(src, _U('error_check_not_at_bank'), 'error', 4000)
        return
    end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then return end
    local char   = user.getUsedCharacter
    local charId = NormalizeId(char.charIdentifier)

    if not AcquirePlayerFinancialLock(src) then
        NotifyClient(src, _U('error_financial_operation_busy'), 'error', 4000)
        return
    end
    local result = CashCheck(checkId, charId)

    if not result.status then
        ReleasePlayerFinancialLock(src)
        local keyMap = {
            already_cashed = 'error_check_already_cashed',
            already_voided = 'error_check_voided',
            not_yours      = 'error_check_not_yours',
        }
        local key = keyMap[result.message] or 'error_invalid_check'
        NotifyClient(src, _U(key), 'error', 4000)
        return
    end

    local credited = pcall(function() char.addCurrency(0, result.amount) end)
    if not credited then
        MySQL.update.await('UPDATE `bcc_checks` SET `status` = "pending", `cashed_at` = NULL WHERE `id` = ? AND `status` = "cashed"', { checkId })
        ReleasePlayerFinancialLock(src)
        return
    end

    -- Remove the item instance
    exports.vorp_inventory:subItemById(src, itemId, function(removed)
        if not removed then devPrint('[Checks] Warning: failed to remove check item id=', tostring(itemId)) end
    end)
    ReleasePlayerFinancialLock(src)
    NotifyClient(src, _U('check_cashed_notify', tostring(result.amount)), 'success', 4000)
    end, GetCurrentResourceName())
end
end)
