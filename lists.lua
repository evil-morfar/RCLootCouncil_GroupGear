--- Contains the lists used in GroupGear
local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
local GG = addon:GetModule("RCGroupGear")

GG.Lists = {
   gems = {
      --[[ Legion
      [130219] = "rare", --Gem:Crit:150
   	[130220] = "rare", --Gem:Haste:150
   	[130222] = "rare", --Gem:Mastery:150
   	[130221] = "rare", --Gem:Vers:150

   	[151580] = "epic", --Gem:Crit:200
   	[151583] = "epic", --Gem:Haste:200
   	[151584] = "epic", --Gem:Mastery:200
   	[151585] = "epic", --Gem:Vers:200

   	[130246] = "epic", --Gem:Str:200
   	[130247] = "epic", --Gem:Agi:200
   	[130248] = "epic", --Gem:Int:200
]]
-- Battle for Azeroth
      [154126] = "rare", --Gem:Crit:40
      [154127] = "rare", --Gem:Haste:40
      [154128] = "rare", --Gem:Vers:40
      [154129] = "rare", --Gem:Mastery:40

      [153707] = "epic", --Gem:Str:40
      [153708] = "epic", --Gem:Agi:40
      [153709] = "epic", --Gem:Int:40
   },
   enchants = {
      --[[ Legion
      [5423] = "rare", --Ring:Crit:150
      [5424] = "rare", --Ring:Haste:150
      [5425] = "rare", --Ring:Mastery:150
      [5426] = "rare", --Ring:Vers:150

      [5431] = "rare", --Cloak:Str:150
      [5432] = "rare", --Cloak:Agi:150
      [5433] = "rare", --Cloak:Int:150

      [5427] = "epic", --Ring:Crit:200
      [5428] = "epic", --Ring:Haste:200
      [5429] = "epic", --Ring:Mastery:200
      [5430] = "epic", --Ring:Vers:200

      [5434] = "epic", --Cloak:Str:200
      [5435] = "epic", --Cloak:Agi:200
      [5436] = "epic", --Cloak:Int:200

      [5467] = "epic", --Cloak:Str:200
      [5468] = "epic", --Cloak:Agi:200
      [5469] = "epic", --Cloak:Int:200

      [5437] = "epic", --Neck:Claw
      [5438] = "epic", --Neck:Army
      [5439] = "epic", --Neck:Satyr
      [5889] = "epic", --Neck:Hide
      [5890] = "epic", --Neck:Soldier
      [5891] = "epic", --Neck:Priestess

      [5895] = "rare", --Neck:Mastery:200
      [5896] = "rare", --Neck:Vers:200
      [5897] = "rare", --Neck:Haste:200
      [5898] = "rare", --Neck:Crit:200
      ]]

      -- BFA
      [5938] = "rare", --Ring:Crit:27
      [5939] = "rare", --Ring:Haste:27
      [5940] = "rare", --Ring:Mastery:27
      [5941] = "rare", --Ring:Vers:27

      [5942] = "epic", --Ring:Crit:37
      [5943] = "epic", --Ring:Haste:37
      [5944] = "epic", --Ring:Mastery:37
      [5945] = "epic", --Ring:Vers:37

      [5946] = "epic", --Weapon:CoastalSurge
      [5948] = "epic", --Weapon:Siphoning
      [5949] = "epic", --Weapon:TorrentOfElements
      [5950] = "epic", --Weapon:GaleForceStriking

      [5962] = "epic", --Weapon:VersitileNavigation
      [5963] = "epic", --Weapon:QuickNavigation
      [5964] = "epic", --Weapon:MasterfulNavigation
      [5965] = "epic", --Weapon:DeadlyNavigation
      [5966] = "epic", --Weapon:StalwartNavigation
   },
   socketsBonusIDs = {
      [563] =  true,
      [564] =  true,
      [565] =  true,
      [572] =  true,
      [1808] = true,
   },
   enchantSlotIDs = { -- BfA has enchants on: rings, weapon
      [11] = true,
      [12] = true,
      [16] = true,
   },
}
