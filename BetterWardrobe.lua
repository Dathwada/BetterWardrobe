--	///////////////////////////////////////////////////////////////////////////////////////////
--
--	Better Wardrobe and Collection
--	Author: SLOKnightfall

--	Wardrobe and Collection: Adds additional functionality and sets to the transmog and collection areas
--

--

--	///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
--addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
addon.Frame = LibStub("AceGUI-3.0")

local playerInv_DB
local Profile
local playerNme
local realmName

addon.itemSourceID = {}


local L = LibStub("AceLocale-3.0"):GetLocale(addonName)


--ACE3 Options Constuctor
local options = {
	name = "BetterWardrobe",
	handler = BetterWardrobe,
	type = 'group',
	childGroups = "tab",
	inline = true,
	args = {
		settings={
			name = "Options",
			type = "group",
			--inline = true,
			order = 0,
			args={
				Options_Header = {
					order = 0,
					name = L["Transmog Vendor Window"],
					type = "header",
					width = "full",
				},

				ShowIncomplete = {
					order = 1,
					name = L["Show Incomplete Sets"],
					type = "toggle",
					set = function(info,val) Profile.ShowIncomplete = val end,
					get = function(info) return Profile.ShowIncomplete end,
					width = "full",
				},
				PartialLimit = {
					order = 7,
					name = L["Required pieces"],
					type = "select",
					type = "range",
					set = function(info,val) Profile.PartialLimit = val end,
					get = function(info) return Profile.PartialLimit end,
					width = "double",
					min = 1,
					max = 7,
					step = 1,
				},

				ShowNames = {
					order = 1,
					name = L["Show Set Names"],
					type = "toggle",
					set = function(info,val) Profile.ShowNames = val end,
					get = function(info) return Profile.ShowNames end,
					width = "full",
				},

				ShowSetCount = {
					order = 1,
					name = L["Show Collected Count"],
					type = "toggle",
					set = function(info,val) Profile.ShowSetCount = val end,
					get = function(info) return Profile.ShowSetCount end,
					width = "full",
				},

				HideMissing = {
					order = 1,
					name = L["Hide Missing Set Pieces"],
					type = "toggle",
					set = function(info,val) Profile.HideMissing = val end,
					get = function(info) return Profile.HideMissing end,
					width = "full",
				},
			},
		},

	},
}

MIN_SET_COLLECTED = 1


--ACE Profile Saved Variables Defaults
local defaults = {
	profile ={
		['*'] = true,
		PartialLimit = 4,
	}
}

---Updates Profile after changes
function addon:RefreshConfig()
	addon.Profile = self.db.profile
	Profile = addon.Profile
end


---Ace based addon initilization
function addon:OnInitialize()

end

function addon:OnEnable()
	self.db = LibStub("AceDB-3.0"):New("BetterWardrobe_Options", defaults, true)
	options.args.profiles  = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, addonName)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BetterWardrobe", "BetterWardrobe")
	self.db.RegisterCallback(addon, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(addon, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(addon, "OnProfileReset", "RefreshConfig")	
	--WardrobeTransmogFrameSpecDropDown_Initialize()

	addon.Profile = self.db.profile
	Profile = addon.Profile

	addon.BuildDB()
	addon.BuildUI()
	addon.SetSortOrder(false)
	WardrobeFilterDropDown_OnLoad(WardrobeCollectionFrame.FilterDropDown)

	--self:Hook("WardrobeCollectionFrame_SetTab", true)
end

local BASE_SET_BUTTON_HEIGHT = 46
local VARIANT_SET_BUTTON_HEIGHT = 20
local SET_PROGRESS_BAR_MAX_WIDTH = 204
local IN_PROGRESS_FONT_COLOR = CreateColor(0.251, 0.753, 0.251)
local IN_PROGRESS_FONT_COLOR_CODE = "|cff40c040"
local COLLECTION_LIST_WIDTH = 260


local f = CreateFrame("Frame",nil,UIParent);
f:SetHeight(1)
f:SetWidth(1)
f:SetPoint("TOPLEFT", UIParent, "TOPRIGHT")
f.model = CreateFrame("DressUpModel",nil), UIParent;
f.model:SetPoint("CENTER", UIParent, "CENTER")
f.model:SetHeight(1)
f.model:SetWidth(1)
f.model:SetModelScale(1);
f.model:SetAutoDress(false)
f.model:SetUnit("PLAYER");
addon.frame = f


function addon.GetItemSource(item, itemMod)

	if addon.modArmor[item] and addon.modArmor[item][itemMod] then return nil, addon.modArmor[item][itemMod] end

		local itemSource
		local visualID, sourceID

		visualID, sourceID = C_TransmogCollection.GetItemInfo(item) --, (mod or 0

		if not sourceID then
			local itemlink = "item:"..item..":0"
			f.model:Show()
			f.model:Undress()
			f.model:TryOn( itemlink)
			for i = 1, 19 do
				local source = f.model:GetSlotTransmogSources(i)
				if source ~= 0 then
					--addon.itemSourceID[item] =  source
					sourceID =  source
					break
				end
			end
			
		end

	f.model:Hide()
	return visualID ,sourceID
end


function GetSetCount(setID)
	local setinfo = addon.GetSetInfo(setID)
	return #setinfo["items"]
end


function addon.GetSetsources(setID)
	local setInfo = addon.GetSetInfo(setID)
	local setSources = {}

	for i, item in ipairs(setInfo.items) do

		
		local visualID, sourceID = addon.GetItemSource(item, setInfo.mod) --C_TransmogCollection.GetItemInfo(item)
		-- visualID, sourceID = addon.GetItemSource(item,setInfo.mod)
		--local sources = C_TransmogCollection.GetAppearanceSources(sourceInfo.visualID)

	
		if sourceID then
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
			local sources = C_TransmogCollection.GetAppearanceSources(sourceInfo.visualID)
			if sources then 
				if #sources > 1 then 
					WardrobeCollectionFrame_SortSources(sources)
				end

				setSources[sourceID] = sources[1].isCollected--and sourceInfo.isCollected
			else
				setSources[sourceID] = false
			end
		end
	end
			--setSources[sourceID] = sourceInfo and sourceInfo.isCollected
	return setSources
end

local EmptyArmor = {
	[1] = 134110,
	--[2] = 134112, neck
	[3] = 134112,
	--[4] = 168659, shirt
	[5] = 168659,
	[6] = 143539,
	--[7] = 158329, pants
	[8] = 168664,
	[9] = 168665,  --wrist
	[10] = 158329, --handr
}


local function GetEmptySlots()
	local setInfo = {}

	for i,x in pairs(EmptyArmor) do
	 	setInfo[i]=x
	end

	return setInfo
end

local function EmptySlots(transmogSources)
	local EmptySet = GetEmptySlots()

	for i, x in pairs(transmogSources) do
			EmptySet[i] = nil
	end

	return EmptySet
end

local SetsDataProvider = CreateFromMixins(WardrobeSetsDataProviderMixin);

function SetsDataProvider:SortSets(sets, reverseUIOrder, ignorePatchID)
	--local sortedSources = SetsDataProvider:GetSortedSetSources(data.setID)
	addon.SortSet(sets, reverseUIOrder, ignorePatchID)
	--addon.Sort["DefaultSortSet"](self, sets, reverseUIOrder, ignorePatchID)
end

function SetsDataProvider:GetBaseSets()
	if ( not self.baseSets ) then
		self.baseSets = C_TransmogSets.GetBaseSets();
		self:DetermineFavorites();
		self:SortSets(self.baseSets);
	end
	return self.baseSets;
end

--[[
function SetsDataProvider:GetUsableSets(incVariants)
	if ( not self.usableSets ) then
		local availableSets = self:GetBaseSets();
		self.usableSets = C_TransmogSets.GetUsableSets();


		--Generates Useable Set
		self.usableSets = {} --SetsDataProvider:GetUsableSets();
		for i, set in ipairs(availableSets) do
			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);

			--if topSourcesCollected >= Profile.PartialLimit  then --and not C_TransmogSets.IsSetUsable(set.setID) then
				tinsert(self.usableSets, set)
			--end

			if incVariants then 
				local variantSets = C_TransmogSets.GetVariantSets(set.setID);
				for i, set in ipairs(variantSets) do
					local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);
					if topSourcesCollected == topSourcesTotal then set.collected = true end
					if topSourcesCollected >= Profile.PartialLimit  then --and not C_TransmogSets.IsSetUsable(set.setID) then
						tinsert(self.usableSets, set)
					end
				end
			end

		end
		self:SortSets(self.usableSets);	
	end

	return self.usableSets;
end
]]--


function SetsDataProvider:GetUsableSets(incVariants)
	if ( not self.usableSets ) then
		self.usableSets = C_TransmogSets.GetUsableSets();

		local setIDS = {}


		self:SortSets(self.usableSets);
		-- group sets by baseSetID, except for favorited sets since those are to remain bucketed to the front
		for i, set in ipairs(self.usableSets) do
			setIDS[set.baseSetID or set.setID] = true
			if ( not set.favorite ) then
				local baseSetID = set.baseSetID or set.setID;
				local numRelatedSets = 0;
				for j = i + 1, #self.usableSets do
					if ( self.usableSets[j].baseSetID == baseSetID or self.usableSets[j].setID == baseSetID ) then
						numRelatedSets = numRelatedSets + 1;
						-- no need to do anything if already contiguous
						if ( j ~= i + numRelatedSets ) then
							local relatedSet = self.usableSets[j];
							tremove(self.usableSets, j);
							tinsert(self.usableSets, i + numRelatedSets, relatedSet);
						end
					end
				end
			end
		end

		if Profile.ShowIncomplete or BW_WardrobeToggle.VisualMode then 
			local availableSets = self:GetBaseSets();
			for i, set in ipairs(availableSets) do
				if not setIDS[set.setID or set.baseSetID ] then 
					local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);

					if BW_WardrobeToggle.VisualMode or topSourcesCollected >= Profile.PartialLimit  then --and not C_TransmogSets.IsSetUsable(set.setID) then
						
						tinsert(self.usableSets, set)
					end
				end

				if incVariants then 
					local variantSets = C_TransmogSets.GetVariantSets(set.setID);
					for i, set in ipairs(variantSets) do
						if not setIDS[set.setID or set.baseSetID ] then 
							local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);
							if topSourcesCollected == topSourcesTotal then set.collected = true end
							if BW_WardrobeToggle.VisualMode or topSourcesCollected >= Profile.PartialLimit  then --and not C_TransmogSets.IsSetUsable(set.setID) then
								tinsert(self.usableSets, set)
							end
						end
						
					end
				end

			end
			self:SortSets(self.usableSets);	
		end

	end
	return self.usableSets;
end



function SetsDataProvider:FilterSearch()
	local baseSets = self:GetUsableSets(true);
	local filteredSets = {}
	local searchString = string.lower(WardrobeCollectionFrameSearchBox:GetText())

	if searchString then 
		for i = 1, #baseSets do
			local baseSet = baseSets[i];
			local match = string.find(string.lower(baseSet.name), searchString) -- or string.find(baseSet.label, searchString) or string.find(baseSet.description, searchString)
			
			if match then 
				tinsert(filteredSets, baseSet)
			end
		end

		self.usableSets = filteredSets 
	else 
		self.usableSets = baseSets 
	end

end

function WardrobeCollectionFrame.SetsCollectionFrame:OnSearchUpdate()
	if ( self.init ) then
		SetsDataProvider:ClearBaseSets();
		SetsDataProvider:ClearVariantSets();
		SetsDataProvider:ClearUsableSets();
		self:Refresh();
	end
end


function WardrobeCollectionFrame.SetsCollectionFrame:OnShow()
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED");
	self:RegisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
	self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");
	-- select the first set if not init
	local baseSets = SetsDataProvider:GetBaseSets();
	if ( not self.init ) then
		self.init = true;
		if ( baseSets and baseSets[1] ) then
			self:SelectSet(self:GetDefaultSetIDForBaseSet(baseSets[1].setID));
		end
	else
		self:Refresh();
	end

	local latestSource = C_TransmogSets.GetLatestSource();
	if ( latestSource ~= NO_TRANSMOG_SOURCE_ID ) then
		local sets = C_TransmogSets.GetSetsContainingSourceID(latestSource);
		local setID = sets and sets[1];
		if ( setID ) then
			self:SelectSet(setID);
			local baseSetID = C_TransmogSets.GetBaseSetID(setID);
			self:ScrollToSet(baseSetID);
		end
		self:ClearLatestSource();
	end

	WardrobeCollectionFrame.progressBar:Show();
	self:UpdateProgressBar();
	self:RefreshCameras();

	if (self:GetParent().SetsTabHelpBox:IsShown()) then
		self:GetParent().SetsTabHelpBox:Hide()
		SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB, true);
	end
end



function WardrobeCollectionFrame.SetsCollectionFrame:HandleKey(key)
	if ( not self:GetSelectedSetID() ) then
		return false;
	end
	local selectedSetID = C_TransmogSets.GetBaseSetID(self:GetSelectedSetID());
	local _, index = SetsDataProvider:GetBaseSetByID(selectedSetID);
	if ( not index ) then
		return;
	end
	if ( key == WARDROBE_DOWN_VISUAL_KEY ) then
		index = index + 1;
	elseif ( key == WARDROBE_UP_VISUAL_KEY ) then
		index = index - 1;
	end
	local sets = SetsDataProvider:GetBaseSets();
	index = Clamp(index, 1, #sets);
	self:SelectSet(self:GetDefaultSetIDForBaseSet(sets[index].setID));
	self:ScrollToSet(sets[index].setID);
end

function WardrobeCollectionFrame.SetsCollectionFrame:ScrollToSet(setID)
	local totalHeight = 0;
	local scrollFrameHeight = self.ScrollFrame:GetHeight();
	local buttonHeight = self.ScrollFrame.buttonHeight;
	for i, set in ipairs(SetsDataProvider:GetBaseSets()) do
		if ( set.setID == setID ) then
			local offset = self.ScrollFrame.scrollBar:GetValue();
			if ( totalHeight + buttonHeight > offset + scrollFrameHeight ) then
				offset = totalHeight + buttonHeight - scrollFrameHeight;
			elseif ( totalHeight < offset ) then
				offset = totalHeight;
			end
			self.ScrollFrame.scrollBar:SetValue(offset, true);
			break;
		end
		totalHeight = totalHeight + buttonHeight;
	end
end



function WardrobeCollectionFrameScrollFrame:Update()
	local offset = HybridScrollFrame_GetOffset(self);
	local buttons = self.buttons;
	local baseSets = SetsDataProvider:GetBaseSets();

	-- show the base set as selected
	local selectedSetID = self:GetParent():GetSelectedSetID();
	local selectedBaseSetID = selectedSetID and C_TransmogSets.GetBaseSetID(selectedSetID);

	for i = 1, #buttons do
		local button = buttons[i];
		local setIndex = i + offset;
		if ( setIndex <= #baseSets ) then
			local baseSet = baseSets[setIndex];
			button:Show();
			button.Name:SetText(baseSet.name);
			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceTopCounts(baseSet.setID);
			local setCollected = C_TransmogSets.IsBaseSetCollected(baseSet.setID);
			local color = IN_PROGRESS_FONT_COLOR;
			if ( setCollected ) then
				color = NORMAL_FONT_COLOR;
			elseif ( topSourcesCollected == 0 ) then
				color = GRAY_FONT_COLOR;
			end
			button.Name:SetTextColor(color.r, color.g, color.b);
			button.Label:SetText(baseSet.label);
			button.Icon:SetTexture(SetsDataProvider:GetIconForSet(baseSet.setID));
			button.Icon:SetDesaturation((topSourcesCollected == 0) and 1 or 0);
			button.SelectedTexture:SetShown(baseSet.setID == selectedBaseSetID);
			button.Favorite:SetShown(baseSet.favoriteSetID);
			button.New:SetShown(SetsDataProvider:IsBaseSetNew(baseSet.setID));
			button.setID = baseSet.setID;

			if ( topSourcesCollected == 0 or setCollected ) then
				button.ProgressBar:Hide();
			else
				button.ProgressBar:Show();
				button.ProgressBar:SetWidth(SET_PROGRESS_BAR_MAX_WIDTH * topSourcesCollected / topSourcesTotal);
			end
			button.IconCover:SetShown(not setCollected);
		else
			button:Hide();
		end
	end

	local extraHeight = (self.largeButtonHeight and self.largeButtonHeight - BASE_SET_BUTTON_HEIGHT) or 0;
	local totalHeight = #baseSets * BASE_SET_BUTTON_HEIGHT + extraHeight;
	HybridScrollFrame_Update(self, totalHeight, self:GetHeight());
end


WardrobeCollectionFrame.SetsCollectionFrame:SetScript("OnShow", WardrobeCollectionFrame.SetsCollectionFrame.OnShow)


function WardrobeCollectionFrame.SetsTransmogFrame:OnSearchUpdate()
	SetsDataProvider:ClearUsableSets();
	SetsDataProvider:FilterSearch()
	self:UpdateSets();
end

--local BetterWardrobeSetsTransmogMixin = CreateFromMixins(WardrobeSetsTransmogMixin);

function WardrobeCollectionFrame.SetsTransmogFrame:UpdateSets()
	local usableSets = SetsDataProvider:GetUsableSets(true);
	self.PagingFrame:SetMaxPages(ceil(#usableSets / self.PAGE_SIZE));
	local pendingTransmogModelFrame = nil;
	local indexOffset = (self.PagingFrame:GetCurrentPage() - 1) * self.PAGE_SIZE;
	for i = 1, self.PAGE_SIZE do
		local model = self.Models[i];
		local index = i + indexOffset;
		local set = usableSets[index];

		if ( set ) then
			model:Show();

			if ( model.setID ~= set.setID ) then
				model:Undress();
				local sourceData = SetsDataProvider:GetSetSourceData(set.setID);
				for sourceID  in pairs(sourceData.sources) do
					model:TryOn(sourceID);
				end
			end

			local transmogStateAtlas;
			if ( set.setID == self.appliedSetID and set.setID == self.selectedSetID ) then
				transmogStateAtlas = "transmog-set-border-current-transmogged";
			elseif ( set.setID == self.selectedSetID ) then
				transmogStateAtlas = "transmog-set-border-selected";
				pendingTransmogModelFrame = model;
			end

			if ( transmogStateAtlas ) then
				model.TransmogStateTexture:SetAtlas(transmogStateAtlas, true);
				model.TransmogStateTexture:Show();
			else
				model.TransmogStateTexture:Hide();
			end

			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);
			local setInfo = C_TransmogSets.GetSetInfo(set.setID)

			model.Favorite.Icon:SetShown(C_TransmogSets.GetIsFavorite(set.setID))
			model.setID = set.setID

			model.setName:SetText((Profile.ShowNames and setInfo["name"].."\n"..(setInfo["description"] or "")) or "")
			model.progress:SetText( (Profile.ShowSetCount and topSourcesCollected.."/".. topSourcesTotal) or "")

		else
			model:Hide();
		end
	end

	if ( pendingTransmogModelFrame ) then
		self.PendingTransmogFrame:SetParent(pendingTransmogModelFrame);
		self.PendingTransmogFrame:SetPoint("CENTER");
		self.PendingTransmogFrame:Show();
		if ( self.PendingTransmogFrame.setID ~= pendingTransmogModelFrame.setID ) then
			self.PendingTransmogFrame.TransmogSelectedAnim:Stop();
			self.PendingTransmogFrame.TransmogSelectedAnim:Play();
			self.PendingTransmogFrame.TransmogSelectedAnim2:Stop();
			self.PendingTransmogFrame.TransmogSelectedAnim2:Play();
			self.PendingTransmogFrame.TransmogSelectedAnim3:Stop();
			self.PendingTransmogFrame.TransmogSelectedAnim3:Play();
			self.PendingTransmogFrame.TransmogSelectedAnim4:Stop();
			self.PendingTransmogFrame.TransmogSelectedAnim4:Play();
			self.PendingTransmogFrame.TransmogSelectedAnim5:Stop();
			self.PendingTransmogFrame.TransmogSelectedAnim5:Play();
		end
		self.PendingTransmogFrame.setID = pendingTransmogModelFrame.setID;
	else
		self.PendingTransmogFrame:Hide();
	end

	self.NoValidSetsLabel:SetShown(not C_TransmogSets.HasUsableSets());
end

function WardrobeCollectionFrame.SetsTransmogFrame:LoadSet(setID)
	local waitingOnData = false;
	local transmogSources = { };
	local sources = C_TransmogSets.GetSetSources(setID);
	for sourceID in pairs(sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
		local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType);
		local slotSources = C_TransmogSets.GetSourcesForSlot(setID, slot);
		WardrobeCollectionFrame_SortSources(slotSources, sourceInfo.visualID);
		local index = WardrobeCollectionFrame_GetDefaultSourceIndex(slotSources, sourceID);
		transmogSources[slot] = slotSources[index].sourceID;

		for i, slotSourceInfo in ipairs(slotSources) do
			if ( not slotSourceInfo.name ) then
				waitingOnData = true;
			end
		end
	end
	if ( waitingOnData ) then
		self.loadingSetID = setID;
	else
		self.loadingSetID = nil;
		-- if we don't ignore the event, clearing will momentarily set the page to the one with the set the user currently has transmogged
		-- if that's a different page from the current one then the models will flicker as we swap the gear to different sets and back
		self.ignoreTransmogrifyUpdateEvent = true;
		C_Transmog.ClearPending();
		self.ignoreTransmogrifyUpdateEvent = false;
		C_Transmog.LoadSources(transmogSources, -1, -1);

		if Profile.HideMissing then 

			local emptySlotData = GetEmptySlots()
			for i, x in pairs(transmogSources) do
				if not C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(x) and i ~= 7  and emptySlotData[i] then
					local _,  source = addon.GetItemSource(emptySlotData[i]) -- C_TransmogCollection.GetItemInfo(emptySlotData[i])
					C_Transmog.SetPending(i, LE_TRANSMOG_TYPE_APPEARANCE, source)
				end
			end
		end
	end
end


local function GetPage(entryIndex, pageSize)
	return floor((entryIndex-1) / pageSize) + 1;
end


function WardrobeCollectionFrame.SetsTransmogFrame:ResetPage()
	local page = 1;
	if ( self.selectedSetID ) then
		local usableSets = SetsDataProvider:GetUsableSets(true);
		self.PagingFrame:SetMaxPages(ceil(#usableSets / self.PAGE_SIZE));
		for i, set in ipairs(usableSets) do
			if ( set.setID == self.selectedSetID ) then
				page = GetPage(i, self.PAGE_SIZE);
				break;
			end
		end
	end
	self.PagingFrame:SetCurrentPage(page);
	self:UpdateSets();
end


function WardrobeCollectionFrame.SetsTransmogFrame:OnShow()
	self:RegisterEvent("TRANSMOGRIFY_UPDATE");
	self:RegisterEvent("TRANSMOGRIFY_SUCCESS");
	self:RegisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
	self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	self:RegisterEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
	self:RefreshCameras();
	local RESET_SELECTION = true;
	self:Refresh(RESET_SELECTION);
	WardrobeCollectionFrame.progressBar:Show();
	self:UpdateProgressBar();
	self.sourceQualityTable = { };

	if (self:GetParent().SetsTabHelpBox:IsShown()) then
		self:GetParent().SetsTabHelpBox:Hide();
		SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB, true);
	end
end


function WardrobeCollectionFrame.SetsTransmogFrame:OnHide()
	self:UnregisterEvent("TRANSMOGRIFY_UPDATE");
	self:UnregisterEvent("TRANSMOGRIFY_SUCCESS");
	self:UnregisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
	self:UnregisterEvent("TRANSMOG_COLLECTION_UPDATED");
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
	self:UnregisterEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
	self.loadingSetID = nil;
	SetsDataProvider:ClearSets();
	WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS);
	self.sourceQualityTable = nil;
	BW_WardrobeToggle.VisualMode = false
end


function WardrobeCollectionFrame.SetsTransmogFrame:OnEvent(event, ...)
	if ( event == "TRANSMOGRIFY_UPDATE" and not self.ignoreTransmogrifyUpdateEvent ) then
		self:Refresh();
	elseif ( event == "TRANSMOGRIFY_SUCCESS" )  then
		-- this event fires once per slot so in the case of a set there would be up to 9 of them
		if ( not self.transmogrifySuccessUpdate ) then
			self.transmogrifySuccessUpdate = true;
			C_Timer.After(0, function() self.transmogrifySuccessUpdate = nil; self:Refresh(); end);
		end
	elseif ( event == "TRANSMOG_COLLECTION_UPDATED" or event == "TRANSMOG_SETS_UPDATE_FAVORITE" ) then
		SetsDataProvider:ClearSets();
		self:Refresh();
		self:UpdateProgressBar();
	elseif ( event == "TRANSMOG_COLLECTION_ITEM_UPDATE" ) then
		if ( self.loadingSetID ) then
			local setID = self.loadingSetID;
			self.loadingSetID = nil;
			self:LoadSet(setID);
		end
		if ( self.tooltipModel ) then
			self.tooltipModel:RefreshTooltip();
		end
	elseif ( event == "PLAYER_EQUIPMENT_CHANGED" ) then
		if ( self.selectedSetID ) then
			self:LoadSet(self.selectedSetID);
		end
		self:Refresh();
	end
end

WardrobeCollectionFrame.SetsTransmogFrame:SetScript("OnShow", WardrobeCollectionFrame.SetsTransmogFrame.OnShow)
WardrobeCollectionFrame.SetsTransmogFrame:SetScript("OnHide", WardrobeCollectionFrame.SetsTransmogFrame.OnHide)
WardrobeCollectionFrame.SetsTransmogFrame:SetScript("OnEvent",  WardrobeCollectionFrame.SetsTransmogFrame.OnEvent)


function WardrobeCollectionFrame.SetsCollectionFrame.ScrollFrame:Update()
	local offset = HybridScrollFrame_GetOffset(self);
	local buttons = self.buttons;
	local baseSets = SetsDataProvider:GetBaseSets();

	-- show the base set as selected
	local selectedSetID = self:GetParent():GetSelectedSetID();
	local selectedBaseSetID = selectedSetID and C_TransmogSets.GetBaseSetID(selectedSetID);

	for i = 1, #buttons do
		local button = buttons[i];
		local setIndex = i + offset;
		if ( setIndex <= #baseSets ) then
			local baseSet = baseSets[setIndex];
			button:Show();
			button.Name:SetText(baseSet.name);
			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceTopCounts(baseSet.setID);
			local setCollected = C_TransmogSets.IsBaseSetCollected(baseSet.setID);
			local color = IN_PROGRESS_FONT_COLOR;
			if ( setCollected ) then
				color = NORMAL_FONT_COLOR;
			elseif ( topSourcesCollected == 0 ) then
				color = GRAY_FONT_COLOR;
			end
			button.Name:SetTextColor(color.r, color.g, color.b);
			button.Label:SetText(baseSet.label);
			button.Icon:SetTexture(SetsDataProvider:GetIconForSet(baseSet.setID));
			button.Icon:SetDesaturation((topSourcesCollected == 0) and 1 or 0);
			button.SelectedTexture:SetShown(baseSet.setID == selectedBaseSetID);
			button.Favorite:SetShown(baseSet.favoriteSetID);
			button.New:SetShown(SetsDataProvider:IsBaseSetNew(baseSet.setID));
			button.setID = baseSet.setID;

			if ( topSourcesCollected == 0 or setCollected ) then
				button.ProgressBar:Hide();
			else
				button.ProgressBar:Show();
				button.ProgressBar:SetWidth(SET_PROGRESS_BAR_MAX_WIDTH * topSourcesCollected / topSourcesTotal);
			end
			button.IconCover:SetShown(not setCollected);
		else
			button:Hide();
		end
	end

	local extraHeight = (self.largeButtonHeight and self.largeButtonHeight - BASE_SET_BUTTON_HEIGHT) or 0;
	local totalHeight = #baseSets * BASE_SET_BUTTON_HEIGHT + extraHeight;
	HybridScrollFrame_Update(self, totalHeight, self:GetHeight());
end
--This bit sets "update" which is set via on load and triggers when scrolling.  Its what caused sorting issues
WardrobeCollectionFrame.SetsCollectionFrame.ScrollFrame.update = WardrobeCollectionFrame.SetsCollectionFrame.ScrollFrame.Update

--=======


--
local SetsDataProvider = CreateFromMixins(WardrobeSetsDataProviderMixin)

function SetsDataProvider:SortSets(sets, reverseUIOrder, ignorePatchID)
	addon.SortSet(sets, reverseUIOrder, ignorePatchID)
	--addon.Sort["DefaultSortSet"](self, sets, reverseUIOrder, ignorePatchID)
end

function SetsDataProvider:ClearSets()
	self.baseSets = nil;
	self.baseSetsData = nil;
	self.variantSets = nil;
	self.usableSets = nil;
	self.sourceData = nil;
end


local setsByExpansion = {}
local setsByFilter = {}
	
local baseSets
function SetsDataProvider:FilterSearch(useBaseSet)
	if useBaseSet then 
		baseSets = SetsDataProvider:GetBaseSets();
	else 
		baseSets = SetsDataProvider:GetUsableSets();
	end

	local filteredSets = {}
		local searchString = string.lower(WardrobeCollectionFrameSearchBox:GetText())

		for i, data in ipairs(baseSets) do
		
						--if (addon.filterCollected[1] and data.collected) or (addon.filterCollected[2] and not data.collected) and
		if  addon.xpacSelection[data.expansionID] and 
			addon.filterSelection[data.filter]  
			and (searchString and string.find(string.lower(data.name), searchString) ) then -- or string.find(baseSet.label, searchString) or string.find(baseSet.description, searchString)then
				tinsert(filteredSets, data)
		end

		if useBaseSet then 
				self.baseSets = filteredSets 
		else 
				self.usableSets = filteredSets 
		end
	
	--else 
		--self.baseSets = baseSets 
	end
end


function SetsDataProvider:GetBaseSets()
	if ( not self.baseSets ) then
		self.baseSets = addon.GetBaseList() --C_TransmogSets.GetBaseSets();
		--self:DetermineFavorites();
		self:SortSets(self.baseSets);
	end

	return self.baseSets;
end


function SetsDataProvider:GetSetSourceCounts(setID)
	local sourceData = self:GetSetSourceData(setID);
	return sourceData.numCollected, sourceData.numTotal;
end

--Lets CanIMogIt plugin get extra sets count
 function addon.GetSetSourceCounts(setID)
	return SetsDataProvider:GetSetSourceCounts(setID)
end


function SetsDataProvider:GetUsableSets(incVariants)
	if ( not self.usableSets ) then
		local availableSets = SetsDataProvider:GetBaseSets();

		--Generates Useable Set
		self.usableSets = {} --SetsDataProvider:GetUsableSets();
		for i, set in ipairs(availableSets) do

			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);
			if BW_WardrobeToggle.VisualMode or topSourcesCollected >= Profile.PartialLimit  then --and not C_TransmogSets.IsSetUsable(set.setID) then
				tinsert(self.usableSets, set)
			end

			if incVariants then 
				local variantSets = C_TransmogSets.GetVariantSets(set.setID);
				for i, set in ipairs(variantSets) do
					local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID);
					if topSourcesCollected == topSourcesTotal then set.collected = true end
					if BW_WardrobeToggle.VisualMode or topSourcesCollected >= Profile.PartialLimit  then --and not C_TransmogSets.IsSetUsable(set.setID) then
						tinsert(self.usableSets, set)
					end
				end
			end

		end
		self:SortSets(self.usableSets);	
	end

	return self.usableSets;
end

function SetsDataProvider:GetSetSourceData(setID)
	if ( not self.sourceData ) then
		self.sourceData = { };
	end

	local sourceData = self.sourceData[setID];
	if ( not sourceData ) then
		--print("BS")
		--print(setID)
		local sources = addon.GetSetsources(setID)
		local numCollected = 0
		local numTotal = 0
		if sources then 
			for sourceID, collected in pairs(sources) do
				if ( collected ) then
					numCollected = numCollected + 1
				end
				numTotal = numTotal + 1
			end

			sourceData = { numCollected = numCollected, numTotal = numTotal, sources = sources }
			self.sourceData[setID] = sourceData;
		end
	end
	return sourceData
end


function SetsDataProvider:GetSortedSetSources(setID)
	local returnTable = { }
	local sourceData = self:GetSetSourceData(setID)

	for sourceID, collected in pairs(sourceData.sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)

		if ( sourceInfo ) then
			local sortOrder = EJ_GetInvTypeSortOrder(sourceInfo.invType)
			tinsert(returnTable, { sourceID = sourceID, collected = collected, sortOrder = sortOrder, itemID = sourceInfo.itemID, invType = sourceInfo.invType })
		end
	end

	local comparison = function(entry1, entry2)
		if ( entry1.sortOrder == entry2.sortOrder ) then
			return entry1.itemID < entry2.itemID
		else
			return entry1.sortOrder < entry2.sortOrder
		end
	end

	table.sort(returnTable, comparison)
	return returnTable
end


function SetsDataProvider:GetBaseSetData(setID)
	if ( not self.baseSetsData ) then
		self.baseSetsData = { }
	end

	if ( not self.baseSetsData[setID] ) then
		local baseSetID = C_TransmogSets.GetBaseSetID(setID)
		if ( baseSetID ~= setID ) then
			return
		end
		local topCollected, topTotal = self:GetSetSourceCounts(setID)
		local setInfo = { topCollected = topCollected, topTotal = topTotal, completed = (topCollected == topTotal) }
		self.baseSetsData[setID] = setInfo
	end

	return self.baseSetsData[setID]
end



--=========--
-- Extra Sets Trannsmog Collection Model 
BetterWardrobeSetsTransmogModelMixin = CreateFromMixins(WardrobeSetsTransmogModelMixin)

function BetterWardrobeSetsTransmogModelMixin:LoadSet(setID)
	local waitingOnData = false
	local transmogSources = { }
	local sources = addon.GetSetsources(setID)
	for sourceID in pairs(sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
		local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType)
		local slotSources = C_TransmogSets.GetSourcesForSlot(setID, slot)
		--WardrobeCollectionFrame_SortSources(slotSources, sourceInfo.visualID)
		local index = WardrobeCollectionFrame_GetDefaultSourceIndex(slotSources, sourceID)
		transmogSources[slot] = (slotSources[index] and slotSources[index].sourceID) or sourceID;


		for i, slotSourceInfo in ipairs(slotSources) do
			if ( not slotSourceInfo.name ) then
				waitingOnData = true
			end
		end
	end

	if ( waitingOnData ) then
		self.loadingSetID = setID
	else
		self.loadingSetID = nil
		-- if we don't ignore the event, clearing will momentarily set the page to the one with the set the user currently has transmogged
		-- if that's a different page from the current one then the models will flicker as we swap the gear to different sets and back
		self.ignoreTransmogrifyUpdateEvent = true
		C_Transmog.ClearPending()
		self.ignoreTransmogrifyUpdateEvent = false
		C_Transmog.LoadSources(transmogSources, -1, -1)
	end
end

function BetterWardrobeSetsTransmogModelMixin:RefreshTooltip()
	local totalQuality = 0
	local numTotalSlots = 0
	local waitingOnQuality = false
	local sourceQualityTable = self:GetParent().sourceQualityTable

	--local sources = C_TransmogSets.GetSetSources(self.setID)
	--print(self.setID)
	local sources = addon.GetSetsources(self.setID)
	for sourceID in pairs(sources) do
		numTotalSlots = numTotalSlots + 1
		if ( sourceQualityTable[sourceID] ) then
			totalQuality = totalQuality + sourceQualityTable[sourceID]
		else
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
			if ( sourceInfo and sourceInfo.quality ) then
				sourceQualityTable[sourceID] = sourceInfo.quality
				totalQuality = totalQuality + sourceInfo.quality
			else
				waitingOnQuality = true
			end
		end
	end

	if ( waitingOnQuality ) then
		GameTooltip:SetText(RETRIEVING_ITEM_INFO, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	else
		local setQuality = (numTotalSlots > 0 and totalQuality > 0) and Round(totalQuality / numTotalSlots) or LE_ITEM_QUALITY_COMMON
		local color = ITEM_QUALITY_COLORS[setQuality]
		local setInfo = addon.GetSetInfo(self.setID)
		GameTooltip:SetText(setInfo.name, color.r, color.g, color.b)
		if ( setInfo.label ) then
			GameTooltip:AddLine(setInfo.label)
			GameTooltip:Show()
		end
	end
end

--==

--=======--
-- Extra Sets Collection  List
BetterWardrobeSetsCollectionMixin = CreateFromMixins(WardrobeSetsCollectionMixin)

function BetterWardrobeSetsCollectionMixin:OnLoad()
	self.RightInset.BGCornerTopLeft:Hide()
	self.RightInset.BGCornerTopRight:Hide()

	self.DetailsFrame.Name:SetFontObjectsToTry(Fancy24Font, Fancy20Font, Fancy16Font)
	self.DetailsFrame.itemFramesPool = CreateFramePool("FRAME", self.DetailsFrame, "WardrobeSetsDetailsItemFrameTemplate")

	self.selectedVariantSets = { }
end


function BetterWardrobeSetsCollectionMixin:OnShow()
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	self:RegisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE")
	self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
	-- select the first set if not init

	local baseSets = SetsDataProvider:GetBaseSets() --addon.GetBaseList()--addon.sets["Mail" ]
	if ( not self.init ) then
		self.init = true

		if ( baseSets and baseSets[1] ) then
			--self:SelectSet(self:GetDefaultSetIDForBaseSet(baseSets[1].setID))
			self:SelectSet(baseSets[1].setID)

		end

	else
		self:Refresh()
	end

	local latestSource = C_TransmogSets.GetLatestSource()

	if ( latestSource ~= NO_TRANSMOG_SOURCE_ID ) then
		local sets = C_TransmogSets.GetSetsContainingSourceID(latestSource)
		local setID = sets and sets[1]
		if ( setID ) then
			self:SelectSet(setID)
			local baseSetID = C_TransmogSets.GetBaseSetID(setID)
			self:ScrollToSet(baseSetID)
		end
		self:ClearLatestSource()
	end

	--WardrobeCollectionFrame.progressBar:Show()
	--self:UpdateProgressBar()
	self:RefreshCameras()

	--if (self:GetParent().SetsTabHelpBox:IsShown()) then
		--self:GetParent().SetsTabHelpBox:Hide()
		--SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB, true)
	--end
end


function BetterWardrobeSetsCollectionMixin:OnHide()
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
	self:UnregisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE")
	self:UnregisterEvent("TRANSMOG_COLLECTION_UPDATED")
	SetsDataProvider:ClearSets()
	--WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_BASE_SETS)
end



function BetterWardrobeSetsCollectionMixin:OnEvent(event, ...)

	if ( event == "GET_ITEM_INFO_RECEIVED" ) then
		local itemID = ...
		for itemFrame in self.DetailsFrame.itemFramesPool:EnumerateActive() do
			if ( itemFrame.itemID == itemID ) then
				self:SetItemFrameQuality(itemFrame)
				break
			end
		end
	elseif ( event == "TRANSMOG_COLLECTION_ITEM_UPDATE" ) then
		for itemFrame in self.DetailsFrame.itemFramesPool:EnumerateActive() do
			self:SetItemFrameQuality(itemFrame)
		end
	elseif ( event == "TRANSMOG_COLLECTION_UPDATED" ) then
		SetsDataProvider:ClearSets()
		self:Refresh()
		self:UpdateProgressBar()
		self:ClearLatestSource()
	end

end

function BetterWardrobeSetsCollectionMixin:Refresh()
	self.ScrollFrame:Update()
	self:DisplaySet(self:GetSelectedSetID())
end

function BetterWardrobeSetsCollectionMixin:DisplaySet(setID)
	local setInfo = (setID and addon.GetSetInfo(setID)) or nil
	if ( not setInfo ) then
		self.DetailsFrame:Hide()
		self.Model:Hide()
		return
	else
		self.DetailsFrame:Show()
		self.Model:Show()
	end

	self.DetailsFrame.Name:SetText(setInfo.name)
	if ( self.DetailsFrame.Name:IsTruncated() ) then
		self.DetailsFrame.Name:Hide()
		self.DetailsFrame.LongName:SetText(setInfo.name)
		self.DetailsFrame.LongName:Show()
	else
		self.DetailsFrame.Name:Show()
		self.DetailsFrame.LongName:Hide()
	end

	self.DetailsFrame.Label:SetText(setInfo.label);

	--local newSourceIDs = C_TransmogSets.GetSetNewSources(setID)

	self.DetailsFrame.itemFramesPool:ReleaseAll()
	self.Model:Undress()
	local BUTTON_SPACE = 37	-- button width + spacing between 2 buttons
	local sortedSources = SetsDataProvider:GetSortedSetSources(setID)
	local xOffset = -floor((#setInfo.items - 1) * BUTTON_SPACE / 2)

	for i = 1, #sortedSources do
		local itemFrame = self.DetailsFrame.itemFramesPool:Acquire()
		itemFrame.sourceID = sortedSources[i].sourceID
		itemFrame.itemID = sortedSources[i].itemID
		itemFrame.collected = sortedSources[i].collected
		itemFrame.invType = sortedSources[i].invType
		local texture = C_TransmogCollection.GetSourceIcon(sortedSources[i].sourceID)
		itemFrame.Icon:SetTexture(texture)
		if ( sortedSources[i].collected ) then
			itemFrame.Icon:SetDesaturated(false)
			itemFrame.Icon:SetAlpha(1)
			itemFrame.IconBorder:SetDesaturation(0)
			itemFrame.IconBorder:SetAlpha(1)

			local transmogSlot = C_Transmog.GetSlotForInventoryType(itemFrame.invType)
			if ( C_TransmogSets.SetHasNewSourcesForSlot(setID, transmogSlot) ) then
				itemFrame.New:Show()
				itemFrame.New.Anim:Play()
			else
				itemFrame.New:Hide()
				itemFrame.New.Anim:Stop()
			end
		else
			itemFrame.Icon:SetDesaturated(true)
			itemFrame.Icon:SetAlpha(0.3)
			itemFrame.IconBorder:SetDesaturation(1)
			itemFrame.IconBorder:SetAlpha(0.3)
			itemFrame.New:Hide()
		end

		self:SetItemFrameQuality(itemFrame)
		itemFrame:SetPoint("TOP", self.DetailsFrame, "TOP", xOffset + (i - 1) * BUTTON_SPACE, -94)
		itemFrame:Show()
		self.Model:TryOn(sortedSources[i].sourceID)
	end

	-- variant sets
	--local baseSetID = C_TransmogSets.GetBaseSetID(setID)
	--local variantSets = SetsDataProvider:GetVariantSets(baseSetID)
	--if ( #variantSets == 0 )  then
		--self.DetailsFrame.VariantSetsButton:Hide()
	--else
		--self.DetailsFrame.VariantSetsButton:Show()
		--self.DetailsFrame.VariantSetsButton:SetText(setInfo.description)
--	end
end

function BetterWardrobeSetsCollectionMixin:OnSearchUpdate()
	if ( self.init ) then
		SetsDataProvider:ClearBaseSets();
		SetsDataProvider:ClearVariantSets();
		SetsDataProvider:ClearUsableSets();
		SetsDataProvider:FilterSearch(true)
		self:Refresh();
	end
end


function BetterWardrobeSetsCollectionMixin:SelectSetFromButton(setID)
	CloseDropDownMenus()
	--self:SelectSet(self:GetDefaultSetIDForBaseSet(setID))
	self:SelectSet(setID)
end


function BetterWardrobeSetsCollectionMixin:SelectSet(setID)
	self.selectedSetID = setID

	--local baseSetID = C_TransmogSets.GetBaseSetID(setID)
	--local variantSets = SetsDataProvider:GetVariantSets(baseSetID)
	--if ( #variantSets > 0 ) then
	--	self.selectedVariantSets[baseSetID] = setID
	--end

	self:Refresh()
end

function BetterWardrobeSetsCollectionMixin:SetAppearanceTooltip(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	self.tooltipTransmogSlot = C_Transmog.GetSlotForInventoryType(frame.invType)
	self.tooltipPrimarySourceID = frame.sourceID
	self:RefreshAppearanceTooltip()
end


function BetterWardrobeSetsCollectionMixin:RefreshAppearanceTooltip()
	if ( not self.tooltipTransmogSlot ) then
		return
	end

	local sourceInfo = C_TransmogCollection.GetSourceInfo(self.tooltipPrimarySourceID)
	local visualID = sourceInfo.visualID
	local sources = C_TransmogCollection.GetAppearanceSources(visualID) or {}
	
	if ( #sources == 0 ) then
		-- can happen if a slot only has HiddenUntilCollected sources
		local sourceInfo = C_TransmogCollection.GetSourceInfo(self.tooltipPrimarySourceID);
		tinsert(sources, sourceInfo);
	end

	WardrobeCollectionFrame_SortSources(sources, sources[1].visualID, self.tooltipPrimarySourceID)
	WardrobeCollectionFrame_SetAppearanceTooltip(self, sources, self.tooltipPrimarySourceID)
end


BetterWardrobeSetsCollectionScrollFrameMixin = CreateFromMixins(WardrobeSetsCollectionScrollFrameMixin)

function BetterWardrobeSetsCollectionScrollFrameMixin:OnLoad()
	self.scrollBar.trackBG:Show()
	self.scrollBar.trackBG:SetVertexColor(0, 0, 0, 0.75)
	self.scrollBar.doNotHide = true
	self.update = self.Update
	HybridScrollFrame_CreateButtons(self, "WardrobeSetsScrollFrameButtonTemplate", 44, 0)
	--UIDropDownMenu_Initialize(self.FavoriteDropDown, WardrobeSetsCollectionScrollFrame_FavoriteDropDownInit, "MENU")
end


--local selectedSetID
function BetterWardrobeSetsCollectionScrollFrameMixin:Update()

	local offset = HybridScrollFrame_GetOffset(self)
	local buttons = self.buttons
	local baseSets =  SetsDataProvider:GetBaseSets() --addon.GetBaseList()

	-- show the base set as selected
	local selectedSetID = self:GetParent():GetSelectedSetID()
	local selectedBaseSetID = selectedSetID --and C_TransmogSets.GetBaseSetID(selectedSetID)

	for i = 1, #buttons do
		local button = buttons[i]
		local setIndex = i + offset

		if ( setIndex <= #baseSets ) then
			local baseSet = baseSets[setIndex]
			--local count, complete = addon.GetSetCompletion(baseSet)
			button:Show()
			button.Name:SetText(baseSet.name)
			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceTopCounts(baseSet.setID)

			local setCollected = topSourcesCollected == topSourcesTotal --baseSet.collected -- C_TransmogSets.IsBaseSetCollected(baseSet.setID)
			local color = IN_PROGRESS_FONT_COLOR

			if ( setCollected ) then
				color = NORMAL_FONT_COLOR
			elseif ( topSourcesCollected == 0 ) then
				color = GRAY_FONT_COLOR
			end

			button.Name:SetTextColor(color.r, color.g, color.b)
			button.Label:SetText(baseSet.label) --(L["NOTE_"..(baseSet.label or 0)] and L["NOTE_"..(baseSet.label or 0) ]) or "")--((L["NOTE_"..baseSet.label] or "X"))
			button.Icon:SetTexture(SetsDataProvider:GetIconForSet(baseSet.setID))
			button.Icon:SetDesaturation((topSourcesCollected == 0) and 1 or 0)
			button.SelectedTexture:SetShown(baseSet.setID == selectedBaseSetID)
			button.Favorite:Hide() --SetShown(baseSet.favoriteSetID)
			--button.New:SetShown(SetsDataProvider:IsBaseSetNew(baseSet.setID))
			button.setID = baseSet.setID

			if ( topSourcesCollected == 0 or setCollected ) then
				button.ProgressBar:Hide()
			else
				button.ProgressBar:Show()
				button.ProgressBar:SetWidth(SET_PROGRESS_BAR_MAX_WIDTH * topSourcesCollected / topSourcesTotal)
			end
			button.IconCover:SetShown(not setCollected)
		else
			button:Hide()
		end
	end

	local extraHeight = (self.largeButtonHeight and self.largeButtonHeight - BASE_SET_BUTTON_HEIGHT) or 0
	local totalHeight = #baseSets * BASE_SET_BUTTON_HEIGHT + extraHeight
	HybridScrollFrame_Update(self, totalHeight, self:GetHeight())
end


--========--
-----Extra Sets Transmog Vendor Window

BetterWardrobeSetsTransmogMixin = CreateFromMixins(WardrobeSetsTransmogMixin)

function BetterWardrobeSetsTransmogMixin:LoadSet(setID)
	local waitingOnData = false
	local transmogSources = { }
	local sources = addon.GetSetsources(setID)

	for sourceID in pairs(sources) do
		local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
		local slot = C_Transmog.GetSlotForInventoryType(sourceInfo.invType)
		--local slotSources = C_TransmogSets.GetSourcesForSlot(setID, slot)
		--WardrobeCollectionFrame_SortSources(slotSources, sourceInfo.visualID)
		--local index = WardrobeCollectionFrame_GetDefaultSourceIndex(slotSources, sourceID)
		--transmogSources[slot] = sourceInfo.sourceID





		local slotSources = C_TransmogCollection.GetAppearanceSources(sourceInfo.visualID)

		--local slotSources = C_TransmogSets.GetSourcesForSlot(setID, slot)
		if slotSources then 
		WardrobeCollectionFrame_SortSources(slotSources, sourceInfo.visualID)

		local index = WardrobeCollectionFrame_GetDefaultSourceIndex(slotSources, sourceID)
		--transmogSources[slot] = sourceInfo.sourceID
		transmogSources[slot] = slotSources[index].sourceID;
	end

		for i, slotSourceInfo in ipairs(sourceInfo) do
			if ( not slotSourceInfo.name ) then
				waitingOnData = true
			end
		end
	end

	if ( waitingOnData ) then
		self.loadingSetID = setID

	else
		self.loadingSetID = nil
		-- if we don't ignore the event, clearing will momentarily set the page to the one with the set the user currently has transmogged
		-- if that's a different page from the current one then the models will flicker as we swap the gear to different sets and back
		self.ignoreTransmogrifyUpdateEvent = true
		C_Transmog.ClearPending()
		self.ignoreTransmogrifyUpdateEvent = false
		C_Transmog.LoadSources(transmogSources, -1, -1)

		if Profile.HideMissing then 

			local clearSlots = EmptySlots(transmogSources)
			for i, x in pairs(clearSlots) do
				local _,  source = addon.GetItemSource(x) --C_TransmogCollection.GetItemInfo(x)
				C_Transmog.SetPending(i, LE_TRANSMOG_TYPE_APPEARANCE,source)
			end


			local emptySlotData = GetEmptySlots()
			for i, x in pairs(transmogSources) do
				if not C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(x) and i ~= 7  and emptySlotData[i] then
					local _,  source = addon.GetItemSource(emptySlotData[i]) --C_TransmogCollection.GetItemInfo(emptySlotData[i])
					C_Transmog.SetPending(i, LE_TRANSMOG_TYPE_APPEARANCE, source)
				end
			end
		end
	
	end
end
--end

function BetterWardrobeSetsTransmogMixin:OnShow()
	self:RegisterEvent("TRANSMOGRIFY_UPDATE")
	self:RegisterEvent("TRANSMOGRIFY_SUCCESS")
	self:RegisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE")
	self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("TRANSMOG_SETS_UPDATE_FAVORITE")
	self:RefreshCameras()
	local RESET_SELECTION = true
	self:Refresh(RESET_SELECTION)
	WardrobeCollectionFrame.progressBar:Show()
	self:UpdateProgressBar()
	self.sourceQualityTable = { }

	--if (self:GetParent().SetsTabHelpBox:IsShown()) then
		--self:GetParent().SetsTabHelpBox:Hide()
		--SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB, true)
	--end
end


function BetterWardrobeSetsTransmogMixin:OnHide()
	self:UnregisterEvent("TRANSMOGRIFY_UPDATE");
	self:UnregisterEvent("TRANSMOGRIFY_SUCCESS");
	self:UnregisterEvent("TRANSMOG_COLLECTION_ITEM_UPDATE");
	self:UnregisterEvent("TRANSMOG_COLLECTION_UPDATED");
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
	self:UnregisterEvent("TRANSMOG_SETS_UPDATE_FAVORITE");
	self.loadingSetID = nil;
	SetsDataProvider:ClearSets();
	WardrobeCollectionFrame_ClearSearch(LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS);
	self.sourceQualityTable = nil;
end


function BetterWardrobeSetsTransmogMixin:UpdateSets()
	local usableSets = SetsDataProvider:GetUsableSets()
	self.PagingFrame:SetMaxPages(ceil(#usableSets / self.PAGE_SIZE))
	local pendingTransmogModelFrame = nil
	local indexOffset = (self.PagingFrame:GetCurrentPage() - 1) * self.PAGE_SIZE

	for i = 1, self.PAGE_SIZE do
		local model = self.Models[i]
		local index = i + indexOffset
		local set = usableSets[index]
--print(set)
		if ( set ) then
			model:Show()

			if ( model.setID ~= set.setID ) then
				model:Undress()
				local sourceData = SetsDataProvider:GetSetSourceData(set.setID)

				for sourceID  in pairs(sourceData.sources) do
					model:TryOn(sourceID)
				end
			end

			local transmogStateAtlas

			if ( set.setID == self.appliedSetID and set.setID == self.selectedSetID ) then
				transmogStateAtlas = "transmog-set-border-current-transmogged"
			elseif ( set.setID == self.selectedSetID ) then
				transmogStateAtlas = "transmog-set-border-selected"
				pendingTransmogModelFrame = model
			end

			if ( transmogStateAtlas ) then
				model.TransmogStateTexture:SetAtlas(transmogStateAtlas, true)
				model.TransmogStateTexture:Show()
			else
				model.TransmogStateTexture:Hide()
			end

			local topSourcesCollected, topSourcesTotal = SetsDataProvider:GetSetSourceCounts(set.setID)
			local setInfo = addon.GetSetInfo(set.setID)

			model.Favorite.Icon:SetShown(set.favorite)
			model.setID = set.setID
			model.setName:SetText(setInfo["name"].."\n"..(setInfo["description"] or ""))
			model.progress:SetText(topSourcesCollected.."/".. topSourcesTotal)
		else
			model:Hide()
		end
	end

	if ( pendingTransmogModelFrame ) then
		self.PendingTransmogFrame:SetParent(pendingTransmogModelFrame)
		self.PendingTransmogFrame:SetPoint("CENTER")
		self.PendingTransmogFrame:Show()

		if ( self.PendingTransmogFrame.setID ~= pendingTransmogModelFrame.setID ) then
			self.PendingTransmogFrame.TransmogSelectedAnim:Stop()
			self.PendingTransmogFrame.TransmogSelectedAnim:Play()
			self.PendingTransmogFrame.TransmogSelectedAnim2:Stop()
			self.PendingTransmogFrame.TransmogSelectedAnim2:Play()
			self.PendingTransmogFrame.TransmogSelectedAnim3:Stop()
			self.PendingTransmogFrame.TransmogSelectedAnim3:Play()
			self.PendingTransmogFrame.TransmogSelectedAnim4:Stop()
			self.PendingTransmogFrame.TransmogSelectedAnim4:Play()
			self.PendingTransmogFrame.TransmogSelectedAnim5:Stop()
			self.PendingTransmogFrame.TransmogSelectedAnim5:Play()
		end

		self.PendingTransmogFrame.setID = pendingTransmogModelFrame.setID
	else
		self.PendingTransmogFrame:Hide()
	end

	self.NoValidSetsLabel:SetShown(not C_TransmogSets.HasUsableSets())
end


function BetterWardrobeSetsTransmogMixin:OnSearchUpdate()
	SetsDataProvider:ClearUsableSets();
	SetsDataProvider:FilterSearch()
	self:UpdateSets();
end


local function GetPage(entryIndex, pageSize)
	return floor((entryIndex-1) / pageSize) + 1
end


function BetterWardrobeSetsTransmogMixin:ResetPage()
	local page = 1

	if ( self.selectedSetID ) then
		local usableSets = SetsDataProvider:GetUsableSets()
		self.PagingFrame:SetMaxPages(ceil(#usableSets / self.PAGE_SIZE))
		for i, set in ipairs(usableSets) do
			if ( set.setID == self.selectedSetID ) then
				page = GetPage(i, self.PAGE_SIZE)
				break
			end
		end
	end

	self.PagingFrame:SetCurrentPage(page)
	self:UpdateSets()
end


local TAB_ITEMS = 1
local TAB_SETS = 2
local TAB_EXTRASETS = 3
local TABS_MAX_WIDTH = 185

function BW_WardrobeCollectionFrame_OnLoad(self)
	WardrobeCollectionFrameTab1:Hide()
	WardrobeCollectionFrameTab2:Hide()
	PanelTemplates_SetNumTabs(self, 3);
	PanelTemplates_SetTab(self, TAB_ITEMS);
	PanelTemplates_ResizeTabsToFit(self, TABS_MAX_WIDTH);
	self.selectedCollectionTab = TAB_ITEMS;
	self.selectedTransmogTab = TAB_ITEMS;
end


function BW_WardrobeCollectionFrame_OnEvent(self, event, ...)
	if ( event == "UNIT_MODEL_CHANGED" ) then
		local hasAlternateForm, inAlternateForm = HasAlternateForm();
		if ( (self.inAlternateForm ~= inAlternateForm or self.updateOnModelChanged) ) then
			if ( self.activeFrame:OnUnitModelChangedEvent() ) then
				self.inAlternateForm = inAlternateForm;
				self.updateOnModelChanged = nil;
			end
		end
	elseif ( event == "TRANSMOG_SEARCH_UPDATED" ) then
		local searchType, arg1 = ...;
		--if ( searchType == self.activeFrame.searchType ) then
			--self.activeFrame:OnSearchUpdate(arg1);
		--end
	end
end

function BW_WardrobeCollectionFrame_OnShow(self)
	CollectionsJournal:SetPortraitToAsset("Interface\\Icons\\inv_chest_cloth_17");

	self:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player");
	self:RegisterEvent("TRANSMOG_SEARCH_UPDATED");

	local hasAlternateForm, inAlternateForm = HasAlternateForm();
	self.inAlternateForm = inAlternateForm;

	if ( WardrobeFrame_IsAtTransmogrifier() ) then
		BW_WardrobeCollectionFrame_SetTab(TAB_ITEMS);
	else
		BW_WardrobeCollectionFrame_SetTab(TAB_ITEMS);
	end
	--WardrobeCollectionFrame_UpdateTabButtons();
end

function BW_WardrobeCollectionFrame_OnHide(self)
	self:UnregisterEvent("UNIT_MODEL_CHANGED");
	self:UnregisterEvent("TRANSMOG_SEARCH_UPDATED");

	--C_TransmogCollection.EndSearch();
	self.jumpToVisualID = nil;
	for i, frame in ipairs(BW_WardrobeCollectionFrame.ContentFrames) do
		frame:Hide();
	end
end


function BetterWardrobeSetsCollectionMixin:HandleKey(key)
	if ( not self:GetSelectedSetID() ) then
		return false;
	end
	local selectedSetID = self:GetSelectedSetID()
	local _, index = SetsDataProvider:GetBaseSetByID(selectedSetID);
	if ( not index ) then
		return;
	end
	if ( key == WARDROBE_DOWN_VISUAL_KEY ) then
		index = index + 1;
	elseif ( key == WARDROBE_UP_VISUAL_KEY ) then
		index = index - 1;
	end
	local sets = SetsDataProvider:GetBaseSets();
	index = Clamp(index, 1, #sets);
	self:SelectSet(sets[index].setID)
	self:ScrollToSet(sets[index].setID);
end

function BetterWardrobeSetsCollectionMixin:ScrollToSet(setID)
	local totalHeight = 0;
	local scrollFrameHeight = self.ScrollFrame:GetHeight();
	local buttonHeight = self.ScrollFrame.buttonHeight;
	for i, set in ipairs(SetsDataProvider:GetBaseSets()) do
		if ( set.setID == setID ) then
			local offset = self.ScrollFrame.scrollBar:GetValue();
			if ( totalHeight + buttonHeight > offset + scrollFrameHeight ) then
				offset = totalHeight + buttonHeight - scrollFrameHeight;
			elseif ( totalHeight < offset ) then
				offset = totalHeight;
			end
			self.ScrollFrame.scrollBar:SetValue(offset, true);
			break;
		end
		totalHeight = totalHeight + buttonHeight;
	end
end

function BW_WardrobeCollectionFrame_OnKeyDown(self, key)
	if ( self.tooltipCycle and key == WARDROBE_CYCLE_KEY ) then
		self:SetPropagateKeyboardInput(false);
		if ( IsShiftKeyDown() ) then
			self.tooltipSourceIndex = self.tooltipSourceIndex - 1;
		else
			self.tooltipSourceIndex = self.tooltipSourceIndex + 1;
		end
		self.tooltipContentFrame:RefreshAppearanceTooltip();
	elseif ( key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY ) then
		if ( self.activeFrame:CanHandleKey(key) ) then
			self:SetPropagateKeyboardInput(false);
			self.activeFrame:HandleKey(key);
		else
			self:SetPropagateKeyboardInput(true);
		end
	else
		self:SetPropagateKeyboardInput(true);
	end
end