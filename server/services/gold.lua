-- Server-side RPCs for Gold Exchange (buy/sell)

local function getRates()
    local cfg = Config and Config.GoldExchange or {}
    local buy = tonumber(cfg.BuyPricePerGold) or 10.0 -- dollars per 1 gold
    local sell = tonumber(cfg.SellPricePerGold) or 9.0 -- dollars per 1 gold
    return buy, sell
end

local function roundTo(value, decimals)
    local power = 10 ^ (decimals or 2)
    return math.floor((value * power) + 0.5) / power
end

BccUtils.RPC:Register('Feather:Banks:GetGoldRates', function(params, cb, src)
    local buy, sell = getRates()
    cb(true, { buy = buy, sell = sell })
end)

-- params: { gold = number } OR { cash = number }
-- If gold provided: buy that much gold.
-- If cash provided: convert all cash to gold at buy rate.
BccUtils.RPC:Register('Feather:Banks:BuyGold', function(params, cb, src)
    devPrint('BuyGold RPC called. src=', src, 'params=', params)

    local user = VORPcore.getUser(src)
    if not user then
        devPrint('BuyGold: invalid player/char')
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint('BuyGold: invalid player/char')
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        cb(false)
        return
    end

    local buyRate = select(1, getRates())

    local gold = tonumber(params and params.gold)
    local cash = tonumber(params and params.cash)

    if (not gold or gold <= 0) and (not cash or cash <= 0) then
        NotifyClient(src, _U('error_invalid_gold_or_cash_amount'), 'error', 4000)
        cb(false)
        return
    end

    if not gold and cash then
        gold = cash / buyRate
    end

    gold = roundTo(gold or 0, 2)
    if gold <= 0 then
        NotifyClient(src, _U('error_amount_zero'), 'error', 4000)
        cb(false)
        return
    end

    local cost = roundTo(gold * buyRate, 2)
    local currentDollars = tonumber(char.money) or 0

    devPrint('BuyGold: gold=', gold, 'cost=', cost, 'wallet=$', currentDollars)

    if currentDollars < cost then
        NotifyClient(src, _U('error_not_enough_cash_purchase'), 'error', 4000)
        cb(false)
        return
    end

    char.removeCurrency(0, cost)
    char.addCurrency(1, gold)

    NotifyClient(src, _U('success_purchased_gold_for_cash', tostring(gold), tostring(cost)), 'success', 4000)
    cb(true, { gold = gold, cost = cost })
end)

-- params: { gold = number } OR { cash = number }
-- If gold provided: sell that much gold.
-- If cash provided: sell enough gold to receive that much cash.
BccUtils.RPC:Register('Feather:Banks:SellGold', function(params, cb, src)
    devPrint('SellGold RPC called. src=', src, 'params=', params)

    local user = VORPcore.getUser(src)
    if not user then
        devPrint('SellGold: invalid player/char')
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint('SellGold: invalid player/char')
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        cb(false)
        return
    end

    local _, sellRate = getRates()

    local gold = tonumber(params and params.gold)
    local cash = tonumber(params and params.cash)

    if (not gold or gold <= 0) and (not cash or cash <= 0) then
        NotifyClient(src, _U('error_invalid_gold_or_cash_amount'), 'error', 4000)
        cb(false)
        return
    end

    if not gold and cash then
        gold = cash / sellRate
    end

    gold = roundTo(gold or 0, 2)
    if gold <= 0 then
        NotifyClient(src, _U('error_amount_zero'), 'error', 4000)
        cb(false)
        return
    end

    local proceeds = roundTo(gold * sellRate, 2)
    local currentGold = tonumber(char.gold) or 0

    devPrint('SellGold: gold=', gold, 'proceeds=$', proceeds, 'wallet gold=', currentGold)

    if currentGold < gold then
        NotifyClient(src, _U('error_not_enough_gold_to_sell'), 'error', 4000)
        cb(false)
        return
    end

    char.removeCurrency(1, gold)
    char.addCurrency(0, proceeds)

    NotifyClient(src, _U('success_sold_gold_for_cash', tostring(gold), tostring(proceeds)), 'success', 4000)
    cb(true, { gold = gold, cash = proceeds })
end)

-- Exchange inventory gold bar items into gold currency
-- params: { count = number }
BccUtils.RPC:Register('Feather:Banks:ExchangeGoldBars', function(params, cb, src)
    devPrint('ExchangeGoldBars RPC called. src=', src, 'params=', params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint('ExchangeGoldBars: invalid user/char')
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter

    local count = tonumber(params and params.count) or 0
    if count <= 0 then
        NotifyClient(src, _U('error_invalid_goldbar_count'), 'error', 4000)
        cb(false)
        return
    end

    local itemName = (Config.GoldExchange and Config.GoldExchange.GoldBarItemName) or 'goldbar'
    local perBarGold = (Config.GoldExchange and Config.GoldExchange.GoldBarToGold) or 1.0
    local feePercent = (Config.GoldExchange and Config.GoldExchange.GoldBarFeePercent) or 0

    local Inv = exports.vorp_inventory:vorp_inventoryApi()
    local had = Inv.getItemCount(src, itemName, nil) or 0
    if had < count then
        NotifyClient(src, _U('error_not_enough_goldbars'), 'error', 4000)
        cb(false)
        return
    end

    Inv.subItem(src, itemName, count)
    local grossGold = perBarGold * count
    local netGold = roundTo(grossGold * (1 - (feePercent / 100)), 2)
    if netGold < 0 then netGold = 0 end
    char.addCurrency(1, netGold)

    local function toFixed(n, decimals)
        n = tonumber(n) or 0
        local mult = 10 ^ (decimals or 0)
        local v = math.floor(n * mult + 0.5) / mult
        local s = tostring(v)
        if decimals and decimals > 0 then
            local dot = string.find(s, '.', 1, true)
            if not dot then
                s = s .. '.' .. string.rep('0', decimals)
            else
                local places = #s - dot
                if places < decimals then
                    s = s .. string.rep('0', decimals - places)
                end
            end
        end
        return s
    end
    NotifyClient(src, _U('success_exchanged_goldbars', tostring(count), toFixed(netGold, 2)), 'success', 4000)
    cb(true, { gold = netGold, fee = feePercent })
end)
