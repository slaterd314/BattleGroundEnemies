
local addonName, Data = ...

local LSM = LibStub("LibSharedMedia-3.0")

-- health name it powerBar, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local PowerBarColor = PowerBarColor
local mathrandom = math.random


local L = Data.L

local defaults =  {
	Enabled = false,
	Texture = 'UI-StatusBar',
	Background = {0, 0, 0, 0.66}
}

local options = {
	All = {
		Texture = {
			type = "select",
			name = L.BarTexture,
			desc = L.powerBar_Texture_Desc,
			dialogControl = 'LSM30_Statusbar',
			values = AceGUIWidgetLSMlists.statusbar,
			width = "normal",
			order = 1
		},
		Fake = Data.optionHelpers.addVerticalSpacing(2),
		Background = {
			type = "color",
			name = L.BarBackground,
			desc = L.powerBar_Background_Desc,
			hasAlpha = true,
			width = "normal",
			order = 3
		},
	}
}
	
	


local PowerBar = {} 

PowerBar.AttachToButton = function(self, playerButton)
	local powerBar = CreateFrame('StatusBar', nil, playerButton)
	powerBar:SetPoint('BOTTOMLEFT', playerButton.Spec, "BOTTOMRIGHT")
	powerBar:SetPoint('BOTTOMRIGHT', playerButton, "BOTTOMRIGHT")
	powerBar:SetMinMaxValues(0, 1)

	
	--playerButton.Power.Background = playerButton.Power:CreateTexture(nil, 'BACKGROUND', nil, 2)
	powerBar.Background = powerBar:CreateTexture(nil, 'BACKGROUND', nil, 2)
	powerBar.Background:SetAllPoints()
	powerBar.Background:SetTexture("Interface/Buttons/WHITE8X8")

	powerBar.CheckForNewPowerColor = function(self, powerToken)
		if self.powerToken ~= powerToken then
			local color = PowerBarColor[powerToken]
			if color then
				self:SetStatusBarColor(color.r, color.g, color.b)
				self.powerToken = powerToken
			end
		end
	end

	powerBar.ApplySettings = function(self)
		self:SetHeight(self.config.Enabled and self.config.Height or 0.01)
		self:SetStatusBarTexture(LSM:Fetch("statusbar", self.config.Texture))--self.healthBar:SetStatusBarTexture(137012)
		self.Background:SetVertexColor(unpack(self.config.Background))
	end
	
	powerBar.NewPlayer = function(self)
		local powerToken
		if isTBCC then
			powerToken = PowerBarColor[Data.Classes[playerButton.PlayerClass].Ressource]
		else
			powerToken = PowerBarColor[Data.Classes[playerButton.PlayerClass][playerButton.PlayerSpecName].Ressource]
		end
		
		self:CheckForNewPowerColor(powerToken)
	end
	
	powerBar.Reset = function(self)
		self:SetMinMaxValues(0, 1)
		self:SetValue(1)
	end
	
	powerBar.UpdateForUnit = function(self, unitID, powerToken)
		if not (playerButton.isShown and self:IsShown()) then return end
		BattleGroundEnemies.Counter.UpdatePower = (BattleGroundEnemies.Counter.UpdateRange or 0) + 1
	
		if powerToken then
			self:CheckForNewPowerColor(playerButton, powerToken)
		else
			local powerType, powerToken, altR, altG, altB = UnitPowerType(unitID)
			self:CheckForNewPowerColor(playerButton, powerToken)
		end
		self:SetValue(UnitPower(unitID)/UnitPowerMax(unitID))
	end
	
	powerBar.Test = function(self)
		if not self.Enabled then return end 
		self:SetValue(mathrandom(0, 100))
	end
	return powerBar
end

function PowerBar:UNIT_POWER_FREQUENT(unitID, powerToken)
	local playerButton = self.MainFrame:GetPlayerbuttonByUnitID(unitID)
	if playerButton and playerButton.isShown then --unit is a shown player
		self.PowerBar:UpdateForUnit(playerButton, unitID, powerToken)
	end
end

BattleGroundEnemies:RegisterModule("PowerBar", PowerBar, true, defaults, options, {General = {"UNIT_POWER_FREQUENT"}})