local BattleGroundEnemies = BattleGroundEnemies
local addonName, Data = ...
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

local L = Data.L

local function addVerticalSpacing(order)
	local verticalSpacing = {
		type = "description",
		name = " ",
		fontSize = "large",
		width = "full",
		order = order
	}
	return verticalSpacing
end

local function addHorizontalSpacing(order)
	local horizontalSpacing = {
		type = "description",
		name = " ",
		width = "half",	
		order = order,
	}
	return horizontalSpacing
end

local defaults =  {
	Trinket_ShowNumbers = true,
	Trinket_Cooldown_Fontsize = 12,
	Trinket_Cooldown_Outline = "OUTLINE",
	Trinket_Cooldown_EnableTextshadow = false,
	Trinket_Cooldown_TextShadowcolor = {0, 0, 0, 1},
}

local options = {
	Texture = {
		type = "select",
		name = L.BarTexture,
		desc = L.Trinket_Texture_Desc,
		dialogControl = 'LSM30_Statusbar',
		values = AceGUIWidgetLSMlists.statusbar,
		width = "normal",
		order = 1
	},
	Fake = addHorizontalSpacing(2),
	Background = {
		type = "color",
		name = L.BarBackground,
		desc = L.Trinket_Background_Desc,
		hasAlpha = true,
		width = "normal",
		order = 3
	},
	Fake = addVerticalSpacing(4),
}
	
	


local Trinket = BattleGroundEnemies:RegisterModule("Trinket", defaults, options)
Trinket:SetScript("OnEvent", function(self, event, ...)
	BattleGroundEnemies:Debug("BattleGroundEnemies OnEvent", event, ...)
	self[event](self, ...) 
end)


Trinket.AttachToButton = function(self, playerButton)

	local Trinket = CreateFrame("Frame", nil, playerButton)

	Trinket:HookScript("OnEnter", function(self)
		if self.SpellID then
			BattleGroundEnemies:ShowTooltip(self, function() 
				GameTooltip:SetSpellByID(self.SpellID)
			end)
		end
	end)
	
	Trinket:HookScript("OnLeave", function(self)
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end)

	
	Trinket.Icon = Trinket:CreateTexture()
	Trinket.Icon:SetAllPoints()
	Trinket:SetScript("OnSizeChanged", function(self, width, height)
		BattleGroundEnemies.CropImage(self.Icon, width, height)
	end)
	
	Trinket.Cooldown = BattleGroundEnemies.MyCreateCooldown(Trinket)


	Trinket.TrinketCheck = function(self, spellID, setCooldown)
		if not Data.TriggerSpellIDToTrinketnumber[spellID] then return end
		self:DisplayTrinket(spellID, Data.TriggerSpellIDToDisplayFileId[spellID])
		if setCooldown then
			self:SetTrinketCooldown(GetTime(), Data.TrinketTriggerSpellIDtoCooldown[spellID] or 0)
		end
	end
	
	Trinket.DisplayTrinket = function(self, spellID, texture)
		self.SpellID = spellID
		self.HasTrinket = Data.TriggerSpellIDToTrinketnumber[spellID]
		self.Icon:SetTexture(texture)
	end
	
	Trinket.SetTrinketCooldown = function(self, startTime, duration)
		if (startTime ~= 0 and duration ~= 0) then
			self.Cooldown:SetCooldown(startTime, duration)
		else
			self.Cooldown:Clear()
		end
	end

	Trinket:AuraApplied = function(self, playerButton, spellID, spellName, srcName, auraType, amount)
		BattleGroundEnemies.Counter.AuraApplied = (BattleGroundEnemies.Counter.AuraApplied or 0) + 1
		
		local amount, index, _, debuffType, duration, expirationTime, unitCaster, canApplyAura 
		local isMine = srcName == BattleGroundEnemies.PlayerDetails.PlayerName
	
		if spellName then 
			if not (duration or expirationTime) then
	
				local unitIDs = playerButton.UnitIDs
				local activeUnitID 
	
				-- it seems to be possible to get Buffs from nameplates now :))))
				-- we can't get Buffs from nameplates(we only use nameplates for enemies) > find another unitID for that enemy if auraType is a buff and the active unitID is a nameplate
			
				local activeUnitID = playerButton:GetUnitID()
	
				
				if not activeUnitID then return end
				if isMine then
					index, _, _, amount, debuffType , duration, expirationTime, unitCaster, _, _, _, canApplyAura, _, _, _, _, _, _, _ = FindAuraBySpellID(activeUnitID, spellID, "PLAYER|" .. filter)
				else
					for i = 1, 40 do
						local _spellID
						_, _, amount, debuffType , duration, expirationTime, unitCaster, _, _, _spellID, canApplyAura, _, _, _, _, _, _, _ = UnitAura(activeUnitID, i, filter)
						if spellID == _spellID and unitCaster then
							local uName, realm = UnitName(unitCaster)
							if realm then
								uName = uName.."-"..realm
							end
							if uName == srcName then
								break
							end
						end
					end
				end
			end
		end
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
	
	playerButton.Trinket = Trinket
end



function Trinket:ARENA_CROWD_CONTROL_SPELL_UPDATE(unitID, ...)
	local playerButton = BattleGroundEnemies:GetPlayerbuttonByUnitID(unitID)
	if not playerButton then playerButton = BattleGroundEnemies:GetPlayerbuttonByName(unitID) end -- the event fires before the name is set on the frame, so at this point the name is still the unitID
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
		local playerButton = BattleGroundEnemies:GetPlayerbuttonByUnitID(unitID)
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
	local playerButton = self:GetPlayerbuttonByName(srcName)
	if playerButton and playerButton.isShown then
		playerButton.Trinket:TrinketCheck(spellID, true)
	end
end

Trinket.COMBAT_LOG_EVENT_UNFILTERED = function(self, ...)
	local timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType = CombatLogGetCurrentEventInfo()
	self:Debug(timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType)
	if CombatLogevents[subevent] then 
		CombatLogevents.Counter[subevent] = (CombatLogevents.Counter[subevent] or 0) + 1
		return CombatLogevents[subevent](self, srcName, destName, spellID, spellName, auraType) 
	end
end

Trinket.Enable = function(self, playerButton)
	Trinket:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
	Trinket:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
	Trinket:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	playerButton.Trinket:Show()
end


Trinket.Disable = function(self, playerButton)
	--dont SetWidth before Hide() otherwise it won't work as aimed
	playerButton.Trinket:Hide()
	playerButton.Trinket:SetWidth(0.01)
	Trinket:UnregisterAllEvents()
end


Trinket.ApplySettings = function(self, playerButton, config)
	playerButton.Trinket.config config
	
	playerButton.Trinket.Cooldown:ApplyCooldownSettings(config.Trinket_ShowNumbers, false, true, {0, 0, 0, 0.75})
	playerButton.Trinket.Cooldown.Text:ApplyFontStringSettings(config.Trinket_Cooldown_Fontsize, config.Trinket_Cooldown_Outline, config.Trinket_Cooldown_EnableTextshadow, config.Trinket_Cooldown_TextShadowcolor)
end


Trinket.NewPlayer = function(self, playerButton)
	local powerToken
	if isTBCC then
		powerToken = TrinketColor[Data.Classes[playerButton.PlayerClass].Ressource]
	else
		powerToken = TrinketColor[Data.Classes[playerButton.PlayerClass][playerButton.PlayerSpecName].Ressource]
	end
	
	self:CheckForNewPowerColor(playerButton, powerToken)
end

Trinket.Reset = function(self, playerButton)
	playerButton.Trinket.HasTrinket = nil
	playerButton.Trinket.SpellID = false
	playerButton.Trinket.Icon:SetTexture(nil)
	playerButton.Trinket.Cooldown:Clear()	--reset Trinket Cooldown
end

Trinket.Update = function(self, playerButton, unitID, powerToken)
	BattleGroundEnemies.Counter.UpdatePower = (BattleGroundEnemies.Counter.UpdateRange or 0) + 1

	if powerToken then
		self:CheckForNewPowerColor(playerButton, powerToken)
	else
		local powerType, powerToken, altR, altG, altB = UnitPowerType(unitID)
		self:CheckForNewPowerColor(playerButton, powerToken)
	end
	playerButton.Power:SetValue(UnitPower(unitID)/UnitPowerMax(unitID))
end


	











	