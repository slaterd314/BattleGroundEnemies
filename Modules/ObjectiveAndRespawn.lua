local BattleGroundEnemies = BattleGroundEnemies
local addonName, Data = ...
local GetTime = GetTime




local addonName, Data = ...
-- health name it healthBar, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local mathrandom = math.random

local L = Data.L


local defaults =  {
	Enabled = true,
	Fontsize = 17,
	Textcolor = {1, 1, 1, 1},
	Outline = "THICKOUTLINE",
	EnableTextshadow = false,
	TextShadowcolor = {0, 0, 0, 1}
}

local options =  {
	["15"] = function(location)
		return {
			TextSettings = {
				type = "group",
				name = "",
				--desc = L.TrinketSettings_Desc,
				disabled = function() return not location["15"].ObjectiveAndRespawn_ObjectiveEnabled end,
				inline = true,
				order = 4,
				args = Data.optionHelpers.addNormalTextSettings(location["15"])
			}
		}
	end,
	RBG = function(location)
		return {
			RespawnEnabled = {
				type = "toggle",
				name = ENABLE,
				desc = L.ObjectiveAndRespawn_RespawnEnabled_Desc,
				order = 1
			},
			CooldownTextSettings = {
				type = "group",
				name = L.Countdowntext,
				--desc = L.TrinketSettings_Desc,
				disabled = function() return not location.RBG.ObjectiveAndRespawn_RespawnEnabled end,
				order = 5,
				args = Data.optionHelpers.addCooldownTextsettings(location.RBG, "ObjectiveAndRespawn")
			}
		}
	end
}



local ObjectiveAndRespawn = {}



local testFlagCarrier
ObjectiveAndRespawn.AttachToButton = function(self, playerButton)
	local objectiveAndRespawn = CreateFrame("Frame", nil, playerButton)
	objectiveAndRespawn = CreateFrame("Frame", nil, playerButton)
	objectiveAndRespawn:SetFrameLevel(playerButton:GetFrameLevel()+5)
	
	objectiveAndRespawn.Icon = objectiveAndRespawn:CreateTexture(nil, "BORDER")
	objectiveAndRespawn.Icon:SetAllPoints()
	
	objectiveAndRespawn:SetScript("OnSizeChanged", function(self, width, height)
		BattleGroundEnemies.CropImage(self.Icon, width, height)
	end)
	objectiveAndRespawn:Hide()
	
	objectiveAndRespawn.AuraText = BattleGroundEnemies.MyCreateFontString(objectiveAndRespawn)
	objectiveAndRespawn.AuraText:SetAllPoints()
	objectiveAndRespawn.AuraText:SetJustifyH("CENTER")
	
	objectiveAndRespawn.Cooldown = BattleGroundEnemies.MyCreateCooldown(objectiveAndRespawn)	
	objectiveAndRespawn.Cooldown:Hide()
	

	objectiveAndRespawn.Cooldown:SetScript("OnHide", function() 
		ObjectiveAndRespawn:Reset()
	end)
	-- ObjectiveAndRespawn.Cooldown:SetScript("OnCooldownDone", function() 
	-- 	ObjectiveAndRespawn:Reset()
	-- end)
	objectiveAndRespawn:SetScript("OnHide", function(self) 
		BattleGroundEnemies:Debug("ObjectiveAndRespawn hidden")
		self:SetAlpha(0)
	end)
	
	objectiveAndRespawn:SetScript("OnShow", function(self) 
		BattleGroundEnemies:Debug("ObjectiveAndRespawn shown")
		self:SetAlpha(1)
	end)

	objectiveAndRespawn.Kotmoguorbs = function(self, unitID)
		--BattleGroundEnemies:Debug("Läüft")
		local battleGroundDebuffs = BattleGroundEnemies.BattleGroundDebuffs
		for i = 1, #battleGroundDebuffs do
			local index, name, _, amount, _, _, _, _, _, _, spellID, _, _, _, _, _, value2, value3, value4 = BattleGroundEnemies:FindAuraBySpellID(unitID, battleGroundDebuffs[i], 'HARMFUL')
			--values for orb debuff:
			--BattleGroundEnemies:Debug(value0, value1, value2, value3, value4, value5)
			-- value2 = Reduces healing received by value2
			-- value3 = Increases damage taken by value3
			-- value4 = Increases damage done by value4
			if value3 then
				if not self.Value then
					--BattleGroundEnemies:Debug("hier")
					--player just got the debuff
					self.Icon:SetTexture(GetSpellTexture(spellID))
					self:Show()
					--BattleGroundEnemies:Debug("Texture set")
				end
				if value3 ~= self.Value then
					self.AuraText:SetText(value3)
					self.Value = value3
				end
				return
			end
		end
	end
	
	objectiveAndRespawn.NotKotmogu = function(self, unitID)
		local battleGroundDebuffs = BattleGroundEnemies.BattleGroundDebuffs
		local name, amount, index, _
		for i = 1, #battleGroundDebuffs do
			index, name, _, amount = BattleGroundEnemies:FindAuraBySpellID(unitID, battleGroundDebuffs[i], 'HARMFUL')
			--values for orb debuff:
			--BattleGroundEnemies:Debug(value0, value1, value2, value3, value4, value5)
			-- value2 = Reduces healing received by value2
			-- value3 = Increases damage taken by value3
			-- value4 = Increases damage done by value4
			
			if amount then -- Focused Assault, Brutal Assault
				if amount ~= self.Value then
					self.AuraText:SetText(amount)
					self.Value = amount
				end
				return
			end
		end
	end 
	
	objectiveAndRespawn.SetPosition = function(self)
		BattleGroundEnemies.SetBasicPosition(self, self.config.BasicPoint, self.config.RelativeTo, self.config.RelativePoint, self.config.OffsetX)
	end
	
	objectiveAndRespawn.Reset = function(self)	
		self:Hide()
		self.Icon:SetTexture()
		self.AuraText:SetText("")
		self.ActiveRespawnTimer = false
	end
	
	objectiveAndRespawn.ApplySettings = function(self)
		if BattleGroundEnemies.BGSize == 15 then
			local conf = self.config
		
			self:SetWidth(conf.Width)		
			
			self.AuraText:SetTextColor(unpack(conf.Textcolor))
			self.AuraText:ApplyFontStringSettings(conf.Fontsize, conf.Outline, conf.EnableTextshadow, conf.TextShadowcolor)
			
			self.Cooldown:ApplyCooldownSettings(BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_ShowNumbers, true, true, {0, 0, 0, 0.75})
			self.Cooldown.Text:ApplyFontStringSettings(BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_Fontsize, BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_Outline, BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_EnableTextshadow, BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_TextShadowcolor)
			
			self:SetPosition()
		end
	end

	objectiveAndRespawn.ShowObjective = function(self)
		if BattleGroundEnemies.BattlegroundBuff then
			--BattleGroundEnemies:Debug(self:GetParent().PlayerName, "has buff")
			self.Icon:SetTexture(GetSpellTexture(BattleGroundEnemies.BattlegroundBuff[playerButton.PlayerIsEnemy and BattleGroundEnemies.EnemyFaction or BattleGroundEnemies.AllyFaction]))
			self:Show()
		end
		
		self.AuraText:SetText("")
		self.Value = false
	end
		
	objectiveAndRespawn.PlayerDied = function(self)	
		if (BattleGroundEnemies.IsRatedBG or (BattleGroundEnemies.TestmodeActive and BattleGroundEnemies.BGSize == 15)) and BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_RespawnEnabled  then
		--BattleGroundEnemies:Debug("UnitIsDead SetCooldown")
			if not self.ActiveRespawnTimer then
				self:Show()
				self.Icon:SetTexture(GetSpellTexture(8326))
				self.AuraText:SetText("")
				self.ActiveRespawnTimer = true
			end
			self.Cooldown:SetCooldown(GetTime(), 26) --overwrite an already active timer
		end
	end

	objectiveAndRespawn.PlayerRevived = function(self)
		if self.ActiveRespawnTimer then --player is alive again
			self.Cooldown:Clear()
		end
	end


	objectiveAndRespawn.ApplySettings = function(self)
		local config = self.config
	
		self:SetWidth(config.Width or playerButton:GetHeight())		
		
		self.AuraText:SetTextColor(unpack(config.Textcolor))
		self.AuraText:ApplyFontStringSettings(config.Fontsize, config.Outline, config.EnableTextshadow, config.TextShadowcolor)
		
		self.Cooldown:ApplyCooldownSettings(BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_ShowNumbers, true, true, {0, 0, 0, 0.75})
		self.Cooldown.Text:ApplyFontStringSettings(BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_Fontsize, BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_Outline, BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_EnableTextshadow, BattleGroundEnemies.db.profile.RBG.ObjectiveAndRespawn_Cooldown_TextShadowcolor)
	end
	
	
	objectiveAndRespawn.NewPlayer = function(self)
		if true then return end
	end

	objectiveAndRespawn.Reset = function(self)
		self:Hide()
		self.Icon:SetTexture()
		self.AuraText:SetText("")
		self.ActiveRespawnTimer = false
	end
	
	objectiveAndRespawn.Test = function(self)
		if playerButton.ObjectiveAndRespawn.ActiveRespawnTimer then return end --when the respawn timer is shown dont change anything
		if testFlagCarrier and testFlagCarrier == playerButton then

			-- this player lost the flag
			self.AuraText:SetText("")
			self.Icon:SetTexture("")
			self:Hide()
			testFlagCarrier = false
		else
			if playerButton.isAlive then
				-- this player is now carrying a flag
				self.AuraText:SetText(mathrandom(1,9))
				self.Icon:SetTexture(GetSpellTexture(46392))
				self:Show()
				testFlagCarrier = playerButton
			end
		end
	end
	return objectiveAndRespawn
end


local ArenaIDToPlayerButton = {}
function ObjectiveAndRespawn:ARENA_OPPONENT_UPDATE(unitEvent, unitID)
	if unitEvent == "cleared" then
		local playerButton = ArenaIDToPlayerButton[unitID]
		if playerButton then
			playerButton.ObjectiveAndRespawn:UnregisterAllEvents()
		end
	else
		local playerButton = self.MainFrame.GetPlayerbuttonByUnitID(unitID)
		if playerButton.ObjectiveAndRespawn.config.ObjectiveEnabled then
			playerButton.ObjectiveAndRespawn:ShowObjective()
		
			
			ArenaIDToPlayerButton[unitID] = playerButton

			playerButton.ObjectiveAndRespawn:RegisterUnitEvent("UNIT_AURA", unitID)
			playerButton.ObjectiveAndRespawn:SetScript("OnEvent", function(self, unitID)
				if BattleGroundEnemies.BattleGroundDebuffs then
					if CurrentMapID == 417 then --417 is kotmogu
						playerButton:Kotmoguorbs(unitID)
					else
						playerButton:NotKotmogu(unitID)
					end
				end
			end)
		end
	end
end

BattleGroundEnemies:RegisterModule("ObjectiveAndRespawn", ObjectiveAndRespawn, true, defaults, options, {General = {"ARENA_OPPONENT_UPDATE"}})