local addonName, Data = ...
local BattleGroundEnemies = BattleGroundEnemies

local GetTime = GetTime
local C_PvP = C_PvP

local addonName, Data = ...
-- health name it Trinket, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local LSM = LibStub("LibSharedMedia-3.0")
local TrinketColor = TrinketColor
local mathrandom = math.random


local L = Data.L
local randomTrinkets = {}

do
	local count = 1
	for triggerSpellID, tinketNumber in pairs(Data.TriggerSpellIDToTrinketnumber) do
		if GetSpellInfo(triggerSpellID) then
			randomTrinkets[count] = triggerSpellID
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
				desc = L.Trinket_Width_Desc,
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


local Trinket = {} 

Trinket.AttachToButton = function(self, playerButton)

	local trinket = CreateFrame("Frame", nil, playerButton)

	trinket:HookScript("OnEnter", function(self)
		if self.SpellID then
			BattleGroundEnemies:ShowTooltip(self, function() 
				GameTooltip:SetSpellByID(self.SpellID)
			end)
		end
	end)
	
	trinket:HookScript("OnLeave", function(self)
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end)

	
	trinket.Icon = trinket:CreateTexture()
	trinket.Icon:SetAllPoints()
	trinket:SetScript("OnSizeChanged", function(self, width, height)
		BattleGroundEnemies.CropImage(self.Icon, width, height)
	end)
	
	trinket.Cooldown = BattleGroundEnemies.MyCreateCooldown(trinket)


	trinket.TrinketCheck = function(self, spellID, setCooldown)
		if not Data.TriggerSpellIDToTrinketnumber[spellID] then return end
		self:DisplayTrinket(spellID, Data.TriggerSpellIDToDisplayFileId[spellID])
		if setCooldown then
			self:SetTrinketCooldown(GetTime(), Data.TrinketTriggerSpellIDtoCooldown[spellID] or 0)
		end
	end
	
	trinket.DisplayTrinket = function(self, spellID, texture)
		self.SpellID = spellID
		self.HasTrinket = Data.TriggerSpellIDToTrinketnumber[spellID]
		self.Icon:SetTexture(texture)
	end
	
	trinket.SetTrinketCooldown = function(self, startTime, duration)
		if (startTime ~= 0 and duration ~= 0) then
			self.Cooldown:SetCooldown(startTime, duration)
		else
			self.Cooldown:Clear()
		end
	end

	trinket.AuraApplied = function(self, playerButton, spellID, spellName, srcName, auraType, amount, duration)
		BattleGroundEnemies.Counter.AuraApplied = (BattleGroundEnemies.Counter.AuraApplied or 0) + 1
		
	
		--if srcName == PlayerDetails.PlayerName then BattleGroundEnemies:Debug(aurasEnabled, config.Auras_Enabled, config.AurasFiltering_Enabled, config.AurasFiltering_Filterlist[spellID], duration) end
		
		if duration and duration > 0 then
			if relentlessCheck then
	
				local Racefaktor = 1
				if drCat == "stun" and playerButton.PlayerRace == "Orc" then
					--Racefaktor = 0.8	--Hardiness, but since september 5th hotfix hardiness no longer stacks with relentless
					return 
				end
	
				
				--local diminish = actualduraion/(Racefaktor * normalDuration * Trinketfaktor)
				--local trinketFaktor * diminish = duration/(Racefaktor * normalDuration) 
				--trinketTimesDiminish = trinketFaktor * diminish
				--trinketTimesDiminish = without relentless : 1, 0.5, 0.25, with relentless: 0.8, 0.4, 0.2
	
				local trinketTimesDiminish = duration/(Racefaktor * relentlessCheck)
				
				if trinketTimesDiminish == 0.8 or trinketTimesDiminish == 0.4 or trinketTimesDiminish == 0.2 then --Relentless
					playerButton.Trinket.HasTrinket = 4
					playerButton.Trinket.Icon:SetTexture(GetSpellTexture(196029))
				end
			end
	
			if auraType == "DEBUFF" and spellID == 336139 then --adaptation
				playerButton.Trinket:DisplayTrinket(spellID, Data.TriggerSpellIDToDisplayFileId[spellID], duration)
				playerButton.Trinket:SetTrinketCooldown(GetTime(), duration)
			end
		end
	end

	trinket.ApplySettings = function(self, playerButton)	
		self.Cooldown:ApplyCooldownSettings(self.config.Cooldown_ShowNumbers, false, true, {0, 0, 0, 0.75})
		self.Cooldown.Text:ApplyFontStringSettings(self.config.Cooldown_Fontsize, self.config.Cooldown_Outline, self.config.Cooldown_EnableTextshadow, self.config.Cooldown_TextShadowcolor)
	end
	
	
	trinket.NewPlayer = function(self, playerButton)
		return true
	end
	
	trinket.Reset = function(self, playerButton)
		self.HasTrinket = nil
		self.SpellID = false
		self.Icon:SetTexture(nil)
		self.Cooldown:Clear()	--reset Trinket Cooldown
	end
		
	trinket.Test = function(self)
		if self.Cooldown:GetCooldownDuration() == 0 then
			local spellID = randomTrinkets[mathrandom(1, #randomTrinkets)] 
			if spellID ~= 214027 then --adapted
				if spellID == 196029 then--relentless
					self:TrinketCheck(spellID, false)
				else
					self:TrinketCheck(spellID, true)
				end
			end
		end
	end
	
	return trinket
end

function Trinket:ARENA_OPPONENT_UPDATE(unitEvent, unitID)
	C_PvP.RequestCrowdControlSpell(unitID)
end

function Trinket:ARENA_CROWD_CONTROL_SPELL_UPDATE(unitID, ...)
	local playerButton = self.MainFrame:GetPlayerbuttonByUnitID(unitID)
	if not playerButton then playerButton = self.MainFrame:GetPlayerbuttonByName(unitID) end -- the event fires before the name is set on the frame, so at this point the name is still the unitID
	if playerButton and playerButton.Trinket:IsShown() then
		if isTBCC then
			local unitTarget, spellID, itemID = ...
			if(itemID ~= 0) then
				local itemTexture = GetItemIcon(itemID);
				playerButton.Trinket:DisplayTrinket(spellID, itemTexture)
			else
				local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID);
				playerButton.Trinket:DisplayTrinket(spellID, spellTextureNoOverride)
			end	
		else
			local spellID = ...
			local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID);
			playerButton.Trinket:DisplayTrinket(spellID, spellTextureNoOverride)
		end
	end

	--if spellID ~= 72757 then --cogwheel (30 sec cooldown trigger by racial)
	--end
end

--fires when a arenaX enemy used a trinket or racial to break cc, C_PvP.GetArenaCrowdControlInfo(unitID) shoudl be called afterwards to get used CCs
--this event is kinda stupid, it doesn't say which unit used which cooldown, it justs says that somebody used some sort of trinket
function Trinket:ARENA_COOLDOWNS_UPDATE(unitID)
	--if not self.db.profile.Trinket then return end
	for i = 1, 5 do
		local unitID = "arena"..i
		local playerButton = self.MainFrame:GetPlayerbuttonByUnitID(unitID)
		if playerButton then
			if isTBCC then
				local spellID, itemID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unitID)
				if spellID then
	
					if(itemID ~= 0) then
						local itemTexture = GetItemIcon(itemID)
						playerButton.Trinket:DisplayTrinket(spellID, itemTexture)
					else
						local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID)
						playerButton.Trinket:DisplayTrinket(spellID, spellTextureNoOverride)
					end
					
					playerButton.Trinket:SetTrinketCooldown(startTime/1000.0, duration/1000.0)
				end
			else
				local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unitID)
				if spellID then
					local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID)
					playerButton.Trinket:DisplayTrinket(spellID, spellTextureNoOverride)
					playerButton.Trinket:SetTrinketCooldown(startTime/1000.0, duration/1000.0)
				end
			end
		end
	end
end




local CombatLogevents = {}

--CombatLogevents.SPELL_DISPEL = CombatLogevents.SPELL_AURA_REMOVED

function CombatLogevents.SPELL_CAST_SUCCESS(self, srcName, destName, spellID)
	local playerButton = self.MainFrame:GetPlayerbuttonByName(srcName)
	if playerButton and playerButton.isShown then
		playerButton.Trinket:TrinketCheck(spellID, true)
	end
end

Trinket.COMBAT_LOG_EVENT_UNFILTERED = function(self, ...)
	local timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType = CombatLogGetCurrentEventInfo()
	self:Debug(timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType)
	if CombatLogevents[subevent] then 
		return CombatLogevents[subevent](self, srcName, destName, spellID, spellName, auraType) 
	end
end


-- Trinket.Disable = function(self, playerButton)
-- 	--dont SetWidth before Hide() otherwise it won't work as aimed
-- 	playerButton.Trinket:SetWidth(0.01)
-- end

BattleGroundEnemies:RegisterModule("Trinket", Trinket, true, defaults, options, {General = {"ARENA_OPPONENT_UPDATE", "ARENA_COOLDOWNS_UPDATE", "ARENA_CROWD_CONTROL_SPELL_UPDATE", "COMBAT_LOG_EVENT_UNFILTERED"}})