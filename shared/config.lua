Config = {
	devMode            = true,
	defaultlang        = 'ro_lang',
	Notify             = "feather-menu", ----or use feather-core
	UseBankerBusy      = true,        -- If enabled only 1 person can use the bank at a time

    -- Admin configuration: choose how admin is determined
    Admin = {
        allowConsole  = true,                 -- allow console (src=0)
        useAce        = false,                -- check ACE permission below
        acePermission = 'feather.banks.admin',-- ACE permission name
        command       = 'bankadmin',          -- admin command name
        groups        = { 'admin', 'superadmin' }, -- VORP group names
        jobs          = { 'banker' }               -- VORP job names
    },

    adminGroups        = { 
		'admin', 'superadmin'
    },

    AllowedJobs        = {
		'banker'
    },

	-- https://github.com/femga/rdr3_discoveries/blob/master/Controls/README.md
	PromptSettings     = {
		Distance = 3.0,   -- Distance for the prompt to work
		TellerKey = 0x760A9C6F, -- Letter G
		SDBKey = 0x760A9C6F -- Letter G
	},
	-- NPC Options
	-- Models: https://github.com/femga/rdr3_discoveries/blob/master/peds/peds_list.lua
	NPCSettings        = {
		Show     = true,
		Distance = 100.0,
		Model    = "s_m_m_bankclerk_01",
	},

	-- Blip Options
	BlipSettings       = {
		Show            = true,
		ShowClosed      = true,
		UseDistance     = true,
		Distance        = 100.0,
		Colors          = {
			Open = "WHITE",
			Closed = "RED",
		},

		AvailableColors = {
			LIGHT_BLUE    = "BLIP_MODIFIER_MP_COLOR_1",
			DARK_RED      = "BLIP_MODIFIER_MP_COLOR_2",
			PURPLE        = "BLIP_MODIFIER_MP_COLOR_3",
			ORANGE        = "BLIP_MODIFIER_MP_COLOR_4",
			TEAL          = "BLIP_MODIFIER_MP_COLOR_5",
			LIGHT_YELLOW  = "BLIP_MODIFIER_MP_COLOR_6",
			PINK          = "BLIP_MODIFIER_MP_COLOR_7",
			GREEN         = "BLIP_MODIFIER_MP_COLOR_8",
			DARK_TEAL     = "BLIP_MODIFIER_MP_COLOR_9",
			RED           = "BLIP_MODIFIER_MP_COLOR_10",
			LIGHT_GREEN   = "BLIP_MODIFIER_MP_COLOR_11",
			TEAL2         = "BLIP_MODIFIER_MP_COLOR_12",
			BLUE          = "BLIP_MODIFIER_MP_COLOR_13",
			DARK_PUPLE    = "BLIP_MODIFIER_MP_COLOR_14",
			DARK_PINK     = "BLIP_MODIFIER_MP_COLOR_15",
			DARK_DARK_RED = "BLIP_MODIFIER_MP_COLOR_16",
			GRAY          = "BLIP_MODIFIER_MP_COLOR_17",
			PINKISH       = "BLIP_MODIFIER_MP_COLOR_18",
			YELLOW_GREEN  = "BLIP_MODIFIER_MP_COLOR_19",
			DARK_GREEN    = "BLIP_MODIFIER_MP_COLOR_20",
			BRIGHT_BLUE   = "BLIP_MODIFIER_MP_COLOR_21",
			BRIGHT_PURPLE = "BLIP_MODIFIER_MP_COLOR_22",
			YELLOW_ORANGE = "BLIP_MODIFIER_MP_COLOR_23",
			BLUE2         = "BLIP_MODIFIER_MP_COLOR_24",
			TEAL3         = "BLIP_MODIFIER_MP_COLOR_25",
			TAN           = "BLIP_MODIFIER_MP_COLOR_26",
			OFF_WHITE     = "BLIP_MODIFIER_MP_COLOR_27",
			LIGHT_YELLOW2 = "BLIP_MODIFIER_MP_COLOR_28",
			LIGHT_PINK    = "BLIP_MODIFIER_MP_COLOR_29",
			LIGHT_RED     = "BLIP_MODIFIER_MP_COLOR_30",
			LIGHT_YELLOW3 = "BLIP_MODIFIER_MP_COLOR_31",
			WHITE         = "BLIP_MODIFIER_MP_COLOR_32",
		}
	},

	-- Access Level Options
	AccessLevels       = {
		Admin = 1,      -- Can grant access to other people
		Withdraw_Deposit = 2, -- Can Withdraw and Deposit Funds
		Deposit = 3,    -- Can Only Deposit
		ReadOnly = 4,   -- Can Only See balances
	},

	-- Gold Exchange Options
	GoldExchange       = {
		Enabled          = true,
		-- Dollar price per 1.00 gold unit
		BuyPricePerGold  = 250.0,
		SellPricePerGold = 180.0,
		-- Inventory item -> gold currency exchange
		GoldBarItemName  = 'goldbar',   -- item name in inventory
		GoldBarToGold    = 1.0,         -- how much gold currency per 1 goldbar item
		GoldBarFeePercent = 10.0,       -- fee percent taken when exchanging gold bars to gold
	},

	-- Transfers
	Transfer           = {
		Enabled = true,
		-- Applies only when source and destination banks differ
		CrossBankFeePercent = 2.0, -- small configurable fee percentage
	},

	-- Bank Account Options
	Accounts           = {
		MaxAccounts = 5 -- 0 = No Limit
	},

	-- Loan timing & reminders
	LoanTiming = {
		DaysUntilDefault = 10, -- Number of in-game days (weathersync cycles) before a loan defaults
		DailyReminders = {
			Enabled = true,            -- Send daily reminders while a balance remains
			SendMailbox = true,        -- Deliver a mail via bcc-mailbox
			NotifyOnline = true,       -- Pop an on-screen notification for borrowers that are online
			MailFrom = 'Bank Postmaster', -- Display name for system mail
			MailSubject = 'Loan Payment Reminder', -- string.format with (elapsedDays, dueDays, loanId, outstanding)
			MailBody = 'Day %d of %d for your loan #%s. Outstanding balance: $%s. Please visit the bank to avoid default.',
			NotifyMessage = 'Your bank loan is still outstanding. Visit a bank today to make a payment.'
		}
	},

	-- Safety Deposit Box Options
	SafetyDepositBoxes = {

		MaxBoxes = 5, -- 0 = No Limit

		Sizes = {
			Small = {
				CashPrice       = 100,
				GoldPrice       = 1,
				MaxWeight       = 100,
				IgnoreItemLimit = true, -- Ignore max quantity of items
				BlacklistItems  = { -- List of item names from the Database (case sensitive)
					'apple'
				}
			},
			Medium = {
				CashPrice       = 500,
				GoldPrice       = 5,
				MaxWeight       = 500,
				IgnoreItemLimit = true, -- Ignore max quantity of items
				BlacklistItems  = {}
			},
			Large = {
				CashPrice = 1500,
				GoldPrice = 15,
				MaxWeight = 1500,
				IgnoreItemLimit = true, -- Ignore max quantity of items
				BlacklistItems = {}
			},
		}
	},

	-- Door Lock Settings (0 = unlocked, 1 = locked)
	Doors              = {
		[2642457609] = 0, -- Valentine bank, front entrance, left door
		[3886827663] = 0, -- Valentine bank, front entrance, right door
		[1340831050] = 1, -- Valentine bank, gate to tellers
		[576950805]  = 1, -- Valentine bank, vault door
		[3718620420] = 1, -- Valentine bank, door behind tellers
		[2343746133] = 1, -- Valentine bank, door to backrooms
		[2307914732] = 1, -- Valentine bank, back door
		[334467483]  = 1, -- Valentine bank, door to hall in vault antechamber

		[1733501235] = 0, -- Saint Denis bank, west entrance, right door
		[2158285782] = 0, -- Saint Denis bank, west entrance, left door
		[1634115439] = 1, -- Saint Denis bank, manager's office, right door
		[965922748]  = 1, -- Saint Denis bank, manager's office, left door
		[2817024187] = 1, -- Saint Denis bank, north entrance, left door
		[2089945615] = 1, -- Saint Denis bank, north entrance, right door
		[1751238140] = 1, -- Saint Denis bank, vault

		[531022111]  = 0, -- Blackwater bank, entrance
		[2817192481] = 1, -- Blackwater bank, office
		[2117902999] = 1, -- Blackwater bank, teller gate
		[1462330364] = 1, -- Blackwater bank, vault

		[3317756151] = 0, -- Rhodes bank, front entrance, left door
		[3088209306] = 0, -- Rhodes bank, front entrance, right door
		[2058564250] = 1, -- Rhodes bank, door to backrooms
		[1634148892] = 1, -- Rhodes bank, teller gate
		[3483244267] = 1, -- Rhodes bank, vault
		[3142122679] = 1, -- Rhodes bank, back entrance
	},

	-- Lockpicking settings for bank doors
	LockPicking = {
		Enabled = true,              -- Enable lockpicking for configured bank doors
		Resource = 'lockpick',       -- Minigame resource at `resources/[OTHER]/lockpick`
		Attempts = 3,               -- How many attempts the minigame provides
		PromptKey = 0xCEFD9220,     -- Default: Key "E" (same as bcc-doorlocks)
		Radius = 1.6,               -- Distance to door center to show prompt
		RelockSeconds = 0,          -- Optional: re-lock after N seconds (0 = never)
		NotifyOnMissing = true,     -- Notify if lockpick resource is missing
		RequireItem = false,        -- If true, checks for item before minigame
		ItemName = 'lockpick',      -- Item to check in vorp_inventory

		-- Durability handling like mms-robbery
		Durability = {
			Enabled = true,          -- If true, reduce durability on fail; else fallback destroy optionally
			Max = 100,               -- Max durability when no metadata present
			DamageOnFail = 25,       -- Durability lost per failed attempt
			DestroyOnFailIfDisabled = true -- If durability disabled, remove one lockpick on fail
		}
	}
}
