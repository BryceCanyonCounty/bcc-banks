function OpenGoldExchangePage(bank, ParentPage)
    local GoldExchangePage = FeatherBankMenu:RegisterPage('bank:page:gold:' .. tostring(bank.id))

    GoldExchangePage:RegisterElement('header', {
        value = 'Gold Services', slot = "header"
    })
    GoldExchangePage:RegisterElement('subheader', {
        value = "Buy, Sell, or Exchange Gold", slot = "header"
    })
    GoldExchangePage:RegisterElement('line', {
        slot = "header", style = {}
    })

    GoldExchangePage:RegisterElement('button', {
        label = "Buy Gold", style = {}
    }, function()
        Feather.Notify.RightNotify("TODO: Implement Buy Gold flow", 3000)
    end)

    GoldExchangePage:RegisterElement('button', {
        label = "Sell Gold", style = {}
    }, function()
        Feather.Notify.RightNotify("TODO: Implement Sell Gold flow", 3000)
    end)

    GoldExchangePage:RegisterElement('button', {
        label = "Exchange Cash ⇄ Gold", style = {}
    }, function()
        Feather.Notify.RightNotify("TODO: Implement Exchange flow", 3000)
    end)

    GoldExchangePage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })
    GoldExchangePage:RegisterElement('button', {
        label = "Back",
        slot  = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    GoldExchangePage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = GoldExchangePage })
end
