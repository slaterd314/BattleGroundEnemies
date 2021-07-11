local BattleGroundEnemies = BattleGroundEnemies
local addonName, Data = ...
local GetTime = GetTime
local C_PvP = C_PvP

local addonName, Data = ...
-- health name it Racial, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local LSM = LibStub("LibSharedMedia-3.0")
local RacialColor = RacialColor
local mathrandom = math.random

local L = Data.L
local randomRacials = {}

do
	local count = 1
	for racialSpelliD, cd in pairs(Data.RacialSpellIDtoCooldown) do
		if GetSpellInfo(racialSpelliD) then
			randomRacials[count] = racialSpelliD
			count = count + 1
		end
	end
end


local defaults =  {
	Enabled = true,
	Cooldown_ShowNumbers = true,
	Cooldown_Fontsize = 12,
	Cooldown_Outline = "OUTLINE",
	Cooldown_EnableTextshadow = false,
	Cooldown_TextShadowcolor = {0, 0, 0, 1},
}

local options = {
	All = function(location) 
		return {
			Width = {
				type = "range",
				name = L.Width,
				desc = L.Racial_Width_Desc,
				min = 1,
				max = 80,
				step = 1,
				order = 3
			},
			CooldownTextSettings = {
				type = "group",
				name = L.Countdowntext,
				--desc = L.TrinketSettings_Desc,
				order = 4,
				args = Data.optionHelpers.addCooldownTextsettings(location)
			}
		}
	end
} 


	
	


local Racial = {} 

Racial.AttachToButton = function(self, playerButton)

	local racial = CreateFrame("Frame", nil, playerButton)

	racial:HookScript("OnEnter", function(self)
		if self.SpellID then
			BattleGroundEnemies:ShowTooltip(self, function() 
				GameTooltip:SetSpellByID(self.SpellID)
			end)
		end
	end)
	
	racial:HookScript("OnLeave", function(self)
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end)

	
	racial.Icon = racial:CreateTexture()
	racial.Icon:SetAllPoints()
	racial:SetScript("OnSizeChanged", function(self, width, height)
		BattleGroundEnemies.CropImage(self.Icon, width, height)
	end)
	
	racial.Cooldown = BattleGroundEnemies.MyCreateCooldown(racial)


	racial.RacialCheck = function(self, spellID)
		local config = self.config 

		if not config.Racial_Enabled then return end
		local insi = playerButton.Trinket
		
		if Data.RacialSpellIDtoCooldownTrigger[spellID] and not insi.HasTrinket == 4 and insi.Cooldown:GetCooldownDuration() < Data.RacialSpellIDtoCooldownTrigger[spellID] * 1000 then
			insi.Cooldown:SetCooldown(GetTime(), Data.RacialSpellIDtoCooldownTrigger[spellID])
		end
		
		if config.RacialFiltering_Enabled and not config.RacialFiltering_Filterlist[spellID] then return end
		
		self.SpellID = spellID
		self.Icon:SetTexture(Data.TriggerSpellIDToDisplayFileId[spellID])
		self.Cooldown:SetCooldown(GetTime(), Data.RacialSpellIDtoCooldown[spellID])
	end

	racial.ApplySettings = function(self)
		local config = self.config
		
		self.Cooldown:ApplyCooldownSettings(config.Racial_ShowNumbers, false, true, {0, 0, 0, 0.75})
		self.Cooldown.Text:ApplyFontStringSettings(config.Racial_Cooldown_Fontsize, config.Racial_Cooldown_Outline, config.Racial_Cooldown_EnableTextshadow, config.Racial_Cooldown_TextShadowcolor)
	end

	racial.Reset = function(self)
		self.SpellID = false
		self.Icon:SetTexture(nil)
		self.Cooldown:Clear()	--reset Racial Cooldown
	end

	racial.Test = function(self)
		if self.Cooldown:GetCooldownDuration() == 0 then
			local spellID = randomRacials[mathrandom(1, #randomRacials)] 
			self:RacialCheck(spellID)
		end
	end
	
	return racial
end

local CombatLogevents = {}

--CombatLogevents.SPELL_DISPEL = CombatLogevents.SPELL_AURA_REMOVED

function CombatLogevents.SPELL_CAST_SUCCESS(self, srcName, destName, spellID)
	local playerButton = self.MainFrame:GetPlayerbuttonByName(srcName)
	if playerButton and playerButton.isShown then
		playerButton.Racial:RacialCheck(spellID, true)
	end
end

Racial.COMBAT_LOG_EVENT_UNFILTERED = function(self, ...)
	local timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType = CombatLogGetCurrentEventInfo()
	self:Debug(timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType)
	if CombatLogevents[subevent] then 
		return CombatLogevents[subevent](self, srcName, destName, spellID, spellName, auraType) 
	end
end

-- Racial.Disable = function(self, playerButton)
-- 	--dont SetWidth before Hide() otherwise it won't work as aimed
-- 	playerButton.Racial:SetWidth(0.01)
-- end


BattleGroundEnemies:RegisterModule("Racial", Racial, true, defaults, options, {General = {"COMBAT_LOG_EVENT_UNFILTERED"}})