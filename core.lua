-- Author      : Potdisc
-- Custom module - Group Gear
-- core.lua 	Adds a frame showing your groups gear based on the RCLootCouncil framework.

local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
local GroupGear = addon:NewModule("RCGroupGear", "AceComm-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RCLootCouncil")
local ST = LibStub("ScrollingTable")

local scrollCols = {
   { name = "",         width = 20,   DoCellUpdate = addon.SetCellClassIcon,},   -- class icon
   { name = L["Name"],     width = 120},                                            -- Player name
   { name = L["Rank"],     width = 95},                                             -- guild Rank
   { name = L["ilvl"],     width = 55,   align = "CENTER"},                         -- ilvl
   { name = "A. traits", width = 55,  align = "CENTER"},                         -- # of artifact traits
   { name = "",         width = 25,   DoCellUpdate = GroupGear.SetCellRefresh, } -- Refresh icon
}

local ROW_HEIGHT = 20
local registeredPlayers = {}


function GroupGear:OnInitialize()
   self.version = GetAddOnMetadata("RCLootCouncil_GroupGear", "Version")

   -- register chat and comms
	addon:CustomChatCmd(self, "Enable", "gg", "groupgear", "gear")
	self:RegisterComm("RCLootCouncil")
end

function GroupGear:OnEnable()
   addon:Debug("GroupGear", self.version, "enabled")
   self:Show()
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
            addon:SendCommand(sender, "groupGearResponse", self:GetGroupGearInfo())
         elseif command == "groupGearResponse" then
            local name, class, guildRank, ilvl, artifactTraits = unpack(data)
            if self:IsPlayerRegistered(name) then
               -- Just readd them, as we have all the needed info
               tremove(self.frame.rows, registeredPlayers[name])
            end
            self:AddEntry(name, class, guildRank, ilvl, artifactTraits)

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

function GroupGear:AddEntry(name, class, guildRank, ilvl, artifactTraits)
   tinsert(self.frame.rows, {
      {args = {class} },
      {value = addon.Ambiguate(name), color = addon:GetClassColor(class)},
      {value = guildRank or "Unknown"},
      {value = addon.round(ilvl,2)},
      {value = artifactTraits or "Unknown"},
      {value = "", DoCellUpdate = GroupGear.SetCellRefresh, name = name}
   })
   registeredPlayers[name] = #self.frame.rows
   self.frame.st:SortData()
end

function GroupGear:UpdateEntry(name, ilvl)
   -- We'll assume it's only when player's doesn't have GG installed that updates occur,
   -- so only update ilvl
   -- Find out which row they're at
   local row = registeredPlayers[name]
   -- And edit the value if we have the data, otherwise keep what we have
   self.frame.rows[row][4].value = ilvl and addon.round(ilvl,2) or self.frame.rows[row][4].value
   self.frame.st:Refresh()
end

-- Function to return everything needed by GroupGear to the requester
function GroupGear:GetGroupGearInfo()
   local name, class, _, guildRank, _, _, ilvl = addon:GetPlayerInfo()
   return name, class, guildRank, ilvl, select(6,C_ArtifactUI.GetEquippedArtifactInfo())
end

function GroupGear:IsPlayerRegistered(name)
   for k in pairs(registeredPlayers) do
      if k == name then return true end
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

   local b1 = addon:CreateButton(L["Group"], f.content)
   b1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
   b1:SetScript("OnClick", function() self:Query("group") end)
   f.groupButton = b1

   local b2 = addon:CreateButton(L["Guild"], f.content)
   b2:SetPoint("LEFT", b1, "RIGHT", 10, 0)
   b2:SetScript("OnClick", function() self:Query("guild") end)
   f.guildButton = b2

   local b3 = addon:CreateButton(L.Close, f.content)
   b3:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
   b3:SetScript("OnClick", function() self:Disable() end)
   f.closeButton = b3

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
      addon:SendCommand("group", "playerInfoRequest")
      addon:SendCommand("group", "groupGearRequest")
   end)
   f:SetScript("OnEnter", function() addon:CreateTooltip("Refresh")end)
   f:SetScript("OnLeave", addon.HideTooltip)
   frame.btn = f
end
