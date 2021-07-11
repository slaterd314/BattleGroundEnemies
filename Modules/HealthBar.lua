
local addonName, Data = ...

local LSM = LibStub("LibSharedMedia-3.0")


-- health name it healthBar, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local mathrandom = math.random

local L = Data.L


local defaults =  {
	Enabled = true,
	Texture = 'UI-StatusBar',
	Background = {0, 0, 0, 0.66}
}

local options = {
	All = {
		Texture = {
			type = "select",
			name = L.BarTexture,
			desc = L.Texture_Desc,
			dialogControl = 'LSM30_Statusbar',
			values = AceGUIWidgetLSMlists.statusbar,
			width = "normal",
			order = 1
		},
		Fake = Data.optionHelpers.addHorizontalSpacing(2),
		Background = {
			type = "color",
			name = L.BarBackground,
			desc = L.Background_Desc,
			hasAlpha = true,
			width = "normal",
			order = 3
		},
		Fake = Data.optionHelpers.addVerticalSpacing(4),
		HealthPrediction_Enabled = {
			type = "toggle",
			name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYHEALPREDICTION,
			width = "normal",
			order = 5,
		}
	}
}


	
	


local HealthBar = {} 


HealthBar.AttachToButton = function(self, playerButton)
	local healthBar = CreateFrame('StatusBar', nil, playerButton)
	healthBar:SetPoint('BOTTOMLEFT', playerButton, "BOTTOMLEFT")
	healthBar:SetPoint('TOPRIGHT', playerButton, "TOPRIGHT")
	healthBar:SetMinMaxValues(0, 1)
	
	playerButton.myHealPrediction = healthBar:CreateTexture(nil, "BORDER", nil, 5)
	playerButton.myHealPrediction:ClearAllPoints();
	playerButton.myHealPrediction:SetColorTexture(1,1,1);
	playerButton.myHealPrediction:SetGradient("VERTICAL", 8/255, 93/255, 72/255, 11/255, 136/255, 105/255);
	playerButton.myHealPrediction:SetVertexColor(0.0, 0.659, 0.608);
	
	
	playerButton.myHealAbsorb = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
	playerButton.myHealAbsorb:ClearAllPoints();
	playerButton.myHealAbsorb:SetTexture("Interface\\RaidFrame\\Absorb-Fill", true, true);
	
	playerButton.myHealAbsorbLeftShadow = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
	playerButton.myHealAbsorbLeftShadow:ClearAllPoints();
	
	playerButton.myHealAbsorbRightShadow = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
	playerButton.myHealAbsorbRightShadow:ClearAllPoints();
	
	playerButton.otherHealPrediction = healthBar:CreateTexture(nil, "BORDER", nil, 5)
	playerButton.otherHealPrediction:SetColorTexture(1,1,1);
	playerButton.otherHealPrediction:SetGradient("VERTICAL", 11/255, 53/255, 43/255, 21/255, 89/255, 72/255);
	
	
	playerButton.totalAbsorbOverlay = healthBar:CreateTexture(nil, "BORDER", nil, 6)
	playerButton.totalAbsorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true);	--Tile both vertically and horizontally
	playerButton.totalAbsorbOverlay.tileSize = 20;
	
	playerButton.totalAbsorb = healthBar:CreateTexture(nil, "BORDER", nil, 5)
	playerButton.totalAbsorb:SetTexture("Interface\\RaidFrame\\Shield-Fill");
	playerButton.totalAbsorb.overlay = playerButton.totalAbsorbOverlay
	playerButton.totalAbsorbOverlay:SetAllPoints(playerButton.totalAbsorb);
	
	playerButton.overAbsorbGlow = healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
	playerButton.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield");
	playerButton.overAbsorbGlow:SetBlendMode("ADD");
	playerButton.overAbsorbGlow:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMRIGHT", -7, 0);
	playerButton.overAbsorbGlow:SetPoint("TOPLEFT", healthBar, "TOPRIGHT", -7, 0);
	playerButton.overAbsorbGlow:SetWidth(16);
	playerButton.overAbsorbGlow:Hide()
	
	playerButton.overHealAbsorbGlow = healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
	playerButton.overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb");
	playerButton.overHealAbsorbGlow:SetBlendMode("ADD");
	playerButton.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMLEFT", 7, 0);
	playerButton.overHealAbsorbGlow:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", 7, 0);
	playerButton.overHealAbsorbGlow:SetWidth(16);
	playerButton.overHealAbsorbGlow:Hide()
	
	
	healthBar.Background = healthBar:CreateTexture(nil, 'BACKGROUND', nil, 2)
	healthBar.Background:SetAllPoints()
	healthBar.Background:SetTexture("Interface/Buttons/WHITE8X8")

	healthBar.ApplySettings = function(self)
		self:SetStatusBarTexture(LSM:Fetch("statusbar", self.config.Texture))--self.healthBar:SetStatusBarTexture(137012)
		self.Background:SetVertexColor(unpack(self.config.Background))
	end
	
	
	
	healthBar.NewPlayer = function(self)
		local color = playerButton.PlayerClassColor
		self:SetStatusBarColor(color.r,color.g,color.b)
		self:SetMinMaxValues(0, 1)
		self:SetValue(1)
	end
	
	healthBar.Reset = function(self)
		self:SetMinMaxValues(0, 1)
		self:SetValue(1)
	end

	healthBar.PlayerIsDead = function(self)
		if playerButton.isAlive then
			self.MainFrame:RunModuleFunction(playerButton, "PlayerDied")
			self:SetValue(0)
		end
		playerButton.isAlive = false
	end

	healthBar.PlayerIsAlive	= function(self)
		if not playerButton.isAlive then
			self.MainFrame:RunModuleFunction(playerButton, "PlayerRevived")
		end
		playerButton.isAlive = true
	end


	healthBar.UpdateForUnit = function(self, unitID)
		self:SetMinMaxValues(0, UnitHealthMax(unitID))
		self:SetValue(UnitHealth(unitID))
		
		if UnitIsDeadOrGhost(unitID) then
			self:PlayerIsDead()
		else
			self:PlayerIsAlive()
		end

		playerButton.displayedUnit = unitID
		playerButton.optionTable = {displayHealPrediction = self.config.HealthPrediction_Enabled}
		if not isTBCC then CompactUnitFrame_UpdateHealPrediction(playerButton) end
	end
	
	healthBar.Test = function(self)
		self:SetMinMaxValues(0, 100)
		local health = mathrandom(0, 100)
		if playerButton.ObjectiveAndRespawn.ActiveRespawnTimer then return end --when the respawn timer is shown dont change anything

		if health == 0 then --don't let players die that are holding a flag at the moment
			--BattleGroundEnemies:Debug("dead")
			self:PlayerIsDead()
		else --player is alive
			self:SetValue(health)
			self:PlayerIsAlive()
		end
	end

	playerButton.healthBar = healthBar
	return playerButton.healthBar
end


local CombatLogevents = {}

--CombatLogevents.SPELL_DISPEL = CombatLogevents.SPELL_AURA_REMOVED

function CombatLogevents.UNIT_DIED(self, _, destName, _, _, _)
	--self:Debug("subevent", destName, "UNIT_DIED")
	local playerButton = self.MainFrame:GetPlayerbuttonByName(destName)
	if playerButton then
		playerButton.HealthBar:PlayerIsDead()
	end
end

ObjectiveAndRespawn.COMBAT_LOG_EVENT_UNFILTERED = function(self)
	local timestamp,subevent,hide,srcGUID,srcName,srcF1,srcF2,destGUID,destName,destF1,destF2,spellID,spellName,spellSchool, auraType = CombatLogGetCurrentEventInfo()
	if CombatLogevents[subevent] then 
		return CombatLogevents[subevent](self, srcName, destName, spellID, spellName, auraType) 
	end
end

HealthBar.UNIT_HEALTH = function(self, unitID)
	local playerButton = self.MainFrame:GetPlayerbuttonByUnitID(unitID)
	if playerButton and playerButton.isShown then --unit is a shown player
		self:UpdateForUnit(playerButton, unitID)
	end
end

HealthBar.UNIT_HEALTH_FREQUENT = HealthBar.UNIT_HEALTH --TBC compability, isTBCC
HealthBar.UNIT_MAXHEALTH = HealthBar.UNIT_HEALTH --TBC compability, isTBCC
HealthBar.UNIT_HEAL_PREDICTION = HealthBar.UNIT_HEALTH --TBC compability, isTBCC
HealthBar.UNIT_ABSORB_AMOUNT_CHANGED = HealthBar.UNIT_HEALTH --TBC compability, isTBCC
HealthBar.UNIT_HEAL_ABSORB_AMOUNT_CHANGED = HealthBar.UNIT_HEALTH --TBC compability, isTBCC

BattleGroundEnemies:RegisterModule("HealthBar", HealthBar, false, defaults, options, {General = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}, TBCC = {"UNIT_HEALTH_FREQUENT"}, Retail = {"UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"}})  -- module needs to be written with lowercase for the CompactUnitFrame_UpdateHealPrediction function