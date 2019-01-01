local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local ElvUF = ElvUI.oUF

local NP = E:NewModule('NamePlates', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local LSM = LibStub('LibSharedMedia-3.0')

--Cache global variables
--Lua functions
local pairs = pairs
local type = type
local gsub = gsub
local wipe = table.wipe
local format = string.format
local strmatch = string.match
local strjoin = strjoin
local tonumber = tonumber
local unpack = unpack

--WoW API / Variables
local CreateFrame = CreateFrame
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction
local SetCVar, GetCVarDefault = SetCVar, GetCVarDefault
local UnitFactionGroup = UnitFactionGroup
local UnitIsPVPSanctuary = UnitIsPVPSanctuary
local UnitCanAttack = UnitCanAttack
local UnitIsFriend = UnitIsFriend
local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local Lerp = Lerp
local C_NamePlate = C_NamePlate

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: NamePlateDriverFrame, UIParent, WorldFrame
-- GLOBALS: CUSTOM_CLASS_COLORS, ADDITIONAL_POWER_BAR_NAME

function NP:StyleFrame(frame, useMainFrame)
	local parent = frame

	if (parent:IsObjectType('Texture')) then
		parent = frame:GetParent()
	end

	if useMainFrame then
		parent:SetTemplate("Transparent")
		return
	end

	parent:CreateBackdrop("Transparent")
end

function NP:Style(frame, unit)
	if (not unit) then
		return
	end

	if unit:match('nameplate') then
		NP:StylePlate(frame, unit)
	else
		E:GetModule('UnitFrames'):Construct_UF(frame, unit)
	end

	return frame
end

function NP:StylePlate(nameplate, realUnit)
	local Texture = LSM:Fetch('statusbar', self.db.statusbar)
	local Font, FontSize, FontFlag = LSM:Fetch('font', self.db.font), self.db.fontSize, self.db.fontOutline

	nameplate.Health = NP:Construct_HealthBar(nameplate)
	nameplate.Health.Text = NP:Construct_TagText(nameplate)
	nameplate.Health.Text:SetPoint('CENTER', nameplate.Health, 'CENTER', 0, 0) -- need option
	nameplate:Tag(nameplate.Health.Text, '[perhp]%') -- need option

	nameplate.HealthPrediction = NP:Construct_HealthPrediction(nameplate)

	nameplate.Power = NP:Construct_PowerBar(nameplate)
	nameplate.Power.Text = NP:Construct_TagText(nameplate)
	nameplate.Power.Text:SetPoint('CENTER', nameplate.Power, 'CENTER', 0, 0) -- need option
	nameplate:Tag(nameplate.Power.Text, '[perpp]%') -- need option

	nameplate.PowerPrediction = NP:Construct_PowerPrediction(nameplate)

	local Health = nameplate.Health

	local CastBar = CreateFrame('StatusBar', nil, nameplate)

	local Name = nameplate:CreateFontString(nil, 'OVERLAY')
	local Level = nameplate:CreateFontString(nil, 'OVERLAY')
	local Info = nameplate:CreateFontString(nil, 'OVERLAY')
	local RaidIcon = nameplate:CreateTexture(nil, 'OVERLAY')
	local QuestIcons = CreateFrame('Frame', nil, nameplate)

	nameplate:SetPoint('CENTER')
	nameplate:SetSize(self.db.clickableWidth, self.db.clickableHeight)
	nameplate:SetScale(UIParent:GetEffectiveScale())

	CastBar:SetFrameStrata(nameplate:GetFrameStrata())
	CastBar:SetStatusBarTexture(Texture)
	CastBar:SetFrameLevel(6)
	CastBar:CreateBackdrop('Transparent')
	CastBar:SetHeight(16) -- need option
	CastBar:SetPoint('TOPLEFT', Health, 'BOTTOMLEFT', 0, -20) -- need option
	CastBar:SetPoint('TOPRIGHT', Health, 'BOTTOMRIGHT', 0, -20) -- need option

	CastBar.Button = CreateFrame('Frame', nil, CastBar)
	CastBar.Button:SetSize(18, 18) -- need option
	CastBar.Button:SetTemplate()
	CastBar.Button:SetPoint('RIGHT', CastBar, 'LEFT', -6, 0) -- need option

	CastBar.Icon = CastBar.Button:CreateTexture(nil, 'ARTWORK')
	CastBar.Icon:SetInside()
	CastBar.Icon:SetTexCoord(unpack(E.TexCoords))

	CastBar.Time = CastBar:CreateFontString(nil, 'OVERLAY')
	CastBar.Time:SetFont(Font, FontSize, FontFlag)
	CastBar.Time:SetPoint('RIGHT', CastBar, 'RIGHT', -4, 0)
	CastBar.Time:SetTextColor(0.84, 0.75, 0.65)
	CastBar.Time:SetJustifyH('RIGHT')

	CastBar.Text = CastBar:CreateFontString(nil, 'OVERLAY')
	CastBar.Text:SetFont(Font, FontSize, FontFlag)
	CastBar.Text:SetPoint('LEFT', CastBar, 'LEFT', 4, 0) -- need option
	CastBar.Text:SetTextColor(0.84, 0.75, 0.65)
	CastBar.Text:SetJustifyH('LEFT')
	CastBar.Text:SetSize(75, 16) -- need option

	local function CheckInterrupt(castbar, unit)
		if (unit == 'vehicle') then
			unit = 'player'
		end

		if (castbar.notInterruptible and UnitCanAttack('player', unit)) then
			castbar:SetStatusBarColor(0.87, 0.37, 0.37, 0.7)
		else
			castbar:SetStatusBarColor(0.29, 0.67, 0.30, 0.7)
		end
	end

	CastBar.PostCastStart = CheckInterrupt
	CastBar.PostCastInterruptible = CheckInterrupt
	CastBar.PostCastNotInterruptible = CheckInterrupt
	CastBar.PostChannelStart = CheckInterrupt

	Name:SetPoint('BOTTOMLEFT', Health, 'TOPLEFT', 0, E.Border*2) -- need option
	Name:SetJustifyH('LEFT')
	Name:SetJustifyV('BOTTOM')
	Name:SetFont(Font, FontSize, FontFlag)
	Name:SetWordWrap(false)

	Level:SetPoint('BOTTOMRIGHT', Health, 'TOPRIGHT', 0, E.Border*2) -- need option
	Level:SetJustifyH('RIGHT')
	Level:SetFont(Font, FontSize, FontFlag)

	RaidIcon:SetPoint('TOP', Health, 0, 8) -- need option
	RaidIcon:SetSize(16, 16)

	QuestIcons:Hide()
	QuestIcons:SetSize(self.db.questIconSize, self.db.questIconSize)
	QuestIcons:SetPoint("LEFT", Health, "RIGHT", 4, 0) -- need option

	local Item = QuestIcons:CreateTexture(nil, 'BORDER', nil, 1)
	Item:SetPoint('TOPLEFT')
	Item:SetSize(self.db.questIconSize, self.db.questIconSize)
	Item:SetTexCoord(unpack(E.TexCoords))
	Item:Hide()
	QuestIcons.Item = Item

	local Loot = QuestIcons:CreateTexture(nil, 'BORDER', nil, 1)
	Loot:SetPoint('TOPLEFT')
	Loot:SetSize(self.db.questIconSize, self.db.questIconSize)
	Loot:Hide()
	QuestIcons.Loot = Loot

	local Skull = QuestIcons:CreateTexture(nil, 'BORDER', nil, 1)
	Skull:SetPoint('TOPLEFT')
	Skull:SetSize(self.db.questIconSize + 4, self.db.questIconSize + 4)
	Skull:Hide()
	QuestIcons.Skull = Skull

	local Chat = QuestIcons:CreateTexture(nil, 'BORDER', nil, 1)
	Chat:SetPoint('TOPLEFT')
	Chat:SetSize(self.db.questIconSize + 4, self.db.questIconSize + 4)
	Chat:SetTexture([[Interface\WorldMap\ChatBubble_64.PNG]])
	Chat:SetTexCoord(0, 0.5, 0.5, 1)
	Chat:Hide()
	QuestIcons.Chat = Chat

	local Text = QuestIcons:CreateFontString(nil, 'OVERLAY')
	Text:SetPoint('BOTTOMRIGHT', QuestIcons, 2, -0.8)
	Text:SetFont(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
	QuestIcons.Text = Text

	nameplate:Tag(Name, '[namecolor][name:abbrev] [npctitle]')
	nameplate:Tag(Level, '[difficultycolor][level]')
	--nameplate:Tag(Info, '[quest:info]')

	--local PvP = Health:CreateTexture(nil, 'OVERLAY')
	--PvP:Size(36, 36)
	--PvP:Point('CENTER', Health)

	local RaidTargetIndicator = Health:CreateTexture(nil, 'OVERLAY', 7)
	RaidTargetIndicator:SetSize(24, 24)
	RaidTargetIndicator:Point('BOTTOM', Health, 'TOP', 0, 24)
	RaidTargetIndicator.Override = function(ele, event)
		local element = ele.RaidTargetIndicator

		if ele.unit then
			local index = GetRaidTargetIndex(ele.unit)
			if (index) and not UnitIsUnit(ele.unit, 'player') then
				SetRaidTargetIconTexture(element, index)
				element:Show()
			else
				element:Hide()
			end
		end
	end

	local ThreatIndicator = Health:CreateTexture(nil, 'OVERLAY')
	ThreatIndicator:SetSize(16, 16)
	ThreatIndicator:SetPoint('CENTER', Health, 'TOPRIGHT')
	ThreatIndicator.feedbackUnit = 'player'

	local ClassificationIndicator = nameplate:CreateTexture(nil, 'OVERLAY')
	ClassificationIndicator:SetSize(16, 16)
	ClassificationIndicator:SetPoint('RIGHT', Name, 'LEFT')

	nameplate.Castbar = CastBar

	nameplate.Name = Name
	nameplate.Level = Level
	nameplate.Info = Info

	nameplate.QuestIcons = QuestIcons
	nameplate.RaidTargetIndicator = RaidTargetIndicator
	--nameplate.PvPIndicator = PvP

	nameplate.ThreatIndicator = ThreatIndicator
	nameplate.ClassificationIndicator = ClassificationIndicator
end

function NP:UnitStyle(nameplate, unit)
	-- ['glowStyle'] = 'TARGET_THREAT',
	local db = self.db.units[unit]

	if (unit == 'FRIENDLY_NPC') or (unit == 'ENEMY_NPC') then
		nameplate.Health.colorClass = false
		nameplate.Health.colorReaction = true
	else
		nameplate.Health.colorClass = db.healthbar.useClassColor
		nameplate.Health.colorReaction = false
	end

	if db.healthbar.enable then
		nameplate:EnableElement('Health')
	else
		nameplate:DisableElement('Health')
	end

	if db.healthbar.enable and db.healthbar.healPrediction then
		nameplate:EnableElement('HealPrediction')
	else
		nameplate:DisableElement('HealPrediction')
	end

	if db.healthbar.text.enable then
		nameplate.Health.Text:Show()
	else
		nameplate.Health.Text:Hide()
	end

	nameplate.Health:SetSize(db.healthbar.width, db.healthbar.height)

	if db.powerbar.enable then
		nameplate:EnableElement('Power')
	else
		nameplate:DisableElement('Power')
	end

	if db.powerbar.enable and db.powerbar.costPrediction then
		nameplate:EnableElement('PowerPrediction')
	else
		nameplate:DisableElement('PowerPrediction')
	end

	if db.powerbar.text.enable then
		nameplate.Power.Text:Show()
	else
		nameplate.Power.Text:Hide()
	end

	nameplate.Power:SetSize(db.healthbar.width, db.powerbar.height)

	if db.showName then
		nameplate.Name:Show()
		nameplate.Name:ClearAllPoints()
		if not db.showLevel then
			nameplate.Name:SetPoint('BOTTOM', nameplate.Health, 'TOP', 0, E.Border*2) -- need option
			nameplate.Name:SetJustifyH('CENTER')
		else
			nameplate.Name:SetPoint('BOTTOMLEFT', nameplate.Health, 'TOPLEFT', 0, E.Border*2) -- need option
			nameplate.Name:SetJustifyH('LEFT')
			nameplate.Name:SetJustifyV('BOTTOM')
		end
	else
		nameplate.Name:Hide()
	end

	if db.showLevel then
		nameplate.Level:Show()
	else
		nameplate.Level:Hide()
	end

	nameplate:UpdateAllElements('OnShow')
end

function NP:CVarReset()
	SetCVar('nameplateClassResourceTopInset', GetCVarDefault('nameplateClassResourceTopInset'))
	SetCVar('nameplateGlobalScale', GetCVarDefault('nameplateGlobalScale'))
	SetCVar('NamePlateHorizontalScale', GetCVarDefault('NamePlateHorizontalScale'))
	SetCVar('nameplateLargeBottomInset', GetCVarDefault('nameplateLargeBottomInset'))
	SetCVar('nameplateLargerScale', GetCVarDefault('nameplateLargerScale'))
	SetCVar('nameplateLargeTopInset', GetCVarDefault('nameplateLargeTopInset'))
	SetCVar('nameplateMaxAlpha', GetCVarDefault('nameplateMaxAlpha'))
	SetCVar('nameplateMaxAlphaDistance', GetCVarDefault('nameplateMaxAlphaDistance'))
	SetCVar('nameplateMaxScale', GetCVarDefault('nameplateMaxScale'))
	SetCVar('nameplateMaxScaleDistance', GetCVarDefault('nameplateMaxScaleDistance'))
	SetCVar('nameplateMinAlpha', GetCVarDefault('nameplateMinAlpha'))
	SetCVar('nameplateMinAlphaDistance', GetCVarDefault('nameplateMinAlphaDistance'))
	SetCVar('nameplateMinScale', GetCVarDefault('nameplateMinScale'))
	SetCVar('nameplateMinScaleDistance', GetCVarDefault('nameplateMinScaleDistance'))
	SetCVar('nameplateMotionSpeed', GetCVarDefault('nameplateMotionSpeed'))
	SetCVar('nameplateOtherAtBase', GetCVarDefault('nameplateOtherAtBase'))
	SetCVar('nameplateOtherBottomInset', GetCVarDefault('nameplateOtherBottomInset'))
	SetCVar('nameplateOtherTopInset', GetCVarDefault('nameplateOtherTopInset'))
	SetCVar('nameplateOverlapH', GetCVarDefault('nameplateOverlapH'))
	SetCVar('nameplateOverlapV', GetCVarDefault('nameplateOverlapV'))
	SetCVar('nameplateResourceOnTarget', GetCVarDefault('nameplateResourceOnTarget'))
	SetCVar('nameplateSelectedAlpha', GetCVarDefault('nameplateSelectedAlpha'))
	SetCVar('nameplateSelectedScale', GetCVarDefault('nameplateSelectedScale'))
	SetCVar('nameplateSelfAlpha', GetCVarDefault('nameplateSelfAlpha'))
	SetCVar('nameplateSelfBottomInset', GetCVarDefault('nameplateSelfBottomInset'))
	SetCVar('nameplateSelfScale', GetCVarDefault('nameplateSelfScale'))
	SetCVar('nameplateSelfTopInset', GetCVarDefault('nameplateSelfTopInset'))
	SetCVar('nameplateShowEnemies', GetCVarDefault('nameplateShowEnemies'))
	SetCVar('nameplateShowEnemyGuardians', GetCVarDefault('nameplateShowEnemyGuardians'))
	SetCVar('nameplateShowEnemyPets', GetCVarDefault('nameplateShowEnemyPets'))
	SetCVar('nameplateShowEnemyTotems', GetCVarDefault('nameplateShowEnemyTotems'))
	SetCVar('nameplateShowFriendlyGuardians', GetCVarDefault('nameplateShowFriendlyGuardians'))
	SetCVar('nameplateShowFriendlyNPCs', GetCVarDefault('nameplateShowFriendlyNPCs'))
	SetCVar('nameplateShowFriendlyPets', GetCVarDefault('nameplateShowFriendlyPets'))
	SetCVar('nameplateShowFriendlyTotems', GetCVarDefault('nameplateShowFriendlyTotems'))
	SetCVar('nameplateShowFriends', GetCVarDefault('nameplateShowFriends'))
	SetCVar('nameplateTargetBehindMaxDistance', GetCVarDefault('nameplateTargetBehindMaxDistance'))
end

function NP:PLAYER_REGEN_DISABLED()
	if (self.db.showFriendlyCombat == "TOGGLE_ON") then
		SetCVar("nameplateShowFriends", 1);
	elseif (self.db.showFriendlyCombat == "TOGGLE_OFF") then
		SetCVar("nameplateShowFriends", 0);
	end

	if (self.db.showEnemyCombat == "TOGGLE_ON") then
		SetCVar("nameplateShowEnemies", 1);
	elseif (self.db.showEnemyCombat == "TOGGLE_OFF") then
		SetCVar("nameplateShowEnemies", 0);
	end

	--if self.db.units.PLAYER.useStaticPosition then
	--	self:UpdateVisibility()
	--end
end

function NP:PLAYER_REGEN_ENABLED()
	if (self.db.showFriendlyCombat == "TOGGLE_ON") then
		SetCVar("nameplateShowFriends", 0);
	elseif (self.db.showFriendlyCombat == "TOGGLE_OFF") then
		SetCVar("nameplateShowFriends", 1);
	end

	if (self.db.showEnemyCombat == "TOGGLE_ON") then
		SetCVar("nameplateShowEnemies", 0);
	elseif (self.db.showEnemyCombat == "TOGGLE_OFF") then
		SetCVar("nameplateShowEnemies", 1);
	end

	--if self.db.units.PLAYER.useStaticPosition then
	--	self:UpdateVisibility()
	--end
end

function NP:ConfigureAll()
	SetCVar('nameplateMaxDistance', NP.db.loadDistance)
	SetCVar('nameplateMotion', NP.db.motionType == 'STACKED' and 1 or 0)
	SetCVar('NameplatePersonalHideDelayAlpha', NP.db.units.PLAYER.visibility.hideDelay)
	SetCVar('NameplatePersonalShowAlways', (NP.db.units.PLAYER.visibility.showAlways == true and 1 or 0))
	SetCVar('NameplatePersonalShowInCombat', (NP.db.units.PLAYER.visibility.showInCombat == true and 1 or 0))
	SetCVar('NameplatePersonalShowWithTarget', (NP.db.units.PLAYER.visibility.showWithTarget == true and 1 or 0))
	SetCVar('nameplateShowAll', NP.db.displayStyle ~= 'ALL' and 0 or 1)
	SetCVar('nameplateShowFriendlyMinions', NP.db.units.FRIENDLY_PLAYER.minions == true and 1 or 0)
	SetCVar('nameplateShowEnemyMinions', NP.db.units.ENEMY_PLAYER.minions == true and 1 or 0)
	SetCVar('nameplateShowEnemyMinus', NP.db.units.ENEMY_NPC.minors == true and 1 or 0)
	SetCVar('nameplateShowSelf', (NP.db.units.PLAYER.useStaticPosition == true or NP.db.units.PLAYER.enable ~= true) and 0 or 1)
	SetCVar('showQuestTrackingTooltips', NP.db.questIcon and 1)

	C_NamePlate.SetNamePlateSelfSize(NP.db.clickableWidth, NP.db.clickableHeight)
	C_NamePlate.SetNamePlateEnemySize(NP.db.clickableWidth, NP.db.clickableHeight)

	-- workaround for #206
	local friendlyWidth, friendlyHeight

	if IsInInstance() then
		-- handle it just like blizzard does when using blizzard friendly plates
		local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"))
		local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"))
		local zeroBasedScale = namePlateVerticalScale - 1.0

		friendlyWidth = NamePlateDriverFrame.baseNamePlateWidth * horizontalScale
		friendlyHeight = NamePlateDriverFrame.baseNamePlateHeight * Lerp(1.0, 1.25, zeroBasedScale)
	end

	C_NamePlate.SetNamePlateFriendlySize(friendlyWidth or NP.db.clickableWidth, friendlyHeight or NP.db.clickableHeight)

	if (self.db.showFriendlyCombat == "TOGGLE_ON") then
		SetCVar("nameplateShowFriends", 0);
	elseif (self.db.showFriendlyCombat == "TOGGLE_OFF") then
		SetCVar("nameplateShowFriends", 1);
	end

	if (self.db.showEnemyCombat == "TOGGLE_ON") then
		SetCVar("nameplateShowEnemies", 0);
	elseif (self.db.showEnemyCombat == "TOGGLE_OFF") then
		SetCVar("nameplateShowEnemies", 1);
	end

	for nameplate in pairs(NP.Plates) do
		NP.NamePlateCallBack(nameplate, 'NAME_PLATE_UNIT_ADDED')
	end
end

local function CopySettings(from, to)
	for setting, value in pairs(from) do
		if(type(value) == "table" and to[setting] ~= nil) then
			CopySettings(from[setting], to[setting])
		else
			if(to[setting] ~= nil) then
				to[setting] = from[setting]
			end
		end
	end
end

function NP:ResetSettings(unit)
	CopySettings(P.nameplates.units[unit], self.db.units[unit])
end

function NP:CopySettings(from, to)
	if (from == to) then return end

	CopySettings(self.db.units[from], self.db.units[to])
end

function NP:NamePlateCallBack(nameplate, event, unit)
	if event == 'NAME_PLATE_UNIT_ADDED' then
		unit = unit or nameplate.unit
		local reaction = UnitReaction('player', unit)
		local faction = UnitFactionGroup(unit)

		if (UnitIsUnit(unit, 'player')) then
			NP:UnitStyle(nameplate, 'PLAYER')
		elseif (UnitIsPVPSanctuary(unit) or (UnitIsPlayer(unit) and UnitIsFriend('player', unit) and reaction and reaction >= 5)) then
			NP:UnitStyle(nameplate, 'FRIENDLY_PLAYER')
		elseif (not UnitIsPlayer(unit) and (reaction and reaction >= 5) or faction == 'Neutral') then
			NP:UnitStyle(nameplate, 'FRIENDLY_NPC')
		elseif (not UnitIsPlayer(unit) and (reaction and reaction <= 4)) then
			NP:UnitStyle(nameplate, 'ENEMY_NPC')
		else
			NP:UnitStyle(nameplate, 'ENEMY_PLAYER')
		end
		NP.Plates[nameplate] = true
	end
end

function NP:Initialize()
	self.db = E.db.nameplates

	if E.private.nameplates.enable ~= true then return end

	ElvUF:RegisterStyle('ElvNP', function(frame, unit)
		NP:Style(frame, unit)
	end)
	ElvUF:SetActiveStyle('ElvNP')

	NP.Plates = {}

	local BlizzPlateManaBar = NamePlateDriverFrame.classNamePlatePowerBar
	if BlizzPlateManaBar then
		BlizzPlateManaBar:Hide()
		BlizzPlateManaBar:UnregisterAllEvents()
	end

	hooksecurefunc(NamePlateDriverFrame, "SetupClassNameplateBars", function(frame)
		if frame.classNamePlateMechanicFrame then
			frame.classNamePlateMechanicFrame:Hide()
		end
		if frame.classNamePlatePowerBar then
			frame.classNamePlatePowerBar:Hide()
			frame.classNamePlatePowerBar:UnregisterAllEvents()
		end
	end)

	self.Tooltip = CreateFrame('GameTooltip', "ElvUIQuestTooltip", nil, 'GameTooltipTemplate')
	self.Tooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')

	ElvUF:SpawnNamePlates('ElvUF_', function(nameplate, event, unit)
		NP:NamePlateCallBack(nameplate, event, unit)
	end)

	NP:RegisterEvent('PLAYER_REGEN_ENABLED')
	NP:RegisterEvent('PLAYER_REGEN_DISABLED')

	E.NamePlates = self
end

local function InitializeCallback()
	NP:Initialize()
end

E:RegisterModule(NP:GetName(), InitializeCallback)
