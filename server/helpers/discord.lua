BccBanksInternal = BccBanksInternal or {}

local function getWebhookLink()
    local webhook = Config and (Config.WebhookLink or Config.Webhook) or nil
    if type(webhook) ~= 'string' then return nil end
    webhook = webhook:gsub('^%s+', ''):gsub('%s+$', '')
    if webhook == '' then return nil end
    return webhook
end

local function discordEnabled()
    return BccUtils and BccUtils.Discord and getWebhookLink() ~= nil
end

local function getCharacterRecord(charIdentifier)
    local id = tonumber(charIdentifier)
    if not id then return nil end
    local rows = MySQL.query.await('SELECT firstname, lastname FROM `characters` WHERE `charidentifier` = ? LIMIT 1', { id })
    return rows and rows[1] or nil
end

local function getPlayerLogContext(src)
    local ctx = {
        src = src,
        playerName = GetPlayerName(src) or ('src ' .. tostring(src)),
        charId = nil,
        firstName = 'Unknown',
        lastName = '',
    }

    if not VORPcore or not src then
        return ctx
    end

    local user = VORPcore.getUser(src)
    local char = user and user.getUsedCharacter or nil
    if not char then
        return ctx
    end

    ctx.charId = tonumber(char.charIdentifier) or char.charIdentifier
    ctx.firstName = char.firstname or ctx.firstName
    ctx.lastName = char.lastname or ctx.lastName

    if (ctx.firstName == 'Unknown' or ctx.firstName == nil) and ctx.charId then
        local row = getCharacterRecord(ctx.charId)
        if row then
            ctx.firstName = row.firstname or ctx.firstName
            ctx.lastName = row.lastname or ctx.lastName
        end
    end

    return ctx
end

local function getCharacterNameById(charIdentifier)
    local row = getCharacterRecord(charIdentifier)
    if not row then
        return 'Unknown'
    end
    local fullName = ((row.firstname or '') .. ' ' .. (row.lastname or '')):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if fullName == '' then
        return 'Unknown'
    end
    return fullName
end

local function getBankName(bankId)
    if bankId == nil or bankId == '' then return 'Unknown' end
    local rows = MySQL.query.await('SELECT `name` FROM `bcc_banks` WHERE `id` = ? LIMIT 1', { tostring(bankId) })
    local row = rows and rows[1] or nil
    return (row and row.name) or tostring(bankId)
end

local function getAccountSummary(accountId)
    if accountId == nil or accountId == '' then return nil end
    local rows = MySQL.query.await(
        'SELECT `id`, `name`, `account_number`, `bank_id`, `owner_id`, `cash`, `gold` FROM `bcc_accounts` WHERE `id` = ? LIMIT 1',
        { tostring(accountId) }
    )
    return rows and rows[1] or nil
end

local function getSDBSummary(sdbId)
    if sdbId == nil or sdbId == '' then return nil end
    local rows = MySQL.query.await(
        'SELECT `id`, `name`, `bank_id`, `owner_id`, `size` FROM `bcc_safety_deposit_boxes` WHERE `id` = ? LIMIT 1',
        { tostring(sdbId) }
    )
    return rows and rows[1] or nil
end

local function appendActorLines(lines, src)
    local ctx = getPlayerLogContext(src)
    lines[#lines + 1] = '**Player:** `' .. tostring(ctx.playerName or 'Unknown') .. '`'
    lines[#lines + 1] = '**Character:** `' .. tostring(((ctx.firstName or 'Unknown') .. ' ' .. (ctx.lastName or '')):gsub('%s+', ' '):gsub('%s+$', '')) .. '`'
    lines[#lines + 1] = '**Char ID:** `' .. tostring(ctx.charId or 'Unknown') .. '`'
    lines[#lines + 1] = '**Source:** `' .. tostring(src or 'Unknown') .. '`'
end

function SendBankDiscordLog(title, lines, color)
    if not discordEnabled() then
        return false
    end

    local description = table.concat(lines or {}, '\n')
    local embed = {{
        color = color or 3447003,
        title = title or 'BCC-Banks',
        description = description
    }}

    BccUtils.Discord.sendMessage(
        getWebhookLink(),
        Config.WebhookTitle or 'BCC-Banks',
        Config.WebhookAvatar or '',
        title or 'BCC-Banks',
        nil,
        embed
    )
    return true
end

BccBanksInternal.getPlayerLogContext = getPlayerLogContext
BccBanksInternal.getCharacterNameById = getCharacterNameById
BccBanksInternal.getBankName = getBankName
BccBanksInternal.getAccountSummary = getAccountSummary
BccBanksInternal.getSDBSummary = getSDBSummary
BccBanksInternal.appendActorLines = appendActorLines
