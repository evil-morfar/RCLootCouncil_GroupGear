--- Contains the lists used in GroupGear
local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
local GG = addon:GetModule("RCGroupGear")

GG.Lists = {
   gems = {
-- Battle for Azeroth
      [154126] = "rare", --Gem:Crit:40
      [154127] = "rare", --Gem:Haste:40
      [154128] = "rare", --Gem:Vers:40
      [154129] = "rare", --Gem:Mastery:40

      -- [153707] = "epic", --Gem:Str:80
      -- [153708] = "epic", --Gem:Agi:80
      -- [153709] = "epic", --Gem:Int:80

      -- Patch 8.2
      [153707] = "rare", --Gem:Str:80
      [153708] = "rare", --Gem:Agi:80
      [153709] = "rare", --Gem:Int:80

      [169220] = "rare", --Gem:Spd:5%

      [168639] = "epic", --Gem:Crit:60
      [168640] = "epic", --Gem:Mastery:60
      [168641] = "epic", --Gem:Haste:60
      [168642] = "epic", --Gem:Vers:60

      [168636] = "epic", --Gem:Str:120
      [168637] = "epic", --Gem:Agi:120
      [168638] = "epic", --Gem:Int:120

   },
   enchants = {
      -- BFA
      [5938] = "rare", --Ring:Crit:27
      [5939] = "rare", --Ring:Haste:27
      [5940] = "rare", --Ring:Mastery:27
      [5941] = "rare", --Ring:Vers:27

      -- [5942] = "epic", --Ring:Crit:37
      -- [5943] = "epic", --Ring:Haste:37
      -- [5944] = "epic", --Ring:Mastery:37
      -- [5945] = "epic", --Ring:Vers:37
      --
      -- [5946] = "epic", --Weapon:CoastalSurge
      -- [5948] = "epic", --Weapon:Siphoning
      -- [5949] = "epic", --Weapon:TorrentOfElements
      -- [5950] = "epic", --Weapon:GaleForceStriking
      --
      -- [5962] = "epic", --Weapon:VersitileNavigation
      -- [5963] = "epic", --Weapon:QuickNavigation
      -- [5964] = "epic", --Weapon:MasterfulNavigation
      -- [5965] = "epic", --Weapon:DeadlyNavigation
      -- [5966] = "epic", --Weapon:StalwartNavigation

      -- Patch 8.2
      [5942] = "rare", --Ring:Crit:37
      [5943] = "rare", --Ring:Haste:37
      [5944] = "rare", --Ring:Mastery:37
      [5945] = "rare", --Ring:Vers:37

      [5946] = "rare", --Weapon:CoastalSurge
      [5948] = "rare", --Weapon:Siphoning
      [5949] = "rare", --Weapon:TorrentOfElements
      [5950] = "rare", --Weapon:GaleForceStriking

      [5962] = "rare", --Weapon:VersitileNavigation
      [5963] = "rare", --Weapon:QuickNavigation
      [5964] = "rare", --Weapon:MasterfulNavigation
      [5965] = "rare", --Weapon:DeadlyNavigation
      [5966] = "rare", --Weapon:StalwartNavigation

      [6108] = "epic", --Ring:Crit:60
      [6109] = "epic", --Ring:Haste:60
      [6110] = "epic", --Ring:Mastery:60
      [6111] = "epic", --Ring:Vers:60

      [6112] = "epic", --Weapon:Machinist'sBrilliance
      [6148] = "epic", --Weapon:ForceMultiplier
      [6149] = "epic", --Weapon:OceanicRestoration
      [6150] = "epic", --Weapon:NagaHide

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
