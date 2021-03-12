-- Author      : Potdisc
-- Custom module - Group Gear
-- core.lua 	Adds a frame showing your groups gear based on the RCLootCouncil framework.

local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
GroupGear = addon:NewModule("RCGroupGear", "AceComm-3.0", "AceConsole-3.0", "AceTimer-3.0")
-- local L = LibStub("AceLocale-3.0"):GetLocale("RCLootCouncil")
local ST = LibStub("ScrollingTable")

--- @type Services.Comms
local Comms = addon.Require "Services.Comms"
--- @type Data.Player
local Player = addon.Require "Data.Player"

local ROW_HEIGHT = 20
local num_display_gear = 16

local registeredPlayers = {} -- names are stored in lowercase for consistency
local db, viewMenuFrame
local updateTimer -- Used to update the display when all items have been cached
local covenantCache = {}


function GroupGear:OnInitialize()
   self.Log = addon.Require "Log":New("GG")
   self.version = GetAddOnMetadata("RCLootCouncil_GroupGear", "Version")
   self.tVersion = nil
   local defaults = {
      profile = {
         showMissingGems = true,
         showMissingEnchants = true,
         showRareGems = false,
         showRareEnchants = false,
      },
   }

   self.db = LibStub("AceDB-3.0"):New("RCGroupGearDB", defaults, true)

   db = self.db.profile

   viewMenuFrame = _G.MSA_DropDownMenu_Create("RCLootCouncil_GroupGear_ViewMenu", UIParent)
   _G.MSA_DropDownMenu_Initialize(viewMenuFrame, self.ViewMenu, "MENU")
   -- register chat and comms, but delay till addon has loaded
   self:ScheduleTimer("Enable", 1)
end

function GroupGear:OnEnable()
   self.Log("GroupGear", self.version, "enabled")
   addon:ModuleChatCmd(self, "Show", nil, "Show the GroupGear window (alt. 'groupgear' or 'gear')", "gg", "groupgear", "gear")

   self.colNameToIndex = {}
   self.scrollCols = self:SetupColumns()
   self:SubPermanentComms()
end

function GroupGear:OnDisable()
   self:Hide()
end

function GroupGear:SubPermanentComms()
   Comms:BulkSubscribe(addon.PREFIXES.MAIN, {
      gear = function (data, sender)
         local player = Player:Get(sender)
         local gear = unpack(data)
         -- Gear needs to be "Uncleaned"
         for k,v in pairs(gear) do
            gear[k] = addon.Utils:UncleanItemString(v)
         end

         self:UpdateEntry(player, nil, nil, gear)
         self:Update()
      end,

      pI = function(data, sender, command, distri)
         local _, guildRank, _, _, ilvl = unpack(data)
         local player = Player:Get(sender)
         self:UpdateEntry (player, ilvl, guildRank)
         self:Update()
      end,
      cov = function(data, sender)
         self:UpdateEntry(Player:Get(sender), nil, nil, nil, unpack(data))
         self:Update()
      end
   })
end

function GroupGear:SetupColumns ()
   if addon.isClassic then
         self.colNameToIndex.class = 1
         self.colNameToIndex.name = 2
         self.colNameToIndex.rank = 3
         self.colNameToIndex.ilvl = 4
         self.colNameToIndex.gear = 5
         self.colNameToIndex.refresh = 6
      return {
         { name = "", width = 20, DoCellUpdate = addon.SetCellClassIcon, }, -- class icon
         { name = _G.NAME, width = 120}, -- Player name
         { name = _G.RANK, width = 100}, -- Guild rank
         { name = _G.ITEM_LEVEL_ABBR, width = 55, align = "CENTER"}, -- ilvl
         { name = "Gear", width = ROW_HEIGHT * num_display_gear + num_display_gear, align = "CENTER", sortnext = 3 }, -- Gear
         { name = "", width = 20, DoCellUpdate = GroupGear.SetCellRefresh, }, -- Refresh icon
      }
   else
         self.colNameToIndex.class = 1
         self.colNameToIndex.name = 2
         self.colNameToIndex.covenant = 3
         self.colNameToIndex.ilvl = 4
         self.colNameToIndex.gear = 5
         self.colNameToIndex.refresh = 6
      return {
         { name = "", width = 20, DoCellUpdate = addon.SetCellClassIcon, }, -- class icon
         { name = _G.NAME, width = 120}, -- Player name
         { name = "Covenant", width = 50, align = "CENTER", DoCellUpdate = GroupGear.SetCellCovenant}, -- Covenant
         { name = _G.ITEM_LEVEL_ABBR, width = 55, align = "CENTER"}, -- ilvl
         { name = "Gear", width = ROW_HEIGHT * num_display_gear + num_display_gear, align = "CENTER", sortnext = 3 }, -- Gear
         { name = "", width = 20, DoCellUpdate = GroupGear.SetCellRefresh, }, -- Refresh icon
      }
   end
end

function GroupGear:Show()
   self.frame = self:GetFrame()
   -- Add our self
   -- self:AddEntry(self:GetGroupGearInfo())
   self.frame.st:SetData(self.frame.rows, true)
   self.frame:Show()
end

function GroupGear:Hide()
   if self.frame then self.frame:Hide() end
end

function GroupGear:IsShown()
   return self.frame and self.frame:IsVisible()
end

function GroupGear:QueryGroup()
   for name in addon:GroupIterator() do
      self:InitEntry(Player:Get(name))
   end
end

function GroupGear:QueryGuild()
   for i = 1, GetNumGuildMembers() do
      local _, _, _, _, _, _, _, _, online, _, _, _, _, _, _,_, guid = GetGuildRosterInfo(i)
      if online then
         self:InitEntry(Player:Get(guid))
      end
   end
end

function GroupGear:SendQueryRequests (target)
   addon:Send(target, "playerInfoRequest")
   addon:Send(target, "Rgear")
   addon:Send(target, "getCov")
end

function GroupGear:Query(method)
   self.frame.rows = {}
   registeredPlayers = {}
   -- Add our self
   -- self:AddEntry(self:GetGroupGearInfo())
   if method == "group" then
      self:QueryGroup()
      self:SendQueryRequests(method)
   elseif method == "guild" then
      self:QueryGuild()
      self:SendQueryRequests(method)
   end
   self.frame.st:SetData(self.frame.rows, true)
end

function GroupGear:Update()
   -- Only update the display when we're showing
   return self:IsShown() and self:Refresh()
end

function GroupGear:GetAverageItemLevel()
   local ilvl, num = 0, 0
   for i = 1, #self.frame.rows do
      if self.frame.rows[i][self.colNameToIndex.ilvl].value ~= 0 then
         ilvl = ilvl + self.frame.rows[i][self.colNameToIndex.ilvl].value
         num = num + 1
      end
   end
   return addon.round(ilvl / num, 2)
end

function GroupGear:Refresh()
   self.frame.st.cols[5].sort = "asc" -- Sort by gear
   self.frame.st:SortData()
   -- Calculate total ilvl
   local ilvl = self:GetAverageItemLevel()
   self.frame.avgilvl:SetText(ilvl and "Average ilvl: "..ilvl or "")
end

function GroupGear:UpdateEntry (player, ilvl, rank, gear, covenantID)
   local name = player:GetName()
   if self:IsPlayerRegistered(name) then -- Update
      local row = registeredPlayers[name:lower()]
      if ilvl and ilvl ~= 0 then self.frame.rows[row][self.colNameToIndex.ilvl].value = addon.round(ilvl, 2) end
      if gear and #gear > 0 then self.frame.rows[row][self.colNameToIndex.gear].gear = gear end
      if covenantID then self.frame.rows[row][self.colNameToIndex.covenant].value = covenantID end
      self.Log:D("UpdateEntry", name, row)
   end
end

function GroupGear:InitEntry (player)
   if not self.frame then return end
   local name = player:GetName()
   local class = player:GetClass()
   tinsert(self.frame.rows,
      -- Retail
         {
            {args = {class} },
            {value = addon.Ambiguate(name), color = addon:GetClassColor(class)},
            {value = 0},
            {value = 0, DoCellUpdate = GroupGear.SetCellIlvl},
            {value = "", DoCellUpdate = GroupGear.SetCellGear, gear = {}},
            {value = "", DoCellUpdate = GroupGear.SetCellRefresh, name = name},
      })
      local index = #self.frame.rows
      self.frame.rows[index].name = name
      self.Log:D("InitEntry", name, index)
      registeredPlayers[name:lower()] = index
end

function GroupGear:IsPlayerRegistered(name)
   return registeredPlayers[name:lower()] and true
end

function GroupGear.ViewMenu(menu, level)
   if level == 1 then
      local info = MSA_DropDownMenu_CreateInfo()
      info.text = "Options"
      info.isTitle = true
      info.notCheckable = true
      info.disabled = true
      MSA_DropDownMenu_AddButton(info, level)

      info = MSA_DropDownMenu_CreateInfo()
      info.text = "Highlight missing enchants"
      info.checked = db.showMissingEnchants
      info.func = function() db.showMissingEnchants = not db.showMissingEnchants; GroupGear:Refresh() end
      MSA_DropDownMenu_AddButton(info, level)

      info.text = "Highlight non-epic enchants"
      info.checked = db.showRareEnchants
      info.func = function() db.showRareEnchants = not db.showRareEnchants; GroupGear:Refresh() end
      MSA_DropDownMenu_AddButton(info, level)

      info.text = "Highlight missing gems"
      info.checked = db.showMissingGems
      info.func = function() db.showMissingGems = not db.showMissingGems; GroupGear:Refresh() end
      MSA_DropDownMenu_AddButton(info, level)

      info.text = "Highlight non-epic gems"
      info.checked = db.showRareGems
      info.func = function() db.showRareGems = not db.showRareGems; GroupGear:Refresh() end
      MSA_DropDownMenu_AddButton(info, level)
   end
end

function GroupGear:GetFrame()
   if self.frame then return self.frame end
   local f = addon.UI:NewNamed("Frame", UIParent, "RCGroupGearFrame", "RCLootCouncil - Group Gear", 250)

   local st = ST:CreateST(self.scrollCols, 12, ROW_HEIGHT, nil, f.content)
   st.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, - 35)
   f:SetWidth(st.frame:GetWidth() + 20)
   f.rows = {}
   f.st = st

   local b1 = addon:CreateButton(_G.GUILD, f.content)
   b1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
   b1:SetScript("OnClick", function() self:Query("guild") end)
   f.groupButton = b1

   local b2 = addon:CreateButton(_G.GROUP, f.content)
   b2:SetPoint("LEFT", b1, "RIGHT", 10, 0)
   b2:SetScript("OnClick", function() self:Query("group") end)
   f.guildButton = b2

   local b3 = addon:CreateButton(_G.CLOSE, f.content)
   b3:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", - 10, 10)
   b3:SetScript("OnClick", function() self:Hide() end)
   f.closeButton = b3

   local b4 = CreateFrame("Button", nil, f.content)
   b4:SetSize(20, 20)
   b4:SetPoint("LEFT", b2, "RIGHT", 8, 0)
   b4:SetNormalTexture("Interface/MINIMAP/TRACKING/None")
   -- b4:SetBackdrop({
   --    bgFile = "Interface/Minimap/UI-Minimap-Background",
   --    --bgFile = "Interface/Minimap/Minimap-TrackingBorder",
   -- })
   b4:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
   b4:SetScript("OnClick", function(this) MSA_ToggleDropDownMenu(1, nil, viewMenuFrame, this, 0, 0) end )
   -- b4.border = b4:CreateTexture()
   -- b4.border:SetTexture("Interface/Minimap/Minimap-TrackingBorder")
   -- b4.border:SetSize(44,44)
   -- b4.border:SetPoint("TOPLEFT", b4, "TOPLEFT", -4,4)
   f.viewButton = b4

   local f1 = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
   f1:SetPoint("LEFT", b4, "RIGHT", 10, 0)
   f1:SetTextColor(1, 1, 1, 1)
   f.avgilvl = f1

   return f
end

local getCovenantData = function (id)
   if covenantCache[id] then return covenantCache[id] end
   if not C_Covenants then return nil end
   local data = C_Covenants.GetCovenantData(id)
   covenantCache[id] = data
   return data
end

function GroupGear.SetCellCovenant(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
   local covenantID = data[realrow][column].value

   if not covenantID or covenantID == 0 then
      if frame.tex then
         frame.tex:Hide()
      end
      frame.text:SetText(_G.NONE)
      return
   end
   local data = getCovenantData(covenantID)
   if not data then return end -- Failsafe
   if not frame.tex then
      frame.tex = frame:CreateTexture()
      local width = frame:GetWidth()
      --frame.tex:SetAllPoints(frame)
      frame.tex:SetPoint("TOPLEFT", frame, "TOPLEFT", width / 4, 0)
      frame.tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -width / 4, 0)
      function frame.tex.GetObjectType () return "Texture" end -- Needed in TextureUtil with below call
   end
   SetupTextureKitOnFrame(data.textureKit, frame.tex, "CovenantChoice-Celebration-%sSigil",TextureKitConstants.SetVisibility, TextureKitConstants.UseAtlasSize)
   frame:SetScript("OnEnter", function() addon:CreateTooltip(data.name) end)
   frame:SetScript("OnLeave", function() addon:HideTooltip() end)
   frame.text:SetText("")
end

function GroupGear.SetCellIlvl(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
   local ilvl = data[realrow][column].value
   ilvl = ilvl == 0 and "-" or ilvl
   frame.text:SetText(ilvl)
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
      frame.text:SetTextColor(.75, .75, .75, 1)
      local f = CreateFrame("Frame", frame:GetName().."GearFrame", frame)
      f:SetPoint("LEFT", frame, "LEFT")
      f:SetSize(ROW_HEIGHT * num_display_gear + num_display_gear, ROW_HEIGHT)
      f.gear = {}
      -- Create the individual pieces' frame
      for i = 1, num_display_gear do
         f.gear[i] = CreateFrame("Button", f:GetName()..i, f)
         if i == 1 then
            f.gear[i]:SetPoint("LEFT", f, "LEFT", 0, 0)
         else
            f.gear[i]:SetPoint("LEFT", f.gear[i - 1], "RIGHT", 1, 0)
         end
         f.gear[i]:SetSize(ROW_HEIGHT, ROW_HEIGHT)
         f.gear[i]:SetScript("OnLeave", function() addon:HideTooltip() end)

         f.gear[i].overlay = f.gear[i]:CreateTexture(nil, "OVERLAY")
         f.gear[i].overlay:SetSize(ROW_HEIGHT, ROW_HEIGHT)
         f.gear[i].overlay:SetPoint("CENTER", f.gear[i])
         f.gear[i].overlay:SetColorTexture(1, 0.1, 0.1, 0.5)
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
   if gear == nil or #gear == 0 then -- Gear might not be received yet
      if data[realrow][GroupGear.colNameToIndex.ilvl].value == 0 then -- no ilvl either = no RCLootCouncil
         frame.text:SetText("No RCLootCouncil")
      else -- No GroupGear
         frame.text:SetText("No GroupGear")
      end
      data[realrow][column].value = "0";
      return frame.container:Hide()
   end
   -- Update icons/tooltips
   for i, gearFrame in ipairs(frame.container.gear) do
      gearFrame:SetScript("OnEnter", function() addon:CreateHypertip(gear[i]) end)
      local _, _, quality, ilvl, _, _, _, _, _, texture = GetItemInfo(gear[i] or "")
      if (texture == nil or texture == "") and gear[i] then
         if GroupGear:TimeLeft(updateTimer) < 0.1 then -- Only 1 timer at a time (but it's usually not exactly 0 after a recent timer)
            updateTimer = GroupGear:ScheduleTimer(GroupGear.Refresh, 2, GroupGear)
         end
      end
      gearFrame:SetNormalTexture(texture)

      gearFrame.ilvl:SetText(ilvl)
      local r, g, b = GetItemQualityColor(quality or 1)
      gearFrame.ilvl:SetTextColor(r, g, b, 1)
      GroupGear:ColorizeItemBackdrop(gearFrame, gear[i], i, true)
   end
   frame.text:SetText("")
   data[realrow][column].value = "1"
   frame.container:Show()
end

function GroupGear:EnchantCheck(item)
   if db.showMissingEnchants or db.showRareEnchants then
      local enchantID = select(4, addon:DecodeItemLink(item))
      if not enchantID or enchantID == 0 or enchantID == "" then
         return true
      elseif db.showRareEnchants and self.Lists.enchants[enchantID] == "rare" then
         return true
      elseif db.showMissingEnchants then
         return not self.Lists.enchants[enchantID]
      end
   end
   return false
end

function GroupGear:GemCheck(item)
   if db.showMissingGems or db.showRareGems then
      local _, _, _, _, gemID1, _, _, _, _, _, _, _, _, _, _, _, bonusIDs = addon:DecodeItemLink(item)
      if gemID1 == 0 or gemID1 == "" then gemID1 = false end
      -- check if we should have a gem:
      for _, id in ipairs(bonusIDs) do
         if self.Lists.socketsBonusIDs[id] then -- There's a socket
            if not gemID1 then
               return true
            end
         end
      end
      -- Now see if we have a gem, and it's valid
      if gemID1 and db.showRareGems and self.Lists.gems[gemID1] == "rare" then
         return true
      elseif gemID1 then
         return not self.Lists.gems[gemID1]
      end
   end
   return false
end

function GroupGear:ColorizeItemBackdrop(frame, item, slotID, noGGCompensation)
   if not item then return end
   if not noGGCompensation and slotID >= 4 then slotID = slotID + 1 end -- Convert back to the "real" slotID's (we skipped the shirt; 4)
   local colorize = false
   -- Need enchants on: Rings, weapons
   if self.Lists.enchantSlotIDs[slotID] then
      colorize = self:EnchantCheck(item) and true or colorize -- retain original value
   end
   -- Gem check
   colorize = self:GemCheck(item) and true or colorize

   if colorize then frame.overlay:Show() else frame.overlay:Hide() end
end
