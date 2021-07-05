
local addonName, Data = ...
-- health name it healthBar, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction

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
	HealthBar_Texture = 'UI-StatusBar',
	HealthBar_Background = {0, 0, 0, 0.66}
}

local options = {
	HealthBar_Texture = {
		type = "select",
		name = L.BarTexture,
		desc = L.HealthBar_Texture_Desc,
		dialogControl = 'LSM30_Statusbar',
		values = AceGUIWidgetLSMlists.statusbar,
		width = "normal",
		order = 1
	},
	Fake = addHorizontalSpacing(2),
	HealthBar_Background = {
		type = "color",
		name = L.BarBackground,
		desc = L.HealthBar_Background_Desc,
		hasAlpha = true,
		width = "normal",
		order = 3
	},
	Fake = addVerticalSpacing(4),
	HealthBar_HealthPrediction_Enabled = {
		type = "toggle",
		name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYHEALPREDICTION,
		width = "normal",
		order = 5,
	}
}
	
	


local healthBar = BattleGroundEnemies:RegisterModule("healthBar", defaults, options)
healthBar:SetScript("OnEvent", function(self, event, ...)
	BattleGroundEnemies:Debug("BattleGroundEnemies OnEvent", event, ...)
	self[event](self, ...) 
end)


healthBar.AttachToButton = function(self, playerButton)
	playerButton.healthBar = CreateFrame('StatusBar', nil, playerButton)
	playerButton.healthBar:SetPoint('BOTTOMLEFT', playerButton, "BOTTOMLEFT")
	playerButton.healthBar:SetPoint('TOPRIGHT', playerButton, "TOPRIGHT")
	playerButton.healthBar:SetMinMaxValues(0, 1)
	
	playerButton.myHealPrediction = playerButton.healthBar:CreateTexture(nil, "BORDER", nil, 5)
	playerButton.myHealPrediction:ClearAllPoints();
	playerButton.myHealPrediction:SetColorTexture(1,1,1);
	playerButton.myHealPrediction:SetGradient("VERTICAL", 8/255, 93/255, 72/255, 11/255, 136/255, 105/255);
	playerButton.myHealPrediction:SetVertexColor(0.0, 0.659, 0.608);
	
	
	playerButton.myHealAbsorb = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
	playerButton.myHealAbsorb:ClearAllPoints();
	playerButton.myHealAbsorb:SetTexture("Interface\\RaidFrame\\Absorb-Fill", true, true);
	
	playerButton.myHealAbsorbLeftShadow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
	playerButton.myHealAbsorbLeftShadow:ClearAllPoints();
	
	playerButton.myHealAbsorbRightShadow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
	playerButton.myHealAbsorbRightShadow:ClearAllPoints();
	
	playerButton.otherHealPrediction = playerButton.healthBar:CreateTexture(nil, "BORDER", nil, 5)
	playerButton.otherHealPrediction:SetColorTexture(1,1,1);
	playerButton.otherHealPrediction:SetGradient("VERTICAL", 11/255, 53/255, 43/255, 21/255, 89/255, 72/255);
	
	
	playerButton.totalAbsorbOverlay = playerButton.healthBar:CreateTexture(nil, "BORDER", nil, 6)
	playerButton.totalAbsorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true);	--Tile both vertically and horizontally
	playerButton.totalAbsorbOverlay.tileSize = 20;
	
	playerButton.totalAbsorb = playerButton.healthBar:CreateTexture(nil, "BORDER", nil, 5)
	playerButton.totalAbsorb:SetTexture("Interface\\RaidFrame\\Shield-Fill");
	playerButton.totalAbsorb.overlay = playerButton.totalAbsorbOverlay
	playerButton.totalAbsorbOverlay:SetAllPoints(playerButton.totalAbsorb);
	
	playerButton.overAbsorbGlow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
	playerButton.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield");
	playerButton.overAbsorbGlow:SetBlendMode("ADD");
	playerButton.overAbsorbGlow:SetPoint("BOTTOMLEFT", playerButton.healthBar, "BOTTOMRIGHT", -7, 0);
	playerButton.overAbsorbGlow:SetPoint("TOPLEFT", playerButton.healthBar, "TOPRIGHT", -7, 0);
	playerButton.overAbsorbGlow:SetWidth(16);
	playerButton.overAbsorbGlow:Hide()
	
	playerButton.overHealAbsorbGlow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
	playerButton.overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb");
	playerButton.overHealAbsorbGlow:SetBlendMode("ADD");
	playerButton.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", playerButton.healthBar, "BOTTOMLEFT", 7, 0);
	playerButton.overHealAbsorbGlow:SetPoint("TOPRIGHT", playerButton.healthBar, "TOPLEFT", 7, 0);
	playerButton.overHealAbsorbGlow:SetWidth(16);
	playerButton.overHealAbsorbGlow:Hide()
	
	
	playerButton.healthBar.Background = playerButton.healthBar:CreateTexture(nil, 'BACKGROUND', nil, 2)
	playerButton.healthBar.Background:SetAllPoints()
	playerButton.healthBar.Background:SetTexture("Interface/Buttons/WHITE8X8")
end

healthBar.Enable = function(self, playerButton)
	local GeneralEvents = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}
	local TBCCEvents = {"UNIT_HEALTH_FREQUENT"}
	local RetailEvents = {"UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"}
	if isTBCC then
		Mixin(GeneralEvents, TBCCEvents)
	elseif isRetail then
		Mixin(GeneralEvents, RetailEvents)
	end

	for i = 1, #GeneralEvents do
		healthBar:RegisterEvent(GeneralEvents(i))
	end
	playerButton.healthBar:Show()
end

healthBar.UNIT_HEALTH = function(self, unitID)
	local playerButton = BattleGroundEnemies:GetPlayerbuttonByUnitID(unitID)
	if playerButton and playerButton.isShown then --unit is a shown player
		self:Update(playerButton, unitID)
	end
end

healthBar.UNIT_HEALTH_FREQUENT = healthBar.UNIT_HEALTH --TBC compability, isTBCC
healthBar.UNIT_MAXHEALTH = healthBar.UNIT_HEALTH --TBC compability, isTBCC
healthBar.UNIT_HEAL_PREDICTION = healthBar.UNIT_HEALTH --TBC compability, isTBCC
healthBar.UNIT_ABSORB_AMOUNT_CHANGED = healthBar.UNIT_HEALTH --TBC compability, isTBCC
healthBar.UNIT_HEAL_ABSORB_AMOUNT_CHANGED = healthBar.UNIT_HEALTH --TBC compability, isTBCC

healthBar.Disable = function(self, playerButton)
	self:UnregisterAllEvents()
	playerButton.healthBar:Hide()
end


healthBar.ApplySettings = function(self, playerButton, config)
	playerButton.healthBar.config = config
	playerButton.healthBar:SetStatusBarTexture(LSM:Fetch("statusbar", config.HealthBar_Texture))--self.healthBar:SetStatusBarTexture(137012)
	playerButton.healthBar.Background:SetVertexColor(unpack(config.HealthBar_Background))
end



healthBar.NewPlayer = function(self, playerButton)
	local color = playerButton.PlayerClassColor
	playerButton.healthBar:SetStatusBarColor(color.r,color.g,color.b)
	playerButton.healthBar:SetMinMaxValues(0, 1)
	playerButton.healthBar:SetValue(1)
end

healthBar.Reset = function(self, playerButton)
	playerButton.healthBar:SetMinMaxValues(0, 1)
	playerButton.healthBar:SetValue(1)
end

healthBar.Update = function(self, playerButton, unitID)
	playerButton.healthBar:SetMinMaxValues(0, UnitHealthMax(unitID))
	playerButton.healthBar:SetValue(UnitHealth(unitID))
	playerButton.displayedUnit = unitID
	playerButton.optionTable = {displayHealPrediction = playerButton.bgSizeConfig.HealthBar_HealthPrediction_Enabled}
	if not isTBCC then CompactUnitFrame_UpdateHealPrediction(playerButton) end
end


	











	