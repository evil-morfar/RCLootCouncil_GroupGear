--- Contains the lists used in GroupGear
local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
local GG = addon:GetModule("RCGroupGear")

GG.Lists = {
   gems = {
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
   },
   enchants = {
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
   },
   socketsBonusIDs = {
      [563] =  true,
      [564] =  true,
      [565] =  true,
      [572] =  true,
      [1808] = true,
   },
   enchantSlotIDs = { -- Legion has enchants on: Neck, rings, cloak
      [2]  = true,
      [11] = true,
      [12] = true,
      [15] = true,
   },
}
