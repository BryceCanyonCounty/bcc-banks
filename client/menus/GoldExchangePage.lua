function OpenGoldExchangePage(bank, ParentPage)
    local GoldExchangePage = FeatherBankMenu:RegisterPage('bank:page:gold:' .. tostring(bank.id))

    local ok, rates = BccUtils.RPC:CallAsync('Feather:Banks:GetGoldRates', {})
    rates = rates or { buy = 10.0, sell = 9.0 }

    local function round2(n)
        n = tonumber(n) or 0
        return math.floor(n * 100 + 0.5) / 100
    end

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

    GoldExchangePage:RegisterElement('header', {
        value = _U("gold_services_header"),
        slot  = "header"
    })

    GoldExchangePage:RegisterElement('subheader', {
        value = _U("gold_services_subheader"),
        slot  = "header"
    })

    GoldExchangePage:RegisterElement('textdisplay', {
        value = _U('gold_rates_label', toFixed(rates.buy, 2), toFixed(rates.sell, 2)),
        slot  = 'header'
    })

    GoldExchangePage:RegisterElement('line', {
        slot  = "header",
        style = {}
    })

    -- Buy flow: enter GOLD amount to purchase (cash auto-calculated)
    local buyGoldValue = ''
    GoldExchangePage:RegisterElement('input', {
        label       = _U("gold_amount_label"),
        placeholder = _U("gold_amount_placeholder"),
        style       = {}
    }, function(data)
        buyGoldValue = data.value
    end)

    GoldExchangePage:RegisterElement('button', {
        label = _U("buy_with_cash_button"),
        style = {}
    }, function()
        local goldAmt = tonumber(buyGoldValue)
        if not goldAmt or goldAmt <= 0 then
            Notify(_U("invalid_gold_amount"), 4000)
            return
        end
        local cashAmt = round2((rates.buy or 0) * goldAmt)
        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:gold:confirm:buyg:' .. tostring(goldAmt))
        ConfirmPage:RegisterElement('header', {
            value = _U('gold_confirm_header'),
            slot  = 'header'
        })
        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('gold_confirm_buy_gold', toFixed(goldAmt, 2), toFixed(cashAmt, 2)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            BccUtils.RPC:CallAsync('Feather:Banks:BuyGold', { gold = goldAmt })
            OpenGoldExchangePage(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', {
            slot  = 'footer',
            style = {}
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenGoldExchangePage(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    GoldExchangePage:RegisterElement('line', { style = {} })

    local sellGoldValue = ''
    GoldExchangePage:RegisterElement('input', {
        label       = _U("gold_amount_label"),
        placeholder = _U("gold_amount_placeholder"),
        style       = {}
    }, function(data)
        sellGoldValue = data.value
    end)

    GoldExchangePage:RegisterElement('button', {
        label = _U("sell_for_cash_button"),
        style = {}
    }, function()
        local goldAmt = tonumber(sellGoldValue)
        if not goldAmt or goldAmt <= 0 then
            Notify(_U("invalid_gold_amount"), 4000)
            return
        end
        local cashAmt = round2(goldAmt * (rates.sell or 0))
        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:gold:confirm:sellg:' .. tostring(goldAmt))
        ConfirmPage:RegisterElement('header', {
            value = _U('gold_confirm_header'),
            slot  = 'header'
        })
        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('gold_confirm_sell_gold', toFixed(goldAmt, 2), toFixed(cashAmt, 2)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            BccUtils.RPC:CallAsync('Feather:Banks:SellGold', { gold = goldAmt })
            OpenGoldExchangePage(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', {
            slot  = 'footer',
            style = {}
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenGoldExchangePage(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    GoldExchangePage:RegisterElement('line', { style = {} })

    GoldExchangePage:RegisterElement('subheader', {
        value = _U('goldbars_section_header'),
    })

    local goldBarCount = ''
    GoldExchangePage:RegisterElement('input', {
        label       = _U('goldbars_count_label'),
        placeholder = _U('goldbars_count_placeholder'),
        style       = {}
    }, function(data)
        goldBarCount = data.value
    end)

    GoldExchangePage:RegisterElement('button', {
        label = _U('goldbars_redeem_button'),
        style = {}
    }, function()
        local count = tonumber(goldBarCount)
        if not count or count <= 0 then
            Notify(_U('error_invalid_goldbar_count'), 4000)
            return
        end
        local perBar = (Config and Config.GoldExchange and Config.GoldExchange.GoldBarToGold) or 1.0
        local feePct = (Config and Config.GoldExchange and Config.GoldExchange.GoldBarFeePercent) or 0
        local gross = (tonumber(count) or 0) * perBar
        local net = round2(gross * (1 - (feePct / 100)))

        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:gold:confirm:bars:' .. tostring(count))
        ConfirmPage:RegisterElement('header', {
            value = _U('gold_confirm_header'),
            slot  = 'header'
        })
        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('goldbars_confirm_text', toFixed(count, 0), toFixed(net, 2), toFixed(feePct, 2)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            BccUtils.RPC:CallAsync('Feather:Banks:ExchangeGoldBars', { count = count })
            OpenGoldExchangePage(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', {
            slot  = 'footer',
            style = {}
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenGoldExchangePage(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    GoldExchangePage:RegisterElement('line', {
        slot  = "footer",
        style = {}
    })

    GoldExchangePage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)

    GoldExchangePage:RegisterElement('bottomline', {
        slot  = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = GoldExchangePage })
end
