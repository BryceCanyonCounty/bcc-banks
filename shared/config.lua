Config                    = {}

-- NPC Options
Config.ShowNPC            = true
Config.SpawnDistance      = 100.0
Config.NPCModel           = "s_m_m_bankclerk_01"

Config.PromptDistance     = 3.0

-- Blip Options
Config.ShowBlips          = true
Config.ShowBlipClosed     = true
Config.BlipColor          = {
  open = "WHITE",
  closed = "RED",
}

Config.Accounts           = {
  MaxAccounts = 5 -- 0 = No Limit
}

Config.SafetyDepositBoxes = {

  MaxBoxes = 5, -- 0 = No Limit

  Sizes = {
    Small = {
      CashPrice       = 100,
      GoldPrice       = 1,
      MaxWeight       = 3,
      IgnoreItemLimit = true, -- Ignore max quantity of items
      BlacklistItems  = {     -- List of item names from the Database (case sensitive)
        'apple'
      }
    },
    Medium = {
      CashPrice       = 500,
      GoldPrice       = 50,
      MaxWeight       = 6,
      IgnoreItemLimit = true, -- Ignore max quantity of items
      BlacklistItems  = {}
    },
    Large = {
      CashPrice = 1500,
      GoldPrice = 150,
      MaxWeight = 15,
      IgnoreItemLimit = true, -- Ignore max quantity of items
      BlacklistItems = {}
    },
  }
}

-- Blip Colors
Config.BlipColors         = {
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

-- Door Hashes 0 = unlocked 1 = locked
Config.Doors              = {
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
}
