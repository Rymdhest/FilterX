LF = LF or {}

local unpack = unpack;
local pairs = pairs;
local getmetatable = getmetatable;
local tRemove = table.remove;
local tInsert = table.insert;
local tWipe = table.wipe;

local LOOTALERT_NUM_BUTTONS = 4
local scale = 1
local offset_y =2
local point_x = 0
local point_y = 50
local uptime = 0.3
local sound = true
local animate = true

local UnitFactionGroup = UnitFactionGroup;
local PlaySoundFile = PlaySoundFile;
local GameTooltip = GameTooltip;
local playerFaction = UnitFactionGroup("player");
local HONOR_BACKGROUND_TCOORDS = {
	["Alliance"] = {277, 113, 0.001953, 0.542969, 0.460938, 0.902344},
	["Horde"] = {281, 115, 0.001953, 0.550781, 0.003906, 0.453125},
};
local SUB_COORDS = HONOR_BACKGROUND_TCOORDS[playerFaction];
local HONOR_BADGE = {SUB_COORDS[3], SUB_COORDS[4], SUB_COORDS[5], SUB_COORDS[6]};
YOU_RECEIVED_LABEL = "You Recieved"
local LE_ITEM_QUALITY_COMMON = 1;
local LE_ITEM_QUALITY_EPIC = 4;
local LE_ITEM_QUALITY_HEIRLOOM = 7;
local LE_ITEM_QUALITY_LEGENDARY = 5;
local LE_ITEM_QUALITY_POOR = 0;
local LE_ITEM_QUALITY_RARE = 3;
local LE_ITEM_QUALITY_UNCOMMON = 2;
local LE_ITEM_QUALITY_WOW_TOKEN = 8;
local LE_ITEM_QUALITY_ARTIFACT = 6;
local LOOT_BORDER_BY_QUALITY = {
	[LE_ITEM_QUALITY_POOR] = {1, 1, 1, 1},
	[LE_ITEM_QUALITY_COMMON] = {1, 1, 1, 1},
	[LE_ITEM_QUALITY_UNCOMMON] = {0.34082, 0.397461, 0.53125, 0.644531},
	[LE_ITEM_QUALITY_RARE] = {0.272461, 0.329102, 0.785156, 0.898438},
	[LE_ITEM_QUALITY_EPIC] = {0.34082, 0.397461, 0.882812, 0.996094},
	[LE_ITEM_QUALITY_LEGENDARY] = {0.34082, 0.397461, 0.765625, 0.878906},
	[LE_ITEM_QUALITY_HEIRLOOM] = {0.34082, 0.397461, 0.648438, 0.761719},
	[LE_ITEM_QUALITY_ARTIFACT] = {0.272461, 0.329102, 0.667969, 0.78125},
};

local assets = [[Interface\AddOns\FilterX\assets\]];
local SOUNDKIT = {
	UI_EPICLOOT_TOAST = assets.."ui_epicloot_toast_01.ogg",
	UI_GARRISON_FOLLOWER_LEARN_TRAIT = assets.."ui_garrison_follower_trait_learned_02.ogg",
	UI_LEGENDARY_LOOT_TOAST = assets.."ui_legendary_item_toast.ogg",
	UI_RAID_LOOT_TOAST_LESSER_ITEM_WON = assets.."ui_loot_toast_lesser_item_won_01.ogg",
};

local LootAlertFrameMixIn = {};
LootAlertFrameMixIn.alertQueue = {};
LootAlertFrameMixIn.alertButton = {};


function LF.AddAlert(name, link, quality, texture, count, label, toast, rollType, rollLink, tip, money, subType)

	tInsert(LootAlertFrameMixIn.alertQueue,{
		name 		= name,
		link 		= link,
		quality 	= quality,
		texture 	= texture,
		count 		= count,
		label 		= label,
		toast 		= toast,
		rollType 	= rollType,
		rollLink 	= rollLink,
		tip 		= tip,
		money		= money,
		subType 	= subType
	});
end

function LootAlertFrameMixIn:AdjustAnchors()
	local previousButton;
	for i=1, LOOTALERT_NUM_BUTTONS do
		local button = self.alertButton[i];
		button:ClearAllPoints();
		if button and button:IsShown() then
			if button.waitAndAnimOut:GetProgress() <= 0.74 then
				if not previousButton or previousButton == button then
					if DungeonCompletionAlertFrame1:IsShown() then
						button:SetPoint("BOTTOM", DungeonCompletionAlertFrame1, "TOP", point_x, point_y);
					else
						button:SetPoint("CENTER", DungeonCompletionAlertFrame1, "CENTER", point_x, point_y);
					end
				else
					button:SetPoint("BOTTOM", previousButton, "TOP", 0, offset_y);
				end
			end
			previousButton = button;
		end
	end
end

function LootAlertFrameMixIn:CreateAlert()
	if #self.alertQueue > 0 then
		for i=1, LOOTALERT_NUM_BUTTONS do
			local button = self.alertButton[i];
			if button and not button:IsShown() then
				local data = tRemove(self.alertQueue, 1);
				button.data = data;
				return button;
			end
		end
	end
	return nil;
end

function Mixin(object, ...)
  for _, mixin in pairs({...}) do
    for k, v in pairs(mixin) do
      object[k] = v
    end
  end
  return object
end

function LootAlertFrame_OnLoad(self)
	self.updateTime = uptime;
	--self:RegisterEvent("CHAT_MSG_LOOT");
	--self:RegisterEvent("CHAT_MSG_SYSTEM");
	--self:RegisterEvent("CHAT_MSG_MONEY");
	--self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");

	Mixin(self, LootAlertFrameMixIn);
end

function LootAlertFrame_OnUpdate(self, elapsed)
	self.updateTime = self.updateTime - elapsed;
	if self.updateTime <= 0 then
		local alert = LootAlertFrameMixIn:CreateAlert();
		if alert then
			alert:SetScale(scale);
			alert:ClearAllPoints();
			alert:Show();
			alert.animIn:Play();
			LootAlertFrameMixIn:AdjustAnchors();
		end
		self.updateTime = uptime;
	end
end

function LootAlertButtonTemplate_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	tInsert(LootAlertFrameMixIn.alertButton, self);
end

local texture, fontstring;
local prototype = {CreateFrame("Frame"), CreateFrame("Button")};

local subinit = function()
	for _, data in pairs(prototype) do
		texture = getmetatable(data:CreateTexture());
		fontstring = getmetatable(data:CreateFontString());
	end
end
subinit();
local methodshown = function(self, data)
	if data and data ~= false then
		self:Show();
	else
		self:Hide();
	end
end
function texture.__index:SetShown(...)
	methodshown(self, ...);
end

function fontstring.__index:SetShown(...)
	methodshown(self, ...);
end

function LootAlertButtonTemplate_OnShow(self)
	if not self.data then
		self:Hide();
		return;
	end

	local data = self.data;
	if data.name then
		local defaultToast 		= data.toast == "defaulttoast";
		local recipeToast 		= data.toast == "recipetoast";
		local battlefieldToast  = data.toast == "battlefieldtoast";
		local moneyToast 		= data.toast == "moneytoast";
		local legendaryToast 	= data.toast == "legendarytoast";
		local commonToast 		= data.toast == "commontoast";
		--local qualityColor 		= LF.ItemRarities[data.quality].color or nil;
		local qualityColor 		= ITEM_QUALITY_COLORS[data.quality] or nil;
		local averageToast		= not recipeToast and not moneyToast and not commonToast;
	
		if data.count then
			self.Count:SetText(data.count);
		else
			self.Count:SetText(" ");
		end

		self.Icon:SetTexture(data.texture);
		self.Icon:SetShown(averageToast);
		self.IconBorder:SetShown(averageToast);
		self.LessIcon:SetTexture(data.texture);
		self.ItemName:SetText(data.name);
		self.ItemName:SetShown(averageToast);
		self.LessItemName:SetText(data.name);
		self.Label:SetText(data.label);
		self.Label:SetShown(averageToast);
		self.RollWon:SetShown(data.rollLink);
		self.MoneyLabel:SetShown(moneyToast);
		self.Amount:SetShown(moneyToast);
		self.Amount:SetText(data.name);
		
		self.Background:SetShown(defaultToast);
		self.HeroicBackground:SetShown(data.toast == "heroictoast");
		self.PvPBackground:SetShown(battlefieldToast);
		self.PvPBackground:SetSize(SUB_COORDS[1], SUB_COORDS[2]);
		self.PvPBackground:SetTexCoord(unpack(HONOR_BADGE));
		self.RecipeBackground:SetShown(recipeToast);
		self.RecipeTitle:SetShown(recipeToast);
		self.RecipeName:SetShown(recipeToast);
		self.RecipeIcon:SetShown(recipeToast);
		self.LessBackground:SetShown(commonToast);
		self.LessItemName:SetShown(commonToast);
		self.LessIcon:SetShown(commonToast);
		self.LegendaryBackground:SetShown(legendaryToast);
		self.RollWonTitle:SetShown(data.rollLink);
		self.MoneyBackground:SetShown(moneyToast);
		--self.MoneyLabel:SetShown(moneyToast);
		self.MoneyBackground:SetShown(moneyToast);
		self.MoneyIconBorder:SetShown(moneyToast);
		self.MoneyIcon:SetShown(moneyToast);
		self.MountToastBackground:SetShown(data.toast == "mounttoast");
		self.PetToastBackground:SetShown(data.toast == "pettoast");
		
		if data.rollLink then
			if data.rollType == LOOT_ROLL_TYPE_NEED then
				self.RollWonTitle:SetTexture([[Interface\Buttons\UI-GroupLoot-Dice-Up]]);
			elseif data.rollType == LOOT_ROLL_TYPE_GREED then
				self.RollWonTitle:SetTexture([[Interface\Buttons\UI-GroupLoot-Coin-Up]]);
			else
				self.RollWonTitle:Hide();
			end
			self.RollWon:SetText(data.rollLink);
		end

		if recipeToast then
			self.RecipeIcon:SetTexture(data.texture);
			local craftIcon = PROFESSION_ICON_TCOORDS[data.subType];
			if craftIcon then
				self.RecipeIcon:SetTexCoord(unpack(craftIcon));
			end
			
			local rankTexture = NewRecipeLearnedAlertFrame_GetStarTextureFromRank(data.quality);
			if rankTexture then
				self.RecipeName:SetFormattedText("%s %s", data.name, rankTexture);
			else
				self.RecipeName:SetText(data.name);
			end
			self.RecipeTitle:SetText(data.label);
		end

		if qualityColor then
			self.ItemName:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b);
			self.LessItemName:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b);
		end

        
        if LOOT_BORDER_BY_QUALITY[data.quality] then
			self.IconBorder:SetTexCoord(unpack(LOOT_BORDER_BY_QUALITY[data.quality]));
        end
		
		if sound then
			if legendaryToast then
				PlaySoundFile(SOUNDKIT.UI_LEGENDARY_LOOT_TOAST);
			elseif commonToast then
				PlaySoundFile(SOUNDKIT.UI_RAID_LOOT_TOAST_LESSER_ITEM_WON);
			elseif self.data.toast == "heroictoast"  then
				PlaySoundFile(SOUNDKIT.UI_GARRISON_FOLLOWER_LEARN_TRAIT);
			else
				PlaySoundFile(SOUNDKIT.UI_EPICLOOT_TOAST);
			end
		end
		
		if animate then
			if legendaryToast then
				self.legendaryGlow.animIn:Play();
				self.legendaryShine.animIn:Play();
			elseif recipeToast then
				self.recipeGlow.animIn:Play();
				self.recipeShine.animIn:Play();
			else
				self.glow.animIn:Play();
				self.shine.animIn:Play();
			end
		end
		
		self.hyperLink 		= data.link;
		self.tip 			= data.tip;
		self.name 			= data.name;
		self.money			= data.money;
	end
end

function LootAlertButtonTemplate_OnHide(self)
	self:Hide();
	self.animIn:Stop();
	self.waitAndAnimOut:Stop();
	
	if animate then
		if self.data.toast == "legendarytoast" then
			self.legendaryGlow.animIn:Stop();
			self.legendaryShine.animIn:Stop();
		elseif self.data.toast == "recipetoast" then
			self.recipeGlow.animIn:Stop();
			self.recipeShine.animIn:Stop();
		else
			self.glow.animIn:Stop();
			self.shine.animIn:Stop();
		end
	end

	tWipe(self.data);
	LootAlertFrameMixIn:AdjustAnchors();
end

function LootAlertButtonTemplate_OnClick(self, button)
	if button == "RightButton" then
		self:Hide();
	else
		if HandleModifiedItemClick(self.hyperLink) then
			return;
		end
	end
end

function LootAlertButtonTemplate_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -14, -6);
	if self.tip then
		GameTooltip:SetText(self.name, 1, 1, 1);
		GameTooltip:AddLine(self.tip, nil, nil, nil, 1);
	elseif self.money then
		GameTooltip:AddLine(YOU_RECEIVED_LABEL);
		SetTooltipMoney(GameTooltip, self.money, nil);
	else
		GameTooltip:SetHyperlink(self.hyperLink);
	end
	GameTooltip:Show();
end