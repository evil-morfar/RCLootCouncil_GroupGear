-- Author      : Potdisc
-- Custom module - Group Gear
-- core.lua 	Adds a frame showing your groups gear based on the RCLootCouncil framework.

local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
local GroupGear = addon:NewModule("RCGroupGear", "AceComm-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RCLootCouncil")
local ST = LibStub("ScrollingTable")

local ROW_HEIGHT = 20
local num_display_gear = 16

local scrollCols = {
   { name = "",         width = 20,  DoCellUpdate = addon.SetCellClassIcon,},       -- class icon
   { name = L["Name"],  width = 120},                                               -- Player name
--   { name = L["Rank"],  width = 95},                                              -- guild Rank
   { name = L["ilvl"],  width = 55,  align = "CENTER"},                             -- ilvl
   { name = "A. traits",width = 55,  align = "CENTER"},                             -- # of artifact traits
   { name = "Gear",     width = ROW_HEIGHT * num_display_gear + num_display_gear, align = "CENTER" },  -- Gear
   { name = "",         width = 20,  DoCellUpdate = GroupGear.SetCellRefresh,},     -- Refresh icon
}


local registeredPlayers = {} -- names are stored in lowercase for consistency
local db, viewMenuFrame


function GroupGear:OnInitialize()
   self.version = GetAddOnMetadata("RCLootCouncil_GroupGear", "Version")
   local defaults = {
      profile = {
         showMissingGems = true,
         showMissingEnchants = true,
      },
   }

   self.db = LibStub("AceDB-3.0"):New("RCGroupGearDB", defaults, true)
   db = self.db.profile

   viewMenuFrame = CreateFrame("Frame", "RCLootCouncil_GroupGear_ViewMenu", UIParent, "Lib_UIDropDownMenuTemplate")
   Lib_UIDropDownMenu_Initialize(viewMenuFrame, self.ViewMenu, "MENU")
   -- register chat and comms
   self:Enable()
end

function GroupGear:OnEnable()
   addon:Debug("GroupGear", self.version, "enabled")
   -- This changes in rclc v2.5
if addon:VersionCompare(addon.version, "2.5.0") then
   addon:CustomChatCmd(self, "Show", "gg", "groupgear", "gear")
else
   addon:CustomChatCmd(self, "Show", "- gg - Show the GroupGear window (alt. 'groupgear' or 'gear')", "gg", "groupgear", "gear")
end
   self:RegisterComm("RCLootCouncil")
   self.frame = self:GetFrame()
end

function GroupGear:OnDisable()
   self:Hide()
end

function GroupGear:OnCommReceived(prefix, serializedMsg, distri, sender)
   if prefix == "RCLootCouncil" then
      if addon:UnitIsUnit(sender, "player") and not addon.debug then return end -- We handle ourself in the code
      -- data is always a table to be unpacked
      local test, command, data = addon:Deserialize(serializedMsg)
      if addon:HandleXRealmComms(self, command, data, sender) then return end

      if test then
         if command == "groupGearRequest" then
            if distri == "GUILD" then
               addon:SendCommand("guild", "groupGearResponse", self:GetGroupGearInfo())
            else
               addon:SendCommand("group", "groupGearResponse", self:GetGroupGearInfo())
            end
         elseif command == "groupGearResponse" then
            local name, class, guildRank, ilvl, artifactTraits, gear = unpack(data)
            if self:IsPlayerRegistered(name) then
               -- Just readd them, as we have all the needed info
               tremove(self.frame.rows, registeredPlayers[name:lower()])
            end
            self:AddEntry(name, class, guildRank, ilvl, artifactTraits, gear)

         elseif command == "playerInfo" then
            -- We could receive this while we're not running, in which case we'll do nothing
            if not self:IsShown() then return end
            local name, class, _, guildRank, _, _, ilvl = unpack(data)
            if not self:IsPlayerRegistered(name) then -- just add them
               self:AddEntry(name, class, guildRank, ilvl)
            else
               -- They're already registered, so we need to update the values
               self:UpdateEntry(name, ilvl)
            end
         end
      end
   end
end

function GroupGear:Show()
   self.frame = self:GetFrame()
   self.frame:Show()
end

function GroupGear:Hide()
   if self.frame then self.frame:Hide() end
end

function GroupGear:IsShown()
   return self.frame and self.frame:IsVisible()
end

function GroupGear:Query(method)
   self.frame.rows = {}
   registeredPlayers = {}
   -- Add our self
   self:AddEntry(self:GetGroupGearInfo())
   if method == "group" then
      addon:SendCommand("group", "playerInfoRequest")
      addon:SendCommand("group", "groupGearRequest")
   elseif method == "guild" then
      addon:SendCommand("guild", "playerInfoRequest")
      addon:SendCommand("guild", "groupGearRequest")
   end
   self.frame.st:SetData(self.frame.rows, true)
end

function GroupGear:Refresh()
   self.frame.st:SortData()
   -- Calculate total ilvl
   local ilvl, num = 0, 0
   for i = 1, #self.frame.rows do
      if self.frame.rows[i][3].value ~= "Unknown" then
         ilvl = ilvl + self.frame.rows[i][3].value
         num = num + 1
      end
   end
   ilvl = addon.round(ilvl/num, 2)
   self.frame.avgilvl:SetText(ilvl and "Average ilvl: "..ilvl or "")
end

function GroupGear:AddEntry(name, class, guildRank, ilvl, artifactTraits, gear)
   tinsert(self.frame.rows, {
      {args = {class} },
      {value = addon.Ambiguate(name), color = addon:GetClassColor(class)},
   --   {value = guildRank or "Unknown"},
      {value = addon.round(ilvl,2)},
      {value = artifactTraits or "Unknown"},
      {value = "", DoCellUpdate = GroupGear.SetCellGear,    gear = gear},
      {value = "", DoCellUpdate = GroupGear.SetCellRefresh, name = name},
   })
   registeredPlayers[name:lower()] = #self.frame.rows
   self:Refresh()
end

function GroupGear:UpdateEntry(name, ilvl)
   -- We'll assume it's only when player's doesn't have GG installed that updates occur,
   -- so only update ilvl
   -- Find out which row they're at
   local row = registeredPlayers[name:lower()]
   -- And edit the value if we have the data, otherwise keep what we have
   self.frame.rows[row][3].value = ilvl and addon.round(ilvl,2) or self.frame.rows[row][3].value
   self.frame.st:Refresh()
end

-- Function to return everything needed by GroupGear to the requester
function GroupGear:GetGroupGearInfo()
   local name, class, _, guildRank, _, _, ilvl = addon:GetPlayerInfo()
   return name, class, guildRank, ilvl, select(6,C_ArtifactUI.GetEquippedArtifactInfo()), self:GetPlayersGear()
end

-- Returns a table containing the itemStrings of the player's gear
function GroupGear:GetPlayersGear()
   local ret = {}
   for i = 1, 17 do
      if i ~= 4 then -- skip the shirt
         local link = GetInventoryItemLink("player", i)
         --tinsert(ret, addon:GetItemStringFromLink(link))
         tinsert(ret, link)
      end
   end
   return ret
end

function GroupGear:IsPlayerRegistered(name)
   return registeredPlayers[name:lower()] and true
end

function GroupGear.ViewMenu(menu, level)
   if level == 1 then
      local info = Lib_UIDropDownMenu_CreateInfo()
      info.text = "Options"
      info.isTitle = true
      info.notCheckable = true
      info.disabled = true
      Lib_UIDropDownMenu_AddButton(info, level)

      info = Lib_UIDropDownMenu_CreateInfo()
      info.text = "Highlight missing enchants"
      info.checked = db.showMissingEnchants
      info.func = function() db.showMissingEnchants = not db.showMissingEnchants; GroupGear:Refresh() end
      Lib_UIDropDownMenu_AddButton(info, level)

      info.text = "Highlight missing gems"
      info.checked = db.showMissingGems
      info.func = function() db.showMissingGems = not db.showMissingGems; GroupGear:Refresh() end
      Lib_UIDropDownMenu_AddButton(info, level)
   end
end

function GroupGear:GetFrame()
   if self.frame then return self.frame end
   local f = addon:CreateFrame("RCGroupGearFrame", "groupGear", "RCLootCouncil - Group Gear", 250)

   local st = ST:CreateST(scrollCols, 12, ROW_HEIGHT, nil, f.content)
	st.frame:SetPoint("TOPLEFT",f,"TOPLEFT",10,-35)
	f:SetWidth(st.frame:GetWidth()+20)
   f.rows = {}
	f.st = st

   local b1 = addon:CreateButton(L["Guild"], f.content)
   b1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
   b1:SetScript("OnClick", function() self:Query("guild") end)
   f.groupButton = b1

   local b2 = addon:CreateButton(L["Group"], f.content)
   b2:SetPoint("LEFT", b1, "RIGHT", 10, 0)
   b2:SetScript("OnClick", function() self:Query("group") end)
   f.guildButton = b2

   local b3 = addon:CreateButton(L.Close, f.content)
   b3:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
   b3:SetScript("OnClick", function() self:Hide() end)
   f.closeButton = b3

   local b4 = CreateFrame("Button", nil, f.content)
   b4:SetSize(20,20)
   b4:SetPoint("LEFT", b2, "RIGHT",8,0)
   b4:SetNormalTexture("Interface/MINIMAP/TRACKING/None")
   -- b4:SetBackdrop({
   --    bgFile = "Interface/Minimap/UI-Minimap-Background",
   --    --bgFile = "Interface/Minimap/Minimap-TrackingBorder",
   -- })
   b4:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
   b4:SetScript("OnClick", function(self) Lib_ToggleDropDownMenu(1, nil, viewMenuFrame, self, 0, 0) end )
   -- b4.border = b4:CreateTexture()
   -- b4.border:SetTexture("Interface/Minimap/Minimap-TrackingBorder")
   -- b4.border:SetSize(44,44)
   -- b4.border:SetPoint("TOPLEFT", b4, "TOPLEFT", -4,4)
   f.viewButton = b4

   local f1 = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
   f1:SetPoint("LEFT", b4, "RIGHT", 10, 0)
   f1:SetTextColor(1,1,1,1)
   f.avgilvl = f1

   return f
end

function GroupGear.SetCellRefresh(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
   local name = data[realrow][column].name
   local f = frame.btn or CreateFrame("Button", nil, frame)
   f:SetPoint("CENTER", frame, "CENTER")
   f:SetSize(ROW_HEIGHT, ROW_HEIGHT)
   f:SetNormalTexture("Interface/BUTTONS/UI-RotationRight-Button-Up")
   f:SetPushedTexture("Interface/BUTTONS/UI-RotationRight-Button-Down")
   f:SetScript("OnClick", function()
      addon:SendCommand(name, "playerInfoRequest")
      addon:SendCommand(name, "groupGearRequest")
   end)
   f:SetScript("OnEnter", function() addon:CreateTooltip("Refresh")end)
   f:SetScript("OnLeave", function() addon:HideTooltip() end)
   frame.btn = f
end

function GroupGear.SetCellGear(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
   local gear = data[realrow][column].gear
   -- Function to create a frame containing the x num of gear frames
   local function create()
      local f = CreateFrame("Frame", frame:GetName().."GearFrame", frame)
      f:SetPoint("LEFT", frame, "LEFT")
      f:SetSize(ROW_HEIGHT * num_display_gear + num_display_gear, ROW_HEIGHT)
      f.gear = {}
      -- Create the individual pieces' frame
      for i = 1, num_display_gear do
         f.gear[i] = CreateFrame("Button", f:GetName()..i, f)
         if i == 1 then
            f.gear[i]:SetPoint("LEFT", f, "LEFT",0,0)
         else
            f.gear[i]:SetPoint("LEFT", f.gear[i-1], "RIGHT",1,0)
         end
         f.gear[i]:SetSize(ROW_HEIGHT, ROW_HEIGHT)
         f.gear[i]:SetScript("OnLeave", function() addon:HideTooltip() end)

         f.gear[i].overlay = f.gear[i]:CreateTexture(nil, "OVERLAY")
         f.gear[i].overlay:SetSize(ROW_HEIGHT, ROW_HEIGHT)
         f.gear[i].overlay:SetPoint("CENTER",f.gear[i])
         f.gear[i].overlay:SetColorTexture(1,0.1,0.1,0.5)
         f.gear[i].overlay:Hide()

         f.gear[i].ilvl = f.gear[i]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
         f.gear[i].ilvl:SetPoint("BOTTOM")
         f.gear[i].ilvl:SetWidth(25)
         f.gear[i].ilvl:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
         f.gear[i].ilvl:SetText(" ")
      end
      return f
   end
   if not frame.container then frame.container = create() end
   if gear == nil then return frame.container:Hide() end -- Gear might not be received yet
   -- Update icons/tooltips
   for i, gearFrame in ipairs(frame.container.gear) do
      gearFrame:SetScript("OnEnter", function() addon:CreateHypertip(gear[i]) end)
      local _, _, quality, ilvl, _, _, _, _, _, texture = GetItemInfo(gear[i] or "")
      gearFrame:SetNormalTexture(texture)

      gearFrame.ilvl:SetText(ilvl)
      local r,g,b = GetItemQualityColor(quality or 1)
      gearFrame.ilvl:SetTextColor(r,g,b,1)
      GroupGear:ColorizeItemBackdrop(gearFrame, gear[i], i)
   end
   frame.container:Show()
end

local socketsBonusIDs = {
	[563]=true,
	[564]=true,
	[565]=true,
	[572]=true,
	[1808]=true,
}
local enchantsAndGems = {
	[5427]="Ring:Crit:200",
	[5428]="Ring:Haste:200",
	[5429]="Ring:Mastery:200",
	[5430]="Ring:Vers:200",

	[5434]="Cloak:Str:200",
	[5435]="Cloak:Agi:200",
	[5436]="Cloak:Int:200",

	[5467]="Cloak:Str:200",
	[5468]="Cloak:Agi:200",
	[5469]="Cloak:Int:200",

	[5437]="Neck:",
	[5438]="Neck:",
	[5439]="Neck:",
	[5889]="Neck:",
	[5890]="Neck:",
	[5891]="Neck:",

	[130219]="Gem:Crit:150",
	[130220]="Gem:Haste:150",
	[130222]="Gem:Mastery:150",
	[130221]="Gem:Vers:150",

	[151580]="Gem:Crit:200",
	[151583]="Gem:Haste:200",
	[151584]="Gem:Mastery:200",
	[151585]="Gem:Vers:200",

	[130246]="Gem:Str:200",
	[130247]="Gem:Agi:200",
	[130248]="Gem:Int:200",
}


local function HasEnchant(item)
   local enchantID = select(4, addon:DecodeItemLink(item))
   --addon:Debug("EnchantID for", item, "is:", enchantID)
   if not enchantID or enchantID == 0 or enchantID == "" then
      -- TODO Check for real enchants
      return true
   end
end

local function GemCheck(item)
   local _, _, _, _, gemID1, _, _, _, _, _, _,_, _, _, _, _, bonusIDs = addon:DecodeItemLink(item)
   for _,id in ipairs(bonusIDs) do
      if socketsBonusIDs[id] then -- There's a socket
         if not gemID1 or gemID1 == 0 or gemID1 == "" then
            -- TODO Check quality
            return true
         end
      end
   end
end

function GroupGear:ColorizeItemBackdrop(frame, item, slotID, noGGCompensation)
   if not item then return end
   if not noGGCompensation and slotID >= 4 then slotID = slotID + 1 end -- Convert back to the "real" slotID's (we skipped the shirt; 4)
   local colorize = false
   -- Need enchants on: Neck, rings, cloak
   if db.showMissingEnchants and (slotID == 2 or slotID == 11 or slotID == 12 or slotID == 15) then
      colorize = HasEnchant(item) and true or colorize -- retain original value
   end
   -- Gem check
   colorize = db.showMissingGems and GemCheck(item) and true or colorize

   if colorize then frame.overlay:Show() else frame.overlay:Hide() end
end
