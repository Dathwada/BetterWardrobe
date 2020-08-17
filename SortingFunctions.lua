--Based off of code from WardrobeSort - https://www.curseforge.com/wow/addons/wardrobesort

local addonName, addon = ...
--addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

local f = CreateFrame("Frame")
local Wardrobe = WardrobeCollectionFrame.ItemsCollectionFrame

local db, active
local FileData
local SortOrder

local nameVisuals, nameCache = {}, {}
local catCompleted, itemLevels = {}, {}
local unknown = {-1}
local LegionWardrobeY = IsAddOnLoaded("LegionWardrobe") and 55 or 5

local LE_DEFAULT = 1
local LE_APPEARANCE = 2
local LE_ALPHABETIC = 3
local LE_ITEM_SOURCE = 5
local LE_EXPANSION = 6
local LE_COLOR = 4
local TAB_ITEMS = 1;
local TAB_SETS = 2;
local TAB_EXTRASETS = 3;

local L = {
	[LE_DEFAULT] = DEFAULT,
	[LE_APPEARANCE] = APPEARANCE_LABEL,
	[LE_ALPHABETIC] = COMPACT_UNIT_FRAME_PROFILE_SORTBY_ALPHABETICAL,
	[LE_ITEM_SOURCE] = SOURCE:gsub("[:：]", ""),
	[LE_COLOR] = COLOR,
	[LE_EXPANSION] = "Expansion.."
}

local dropdownOrder = {LE_DEFAULT, LE_ALPHABETIC, LE_APPEARANCE, LE_COLOR, LE_ITEM_SOURCE, LE_EXPANSION}

local defaults = {
	db_version = 2,
	sortDropdown = LE_DEFAULT,
	reverse = false,
}

local colors = {
	"red", -- 255, 0, 0
	"crimson", -- 255, 0, 63
	"maroon", -- 128, 0, 0
	"pink", -- 255, 192, 203
	"lavender", -- 230, 230, 250
	"purple", -- 128, 0, 128
	"indigo", -- 75, 0, 130
	
	"blue", -- 0, 0, 255
	"teal", -- 0, 128, 128
	"cyan", -- 0, 255, 255
	
	"green", -- 0, 255, 0
	"yellow", -- 255, 255, 0
	"gold", -- 255, 215, 0
	"orange", -- 255, 128, 0
	"brown", -- 128, 64, 0
	
	"black", -- 0, 0, 0
	"gray", -- 128, 128, 128
	"grey",
	"silver", -- 192, 192, 192
	"white", -- 255, 255, 255
}



local function getTab()

local atTransmogrifier = WardrobeFrame_IsAtTransmogrifier()
local tabID

	if ( atTransmogrifier ) then
		tabID = WardrobeCollectionFrame.selectedTransmogTab
	else
		tabID = WardrobeCollectionFrame.selectedCollectionTab
	end
	return tabID, atTransmogrifier

end


local function mysort(set1, set2)
		if ( set1.expansionID ~= set2.expansionID ) then
			return set1.expansionID > set2.expansionID;
		end

        return set1.name < set2.name;
    end


local function GetCollectionList(self)
	local  tabID, atTransmogrifier = getTab()
	local list = {}

		if tabID == 2 or  tabID == 3 then 

		else 
			
			list = Wardrobe.filteredVisualsList
		end

		return list
	end


local function SortNormal(a, b)
	return a < b
end


local function SortReverse(a, b)
	return a > b
end


local function SortColor(source1, source2)
	local file1 = addon.ItemAppearance[source1.visualID]
	local file2 = addon.ItemAppearance[source2.visualID]
	
	if file1 and file2 then
		local index1 = #colors+1
		for k, v in pairs(colors) do
			if strfind(file1, v) then
				index1 = k
				break
			end
		end
		
		local index2 = #colors+1
		for k, v in pairs(colors) do
			if strfind(file2, v) then
				index2 = k
				break
			end
		end
		
		if index1 == index2 then
			return SortOrder(file1, file2)
		else
			return SortOrder(index1, index2)
		end
	else
		return SortOrder(source1.uiOrder, source2.uiOrder)
	end
end


local function SortAlphabetic()
	if Wardrobe:IsVisible() then -- check if wardrobe is still open after caching is finished
		sort(Wardrobe:GetFilteredVisualsList(), function(source1, source2)
			if nameVisuals[source1.visualID] and nameVisuals[source2.visualID] then
				return SortOrder(nameVisuals[source1.visualID], nameVisuals[source2.visualID])
			else
				return SortOrder(source1.uiOrder, source2.uiOrder)
			end
		end)
		Wardrobe:UpdateItems()
	end
end


 -- takes around 5 to 30 onupdates
local function CacheHeaders()
	for k in pairs(nameCache) do
		-- oh my god so much wasted tables
		local appearances = WardrobeCollectionFrame_GetSortedAppearanceSources(k)[1]
		if appearances.name then
			nameVisuals[k] = appearances.name
			nameCache[k] = nil
		end
	end
	
	if not next(nameCache) then
		catCompleted[Wardrobe:GetActiveCategory()] = true
		f:SetScript("OnUpdate", nil)
		SortAlphabetic()
	end
end


addon.Sort = {
	[TAB_ITEMS] = {
		[LE_DEFAULT] = function() end,
		
		[LE_APPEARANCE] = function(self)
			sort(self:GetFilteredVisualsList(), function(source1, source2)
				if addon.ItemAppearance[source1.visualID] and addon.ItemAppearance[source2.visualID] then
					return SortOrder(addon.ItemAppearance[source1.visualID], addon.ItemAppearance[source2.visualID])
				else
					return SortOrder(source1.uiOrder, source2.uiOrder)
				end
			end)
		end,
		
		[LE_ALPHABETIC] = function(self)
			if catCompleted[self:GetActiveCategory()] then
				SortAlphabetic()
			else
				for _, v in pairs(self:GetFilteredVisualsList()) do
					nameCache[v.visualID] = true -- queue data to be cached	
				end
				f:SetScript("OnUpdate", CacheHeaders)
			end
		end,
		
		[LE_ITEM_SOURCE] = function(self)
			sort(self:GetFilteredVisualsList(), function(source1, source2)
			local item1 = WardrobeCollectionFrame_GetSortedAppearanceSources(source1.visualID)[1]
			local item2 = WardrobeCollectionFrame_GetSortedAppearanceSources(source2.visualID)[1]
			item1.sourceType = item1.sourceType or 7
			item2.sourceType = item2.sourceType or 7
			
			if item1.sourceType == item2.sourceType then
				if item1.sourceType == TRANSMOG_SOURCE_BOSS_DROP then
					local drops1 = C_TransmogCollection.GetAppearanceSourceDrops(item1.sourceID)
					local drops2 = C_TransmogCollection.GetAppearanceSourceDrops(item2.sourceID)
					
					if #drops1 > 0 and #drops2 > 0 then
						local instance1, encounter1 = drops1[1].instance, drops1[1].encounter
						local instance2, encounter2 = drops2[1].instance, drops2[1].encounter
						
						if instance1 == instance2 then
							return SortOrder(encounter1, encounter2)
						else
							return SortOrder(instance1, instance2)
						end
					end
				else
					if addon.ItemAppearance[source1.visualID] and addon.ItemAppearance[source2.visualID] then
						return SortOrder(addon.ItemAppearance[source1.visualID], addon.ItemAppearance[source2.visualID])
					end
				end
			else
				return SortOrder(item1.sourceType, item2.sourceType)
			end
			return SortOrder(source1.uiOrder, source2.uiOrder)
		end)

		end,
		
		-- sort by the color in filename
		[LE_COLOR] = function(self)
			sort(Wardrobe:GetFilteredVisualsList(), SortColor)
		end,

		[LE_EXPANSION] = 	function(self)
			sort(self:GetFilteredVisualsList(), function(source1, source2)
			local item1 = WardrobeCollectionFrame_GetSortedAppearanceSources(source1.visualID)[1]
			local item2 = WardrobeCollectionFrame_GetSortedAppearanceSources(source2.visualID)[1]
			item1.itemID = item1.itemID or 0
			item2.itemID = item2.itemID or 0

				_, _, _, _, _, _, _, _,_, _, _, _, _, _, item1.expacID = GetItemInfo(item1.itemID)
				_, _, _, _, _, _, _, _,_, _, _, _, _, _, item2.expacID = GetItemInfo(item2.itemID)

			if ( item1.expacID ~= item2.expacID ) then
				return item1.expacID > item2.expacID;
			end

		

			return item1.name > item2.name;


			end)
		end,
	},
	[TAB_SETS] = {
		[LE_DEFAULT] = function(self, sets, reverseUIOrder, ignorePatchID)
			sort(sets, function(set1, set2)

				return set1.name > set2.name;
				end)
		end,

		[LE_ALPHABETIC] = function(self, sets, reverseUIOrder, ignorePatchID)
		end,

		[LE_APPEARANCE] = function(self, sets, reverseUIOrder, ignorePatchID)
			for i, data in ipairs(sets) do
				local setID = data.setID
				local sources = C_TransmogSets.GetSetSources(setID)  --[{sourceID =collected}]
				local sourceID

				for i,d in pairs(sources) do
				 	sourceID = i
					 break
				end
			
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				data.visualID = sourceInfo.visualID
			end

			sort(sets, function(source1, source2)
					if addon.ItemAppearance[source1.visualID] and addon.ItemAppearance[source2.visualID] then
						return SortOrder(addon.ItemAppearance[source1.visualID], addon.ItemAppearance[source2.visualID])
					else
						return SortOrder(source1.uiOrder, source2.uiOrder)
					end
				end)
		end,

		-- sort by the color in filename
		[LE_COLOR] = function(self, sets, reverseUIOrder, ignorePatchID)
			for i, data in ipairs(sets) do
				local setID = data.setID
				local sources = C_TransmogSets.GetSetSources(setID)  --[{sourceID =collected}]
				local sourceID

				for i,d in pairs(sources) do
				 	sourceID = i
					 break
				end
			
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				data.visualID = sourceInfo.visualID
			end

			sort(sets, SortColor)
		end,

		[LE_ITEM_SOURCE] = function(self, sets, reverseUIOrder, ignorePatchID)
		end,
		
		[LE_EXPANSION] = function(self, sets, reverseUIOrder, ignorePatchID)
		local comparison = function(set1, set2)
			local groupFavorite1 = set1.favoriteSetID and true;
			local groupFavorite2 = set2.favoriteSetID and true;
	
			if ( set1.expansionID ~= set2.expansionID ) then
				return set1.expansionID > set2.expansionID;
			end

			if not ignorePatchID then
				if ( set1.patchID ~= set2.patchID ) then
					return set1.patchID > set2.patchID;
				end
			end

			if ( set1.uiOrder ~= set2.uiOrder ) then
				if ( reverseUIOrder ) then
					return set1.uiOrder < set2.uiOrder;
				else
					return set1.uiOrder > set2.uiOrder;
				end
			end

			if reverseUIOrder then
				return set1.setID < set2.setID;
			else
				return set1.setID > set2.setID;
			end

			return set1.name > set2.name;
			end

			table.sort(sets, comparison)

		end,
	},

	[TAB_EXTRASETS] = {
		[LE_DEFAULT]  = function(self, sets, reverseUIOrder, ignorePatchID)
			local comparison = function(set1, set2)
			local groupFavorite1 = set1.favoriteSetID and true;
			local groupFavorite2 = set2.favoriteSetID and true;
			if ( groupFavorite1 ~= groupFavorite2 ) then
				return groupFavorite1;
			end

			if ( set1.favorite ~= set2.favorite ) then
				return set1.favorite;
			end

			if ( set1.expansionID ~= set2.expansionID ) then
				return set1.expansionID > set2.expansionID;
			end

			if not ignorePatchID then
				if ( set1.patchID ~= set2.patchID ) then
					return set1.patchID > set2.patchID;
				end
			end

			if ( set1.uiOrder ~= set2.uiOrder ) then
				if ( reverseUIOrder ) then
					return set1.uiOrder < set2.uiOrder;
				else
					return set1.uiOrder > set2.uiOrder;
				end
			end

			if reverseUIOrder then
				return set1.setID < set2.setID;
			else
				return set1.setID > set2.setID;
			end

			return set1.name > set2.name;
			end



			table.sort(sets, comparison)
			table.sort(sets, mysort)
		end,

		[LE_ALPHABETIC] = function(self, sets, reverseUIOrder, ignorePatchID)
		end,

		[LE_APPEARANCE] = function(self, sets, reverseUIOrder, ignorePatchID)
				for i, data in ipairs(sets) do
				local baseItem = data.items[1]
				local _, sourceID = addon.GetItemSource(baseItem)
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				data.visualID = sourceInfo.visualID
			end

		sort(sets, function(source1, source2)
				if addon.ItemAppearance[source1.visualID] and addon.ItemAppearance[source2.visualID] then
					return SortOrder(addon.ItemAppearance[source1.visualID], addon.ItemAppearance[source2.visualID])
				else
					return SortOrder(source1.uiOrder, source2.uiOrder)
				end
			end)
		end,
		
		-- sort by the color in filename
		[LE_COLOR] = function(self, sets, reverseUIOrder, ignorePatchID)
			for i, data in ipairs(sets) do
				local baseItem = data.items[1]
				local _, sourceID = addon.GetItemSource(baseItem)
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				data.visualID = sourceInfo.visualID
			end

		sort(sets, SortColor)
		end,

		[LE_ITEM_SOURCE] = function(self, sets, reverseUIOrder, ignorePatchID)
			
		end,

		[LE_EXPANSION] = function(self, sets, reverseUIOrder, ignorePatchID)
		local comparison = function(set1, set2)
			local groupFavorite1 = set1.favoriteSetID and true;
			local groupFavorite2 = set2.favoriteSetID and true;
	
			if ( set1.expansionID ~= set2.expansionID ) then
				return set1.expansionID > set2.expansionID;
			end

			if not ignorePatchID then
				if ( set1.patchID ~= set2.patchID ) then
					return set1.patchID > set2.patchID;
				end
			end

			if ( set1.uiOrder ~= set2.uiOrder ) then
				if ( reverseUIOrder ) then
					return set1.uiOrder < set2.uiOrder;
				else
					return set1.uiOrder > set2.uiOrder;
				end
			end

			if reverseUIOrder then
				return set1.setID < set2.setID;
			else
				return set1.setID > set2.setID;
			end

			return set1.name > set2.name;
			end
			
			table.sort(sets, comparison)
		end,
	},
}

function addon.SetSortOrder()
	SortOrder = addon.sortDB.reverse and SortReverse or SortNormal
end


function addon.SortCollection(frame)
if getTab() == 1 then 
addon.Sort[1][addon.sortDB.sortDropdown](Wardrobe)
Wardrobe:UpdateItems()
end
end


function addon.SortSet(sets, reverseUIOrder, ignorePatchID)
 
	addon.Sort[getTab()][addon.sortDB.sortDropdown](self, sets, reverseUIOrder, ignorePatchID)

end
	--===
	-- sort and update
	--hooksecurefunc(WardrobeCollectionFrame.ItemsCollectionFrame, "SortVisuals", function()
		-- exclude enchants/illusions by checking for category
		--if WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory() then
			--addon.SortCollection(WardrobeCollectionFrame.ItemsCollectionFrame)
			
			--UIDropDownMenu_EnableDropDown(BW_SortDropDown)
		--else
			--UIDropDownMenu_DisableDropDown(BW_SortDropDown)
		--end
	--end)




		hooksecurefunc(Wardrobe, "SortVisuals", function(self)
		-- exclude enchants/illusions by checking for category
		if getTab() == 1 then 
			if self:GetActiveCategory() then
				--sortFunc[db.sortDropdown](self)
				addon.Sort[1][addon.sortDB.sortDropdown](self)
				self:UpdateItems()
				--UIDropDownMenu_EnableDropDown(BW_SortDropDown)
			else
				--UIDropDownMenu_DisableDropDown(BW_SortDropDown)
			end
		else 

		end
	end)



