
local addonName, Data = ...
-- health name it powerBar, to use Blizzard code from UnitFrame.lua  CompactUnitFrame_UpdateHealPrediction
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isTBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local BattleGroundEnemies = BattleGroundEnemies
local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction
local LSM = LibStub("LibSharedMedia-3.0")
local PowerBarColor = PowerBarColor

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
	Texture = 'UI-StatusBar',
	Background = {0, 0, 0, 0.66}
}

local options = {
	Texture = {
		type = "select",
		name = L.BarTexture,
		desc = L.powerBar_Texture_Desc,
		dialogControl = 'LSM30_Statusbar',
		values = AceGUIWidgetLSMlists.statusbar,
		width = "normal",
		order = 1
	},
	Fake = addHorizontalSpacing(2),
	Background = {
		type = "color",
		name = L.BarBackground,
		desc = L.powerBar_Background_Desc,
		hasAlpha = true,
		width = "normal",
		order = 3
	},
}
	
	


local powerBar = BattleGroundEnemies:RegisterModule("powerBar", defaults, options)
powerBar:SetScript("OnEvent", function(self, event, ...)
	BattleGroundEnemies:Debug("BattleGroundEnemies OnEvent", event, ...)
	self[event](self, ...) 
end)

powerBar.AttachToButton = function(self, playerButton)
	playerButton.powerBar = = CreateFrame('StatusBar', nil, playerButton)
	playerButton.powerBar:SetPoint('BOTTOMLEFT', playerButton.Spec, "BOTTOMRIGHT")
	playerButton.powerBar:SetPoint('BOTTOMRIGHT', playerButton, "BOTTOMRIGHT")
	playerButton.powerBar:SetMinMaxValues(0, 1)

	
	--playerButton.Power.Background = playerButton.Power:CreateTexture(nil, 'BACKGROUND', nil, 2)
	playerButton.powerBar.Background = playerButton.powerBar:CreateTexture(nil, 'BACKGROUND', nil, 2)
	playerButton.powerBar.Background:SetAllPoints()
	playerButton.powerBar.Background:SetTexture("Interface/Buttons/WHITE8X8")

	playerButton.powerBar.CheckForNewPowerColor = function(self, powerToken)
		if self.powerToken ~= powerToken then
			local color = PowerBarColor[powerToken]
			if color then
				self:SetStatusBarColor(color.r, color.g, color.b)
				self.powerToken = powerToken
			end
		end
	end
end

function powerBar:UNIT_POWER_FREQUENT(unitID, powerToken)
	local playerButton = BattleGroundEnemies:GetPlayerbuttonByUnitID(unitID)
	if playerButton and playerButton.isShown then --unit is a shown player
		self:Update(playerButton, unitID)
	end
end

powerBar.Enable = function(self, playerButton)
	powerBar:RegisterEvent("UNIT_POWER_FREQUENT")
	playerButton.powerBar:Show()
end

powerBar.Disable = function(self, playerButton)
	powerBar:UnregisterAllEvents()
	playerButton.powerBar:Hide()
end

powerBar.ApplySettings = function(self, playerButton, config)
	playerButton.powerBar.config = config
	playerButton.powerBar:SetHeight(config.Enabled and config.Height or 0.01)
	playerButton.powerBar:SetStatusBarTexture(LSM:Fetch("statusbar", config.Texture))--self.healthBar:SetStatusBarTexture(137012)
	playerButton.powerBar.Background:SetVertexColor(unpack(config.Background))
end

powerBar.NewPlayer = function(self, playerButton)
	local powerToken
	if isTBCC then
		powerToken = PowerBarColor[Data.Classes[playerButton.PlayerClass].Ressource]
	else
		powerToken = PowerBarColor[Data.Classes[playerButton.PlayerClass][playerButton.PlayerSpecName].Ressource]
	end
	
	playerButton.powerBar:CheckForNewPowerColor(powerToken)
end

powerBar.Reset = function(self, playerButton)
	playerButton.powerBar:SetMinMaxValues(0, 1)
	playerButton.powerBar:SetValue(1)
end

powerBar.Update = function(self, playerButton, unitID, powerToken)
	if not (playerButton.isShown and playerButton.powerBar:IsShown()) then return end
	BattleGroundEnemies.Counter.UpdatePower = (BattleGroundEnemies.Counter.UpdateRange or 0) + 1

	if powerToken then
		playerButton.powerBar:CheckForNewPowerColor(playerButton, powerToken)
	else
		local powerType, powerToken, altR, altG, altB = UnitPowerType(unitID)
		playerButton.powerBar:CheckForNewPowerColor(playerButton, powerToken)
	end
	playerButton.powerBar:SetValue(UnitPower(unitID)/UnitPowerMax(unitID))
end


	











	