local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local Profile
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local UI = {}

local LE_DEFAULT = addon.Globals.LE_DEFAULT
local LE_APPEARANCE = addon.Globals.LE_APPEARANCE
local LE_ALPHABETIC = addon.Globals.LE_ALPHABETIC
local LE_ITEM_SOURCE = addon.Globals.LE_ITEM_SOURCE
local LE_EXPANSION = addon.Globals.LE_EXPANSION
local LE_COLOR = addon.Globals.LE_COLOR

local TAB_ITEMS = addon.Globals.TAB_ITEMS
local TAB_SETS = addon.Globals.TAB_SETS
local TAB_EXTRASETS = addon.Globals.TAB_EXTRASETS
local TAB_SAVED_SETS = addon.Globals.TAB_SAVED_SETS
local TABS_MAX_WIDTH = addon.Globals.TABS_MAX_WIDTH


local db, active
local FileData
local SortOrder


local dropdownOrder = {LE_DEFAULT, LE_ALPHABETIC, LE_APPEARANCE, LE_COLOR, LE_EXPANSION, LE_ITEM_SOURCE}
local locationDrowpDown = addon.Globals.locationDrowpDown

--= {INVTYPE_HEAD, INVTYPE_SHOULDER, INVTYPE_CLOAK, INVTYPE_CHEST, INVTYPE_WAIST, INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_WRIST, INVTYPE_HAND}
local defaults = {
	sortDropdown = LE_DEFAULT,
	reverse = false,
}



function addon.Init:BuildCollectionJournalUI()
	UI.SortDropDown_Initialize()
	UI.RepositionSortDropDown()
	--UI.LocationDropDown_Initialize()
	UI.SavedSetsDropDown_Initialize()

 --UI.CreateFilterMenu()
	CreateVisualViewButton()

	WardrobeCollectionFrame.searchBox:SetFrameLevel(BW_WardrobeCollectionFrame:GetFrameLevel()+10)
	WardrobeCollectionFrame.FilterButton:SetFrameLevel(BW_WardrobeCollectionFrame:GetFrameLevel()+10)
	BW_WardrobeCollectionFrame.FilterButton:SetFrameLevel(BW_WardrobeCollectionFrame:GetFrameLevel()+10)
	BW_WardrobeCollectionFrame.FilterButton:SetPoint("TOPLEFT", WardrobeCollectionFrame.FilterButton, "TOPLEFT")
	
	BW_WardrobeCollectionFrame:GetFrameLevel()
	WardrobeCollectionFrame.searchBox:SetFrameLevel(BW_WardrobeCollectionFrame:GetFrameLevel()+10)
	WardrobeCollectionFrame.FilterButton:SetFrameLevel(BW_WardrobeCollectionFrame:GetFrameLevel()+10)
	BW_WardrobeCollectionFrame.FilterButton:SetFrameLevel(BW_WardrobeCollectionFrame:GetFrameLevel()+10)
	BW_WardrobeCollectionFrame.FilterButton:SetPoint("TOPLEFT", WardrobeCollectionFrame.FilterButton, "TOPLEFT")

	--UI.BuildLoadQueueButton()
	--UI.DefaultButtons_Update()

--	WardrobeFrame:HookScript("OnShow",  function() print("XXX"); UI.ExtendTransmogView() end)
--hooksecurefunc(WardrobeCollectionFrame.ItemsCollectionFrame, "UpdateWeaponDropDown", PositionDropDown)
end

function CreateVisualViewButton()
	local b = CreateFrame("Button", "BW_WardrobeToggle", WardrobeCollectionFrame, "EyeTemplate")
	b:SetSize(30 ,30) -- width, height
	b:Hide()
	b.texture:SetTexCoord(0.125, 0.25, 0.25, 0.5)
	b:SetPoint("CENTER")
	b:SetPoint("LEFT", WardrobeCollectionFrame.progressBar, "RIGHT")
	b:SetScript("OnClick", function(self)
		local baseFrame
		self.viewAll = false
		local aCtrlKeyIsDown = IsControlKeyDown()

		if aCtrlKeyIsDown then
				addon.Profile.ShowHidden = not addon.Profile.ShowHidden
				WardrobeCollectionFrame.SetsTransmogFrame:OnSearchUpdate()
				BW_SetsTransmogFrame:OnSearchUpdate()
				WardrobeCollectionFrame.SetsCollectionFrame:OnSearchUpdate()
				BW_SetsCollectionFrame:OnSearchUpdate()
				return
		end

		local atTransmogrifier = WardrobeFrame_IsAtTransmogrifier()
		if (atTransmogrifier) then
			local tab = WardrobeCollectionFrame.selectedTransmogTab
			if tab == 2  or tab == 3  or tab == 4 then 
				self.VisualMode = not self.VisualMode
				WardrobeCollectionFrame.SetsTransmogFrame:OnSearchUpdate()
				BW_SetsTransmogFrame:OnSearchUpdate()
			end
		else
			local tab = WardrobeCollectionFrame.selectedCollectionTab
			if tab == 2 then
				if WardrobeCollectionFrame.SetsCollectionFrame:IsShown() then
					self.VisualMode = true
					self.viewAll = true
					WardrobeCollectionFrame.SetsTransmogFrame:Show()
					WardrobeCollectionFrame.SetsCollectionFrame:Hide()
					WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsTransmogFrame
					BW_WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsTransmogFrame
					WardrobeCollectionFrame.SetsTransmogFrame:OnSearchUpdate()
					WardrobeCollectionFrame.FilterButton:Hide()
				else
					self.VisualMode = false
					self.viewAll = false
					WardrobeCollectionFrame.SetsTransmogFrame:Hide()
					WardrobeCollectionFrame.SetsCollectionFrame:Show()
					WardrobeCollectionFrame.FilterButton:Show()
					WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsCollectionFrame
					BW_WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsCollectionFrame
				end

			elseif tab == 3 or tab == 4 then
				if BW_WardrobeCollectionFrame.BW_SetsCollectionFrame:IsShown() then
					self.VisualMode = true
					self.viewAll = true
					BW_WardrobeCollectionFrame.BW_SetsTransmogFrame:Show()
					BW_WardrobeCollectionFrame.BW_SetsCollectionFrame:Hide()
					WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsTransmogFrame
					BW_WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsTransmogFrame
					BW_SetsTransmogFrame:OnSearchUpdate()
				else
					self.VisualMode = false
					self.viewAll = false
					BW_WardrobeCollectionFrame.BW_SetsTransmogFrame:Hide()
					BW_WardrobeCollectionFrame.BW_SetsCollectionFrame:Show()
					WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsCollectionFrame
					BW_WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsCollectionFrame
				end

				if tab == 4 then
					local savedCount = #addon.GetSavedList()
					WardrobeCollectionFrame_UpdateProgressBar(savedCount, savedCount)
				end
			end
		end
	end)
	
	b:SetScript("OnHide", function(self)
			--BW_WardrobeCollectionFrame.BW_SetsTransmogFrame:Hide()
			self.VisualMode = false
		end)

	b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Visual View")
			GameTooltip:Show()
		end)

	b:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
end




--Repositions sort dropown if Legion Wardrobe is loaded
function UI.RepositionSortDropDown()
	local Wardrobe = WardrobeCollectionFrame.ItemsCollectionFrame
	if WardrobeFrame_IsAtTransmogrifier() then
		local _, isWeapon = C_TransmogCollection.GetCategoryInfo(Wardrobe:GetActiveCategory() or -1)
		BW_SortDropDown:SetPoint("TOPLEFT", Wardrobe.WeaponDropDown, "BOTTOMLEFT", 0, isWeapon and 55 or 32)
	else
		BW_SortDropDown:SetPoint("TOPLEFT", Wardrobe.WeaponDropDown, "BOTTOMLEFT", 0, LegionWardrobeY)
	end
end

--AceDropdownmenu for the Collection Journal sorting options -Shouldn't cause taint
function UI.SortDropDown_Initialize()
	if not addon.sortDB then
		addon.sortDB = CopyTable(defaults)
	end
	local Wardrobe = WardrobeCollectionFrame.ItemsCollectionFrame
	db = addon.sortDB

	local  f = addon.Frame:Create("SimpleGroup")
		BW_SortDropDown = f
	--UI.SavedSetDropDownFrame = f
	f.frame:SetParent("BW_WardrobeCollectionFrame")
	f:SetWidth(87)--, 22)
	f:SetHeight(22)

	f:ClearAllPoints()
	f:SetPoint("TOPRIGHT", -6, -22)

	--f:SetPoint("TOPLEFT", "BW_SortDropDown", "TOPLEFT")
	local list = {}

	for _, name in ipairs(dropdownOrder)do
		tinsert(list,L[name])
	end

	local dropdown = addon.Frame:Create("Dropdown")

	BW_SortDropDown.dropdown = dropdown
	dropdown:SetWidth(175)--, 22)
	--dropdown:SetHeight(22)
	f:AddChild(dropdown)
	dropdown:SetList(list)
	dropdown:SetValue(db.sortDropdown)
	dropdown:SetText(COMPACT_UNIT_FRAME_PROFILE_SORTBY.." "..L[db.sortDropdown])

	dropdown:SetCallback("OnValueChanged", function(widget) 
			db.sortDropdown = widget.value
			db.reverse = IsModifierKeyDown()
			addon.SetSortOrder(db.reverse)
			local tabID = addon.GetTab()
			if tabID == 1 then
				--Wardrobe:OnShow()
				Wardrobe:RefreshVisualsList()
				Wardrobe:UpdateItems()
				Wardrobe:UpdateWeaponDropDown()
			elseif tabID == 2 then
				WardrobeCollectionFrame.SetsCollectionFrame:OnSearchUpdate()
				WardrobeCollectionFrame.SetsTransmogFrame:OnSearchUpdate()
			elseif tabID == 3 then
				BW_SetsCollectionFrame:OnSearchUpdate()
				BW_SetsTransmogFrame:OnSearchUpdate()
			end
			dropdown:SetText(COMPACT_UNIT_FRAME_PROFILE_SORTBY.." "..L[db.sortDropdown])
	end)

end


function BW_WardrobeFilterDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, UI.FilterMenu_InitializeItems, "MENU")
end


local FILTER_SOURCES = addon.Globals.FILTER_SOURCES
local EXPANSIONS = addon.Globals.EXPANSIONS
local filterCollected = {true, true}
local missingSelection = {}
local filterSelection = {}
local xpacSelection = {}
addon.filterCollected = filterCollected
addon.xpacSelection = xpacSelection
addon.filterSelection = filterSelection
addon.missingSelection = missingSelection

function addon:InitTables()
	for i = 1, #FILTER_SOURCES do
		filterSelection[i] = true
	end

	for i = 1, #EXPANSIONS do
		xpacSelection[i] = true
	end
end


addon:InitTables()

local function RefreshLists()
	local tabID = addon.GetTab()
	if tabID == 2 then
		WardrobeCollectionFrame.SetsCollectionFrame:OnSearchUpdate()
		--WardrobeCollectionFrame.SetsTransmogFrame:OnSearchUpdate()
	elseif tabID == 3 then
		BW_SetsCollectionFrame:OnSearchUpdate()
	--	BW_SetsTransmogFrame:OnSearchUpdate()
	end
end


--Dropdown for the CollectionJournal Filter Menu  -possible Taint Source
function UI:FilterMenu_InitializeItems(level)
	if (not WardrobeCollectionFrame.activeFrame) then
		return
	end

	local info = UIDropDownMenu_CreateInfo()
	info.keepShownOnClick = true
	local atTransmogrifier = WardrobeFrame_IsAtTransmogrifier()

	if level == 1 then
		local refreshLevel = 1
		info.text = COLLECTED
		info.func = function(_, _, _, value)
						filterCollected[1] = value
						RefreshLists()
						--UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		info.checked = 	function() return filterCollected[1] end
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_, _, _, value)
						filterCollected[2] =  value
						RefreshLists()
						--UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		info.checked = 	function() return filterCollected[2] end
		info.isNotRadio = true

		UIDropDownMenu_AddButton(info, level)
		UIDropDownMenu_AddSeparator()

		info.checked = 	nil
		info.isNotRadio = nil
		info.func =  nil
		info.hasArrow = true
		info.notCheckable = true

		info.text = SOURCES
		info.value = 1
		info.isNotRadio = true
		--info.arg1 = self:GetName().."Check"
		--info.func = function(dropdownbutton, arg1)
			--_G[arg1]:Hide()
		--end,
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Expansion"]
		info.value = 2
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Missing:"]
		info.value = 3
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Armor Type"]
		info.value = 4
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2  and UIDROPDOWNMENU_MENU_VALUE == 1 then
		local refreshLevel = 2
		info.hasArrow = false
		info.isNotRadio = true
		info.notCheckable = true
		--tinsert(filterSelection,true)
		info.text = CHECK_ALL
		info.func = function()
						for i = 1, #filterSelection do
								filterSelection[i] = true
						end
						RefreshLists()
						UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		UIDropDownMenu_AddButton(info, level)

		local refreshLevel = 2
		info.hasArrow = false
		info.isNotRadio = true
		info.notCheckable = true
		--tinsert(filterSelection,true)

		info.text = UNCHECK_ALL
		info.func = function()
						for i = 1, #filterSelection do
								filterSelection[i] = false
						end
						RefreshLists()
						UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		UIDropDownMenu_AddButton(info, level)
		UIDropDownMenu_AddSeparator(level)

		info.notCheckable = false

		local numSources = #FILTER_SOURCES --C_TransmogCollection.GetNumTransmogSources()
		for i = 1, numSources do
			--tinsert(filterSelection,true)
			info.text = FILTER_SOURCES[i]
				info.func = function(_, _, _, value)
					filterSelection[i] = value
					RefreshLists()
				end
				info.checked = 	function() return filterSelection[i] end
			UIDropDownMenu_AddButton(info, level)
		end

	elseif level == 2  and UIDROPDOWNMENU_MENU_VALUE == 2 then
		local refreshLevel = 2
		info.hasArrow = false
		info.isNotRadio = true
		info.notCheckable = true
		info.text = CHECK_ALL
		info.func = function()
						for i = 1, #xpacSelection do
							xpacSelection[i] = true
						end
						RefreshLists()
						UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		UIDropDownMenu_AddButton(info, level)

		local refreshLevel = 2
		info.hasArrow = false
		info.isNotRadio = true
		info.notCheckable = true

		info.text = UNCHECK_ALL
		info.func = function()
						for i = 1, #xpacSelection do
								xpacSelection[i] = false
						end
						RefreshLists()
						UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		UIDropDownMenu_AddButton(info, level)
		UIDropDownMenu_AddSeparator(level)

		info.notCheckable = false
		for i = 1, #EXPANSIONS do
			info.text = EXPANSIONS[i]
				info.func = function(_, _, _, value)
					xpacSelection[i] = value
					RefreshLists()
				end
				info.checked = 	function() return xpacSelection[i] end
			UIDropDownMenu_AddButton(info, level)
		end

	elseif level == 2  and UIDROPDOWNMENU_MENU_VALUE == 3 then
		info.hasArrow = false
		info.isNotRadio = true
		info.notCheckable = true
		local refreshLevel = 2

		info.text = CHECK_ALL
		info.func = function()
						for i in pairs(locationDrowpDown) do
							missingSelection[i] = true
						end
						RefreshLists()
						UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		UIDropDownMenu_AddButton(info, level)

		info.text = UNCHECK_ALL
		info.func = function()
						for i in pairs(locationDrowpDown) do
							missingSelection[i] = false
						end
						RefreshLists()
						UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
					end
		UIDropDownMenu_AddButton(info, level)
		UIDropDownMenu_AddSeparator(level)

		for index, id in pairs(locationDrowpDown) do
			if index ~= 21 then --Skip "robe" type
				info.text = id
				info.notCheckable = false
				info.func = function(_, _, _, value)
							missingSelection[index] = value

							if index == 6 then
								missingSelection[21] = value
							end

							UIDropDownMenu_Refresh(BW_WardrobeFilterDropDown)
							RefreshLists()
						end
				info.checked = function() return missingSelection[index] end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	elseif level == 2  and UIDROPDOWNMENU_MENU_VALUE == 4 then
		local counter = 1
		for name in pairs(addon.Globals.ARMOR_MASK) do
			info.keepShownOnClick = false
			info.text = name
			info.func = function(info, arg1, _, value)
					addon.selectedArmorType = arg1
					--addon.extraSetsCache = nil
					BW_WardrobeCollectionFrame_SetTab(2)
					BW_WardrobeCollectionFrame_SetTab(3)
			end
			info.arg1 = name
			info.checked = 	function() return addon.selectedArmorType == name end
			UIDropDownMenu_AddButton(info, level)
		end

	end
--end
end


--AceDropdownmenu for the selection of other character's saved sets -Shouldn't cause taint
function UI.SavedSetsDropDown_Initialize(self)
	local  f = addon.Frame:Create("SimpleGroup")
	UI.SavedSetDropDownFrame = f
	f.frame:SetParent("BW_WardrobeCollectionFrame")
	f:SetWidth(87)--, 22)
	f:SetHeight(22)

	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", BW_SortDropDown.frame, "TOPLEFT")
	local list = {}

	for name in pairs(addon.setdb.global.sets)do
		tinsert(list, name)
	end

	local dropdown = addon.Frame:Create("Dropdown")
	dropdown:SetWidth(175)--, 22)
	--dropdown:SetHeight(22)
	f:AddChild(dropdown)
	dropdown:SetList(list)

	for i, name in ipairs(list) do
		if name == addon.setdb:GetCurrentProfile() then
			dropdown:SetValue(i)
			break
		end
	end
	
	dropdown:SetCallback("OnValueChanged", function(widget) 
		local value = widget.list[widget.value]
		local name = UnitName("player")
		local realm = GetRealmName()

		if value ~= addon.setdb:GetCurrentProfile() then 
			addon.SelecteSavedList = widget.list[widget.value]
		else
			addon.SelecteSavedList = false
		end
		BW_WardrobeCollectionFrame_SetTab(2)
		BW_WardrobeCollectionFrame_SetTab(4)
		addon.savedSetCache = nil
	end)
end


--- Functionality to add tabs to window
function BW_WardrobeCollectionFrame_ClickTab(tab)
	BW_WardrobeCollectionFrame_SetTab(tab:GetID())
	PanelTemplates_ResizeTabsToFit(WardrobeCollectionFrame, TABS_MAX_WIDTH)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function BW_WardrobeCollectionFrame_SetTab(tabID)
	PanelTemplates_SetTab(BW_WardrobeCollectionFrame, tabID)
	local atTransmogrifier = WardrobeFrame_IsAtTransmogrifier()
	if atTransmogrifier then
		WardrobeCollectionFrame.selectedTransmogTab = tabID
		BW_WardrobeCollectionFrame.selectedTransmogTab = tabID
	else
		WardrobeCollectionFrame.selectedCollectionTab = tabID
		BW_WardrobeCollectionFrame.selectedCollectionTab = tabID
		addon:InitTables()
	end

	local tab1 = (tabID == TAB_ITEMS)
	local tab2 = (tabID == TAB_SETS)
	local tab3 = (tabID == TAB_EXTRASETS)
	local tab4 = (tabID == TAB_SAVED_SETS)

	if UI.SavedSetDropDownFrame and (tab1 or tab2 or tab3 )then 
		UI.SavedSetDropDownFrame.frame:Hide()
	else
		UI.SavedSetDropDownFrame.frame:Show()
	end

	WardrobeCollectionFrame.ItemsCollectionFrame:SetShown(tab1)
	WardrobeCollectionFrame.SetsCollectionFrame:SetShown(tab2 and not atTransmogrifier)
	WardrobeCollectionFrame.SetsTransmogFrame:SetShown(tab2 and atTransmogrifier)
	BW_WardrobeCollectionFrame.BW_SetsCollectionFrame:Hide()
	BW_WardrobeCollectionFrame.BW_SetsTransmogFrame:Hide()
	BW_WardrobeCollectionFrame.BW_SetsCollectionFrame:SetShown((tab3 or tab4) and not atTransmogrifier)
	BW_WardrobeCollectionFrame.BW_SetsTransmogFrame:SetShown((tab3 or tab4) and atTransmogrifier)

	BW_WardrobeToggle:SetShown(tab2 or tab3 or tab4 )
	BW_WardrobeToggle.VisualMode = false

	local searchBox_X = ((tab1 or ((tab2 or tab3 or tab4) and atTransmogrifier)) and -107) or 19
	local searchBox_Y = ((tab1 or ((tab2 or tab3 or tab4) and atTransmogrifier)) and -35) or -69
	local searchBox_Anchor = ((tab1 or ((tab2 or tab3 or tab4) and atTransmogrifier)) and "TOPRIGHT") or "TOPLEFT"

	WardrobeCollectionFrame.searchBox:ClearAllPoints()
	WardrobeCollectionFrame.searchBox:SetEnabled((tab1 and  WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory()) or tab2 or tab3)
	WardrobeCollectionFrame.searchBox:SetPoint(searchBox_Anchor, searchBox_X, searchBox_Y)
	WardrobeCollectionFrame.searchBox:SetWidth(((tab2 or tab3 or tab4) and not atTransmogrifier and 145) or 105)
	--WardrobeCollectionFrame.searchBox:SetShown(not tab4)

	WardrobeCollectionFrame.FilterButton:SetShown(tab1 or (tab2 and not atTransmogrifier))
	WardrobeCollectionFrame.FilterButton:SetEnabled((tab1 and  WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory()) or tab2)
	--WardrobeCollectionFrame.progressBar:SetShown(not tab4)
	BW_CollectionListButton:SetShown(tab1 and not atTransmogrifier)

	BW_WardrobeCollectionFrame.FilterButton:SetShown((tab3 or tab4 ) and not atTransmogrifier)
	BW_WardrobeCollectionFrame.FilterButton:SetEnabled(tab3)

	BW_WardrobeCollectionFrame.TransmogOptionsButton:SetShown(atTransmogrifier and (tab2 or tab3))
	BW_WardrobeCollectionFrame.TransmogOptionsButtonCover:SetShown(not addon.Profile.ShowIncomplete and atTransmogrifier and (tab2 or tab3))
	BW_WardrobeCollectionFrame.TransmogOptionsButton:SetEnabled(addon.Profile.ShowIncomplete)

--	UIDropDownMenu_EnableDropDown(BW_SortDropDown)
	BW_SortDropDown.frame:Show()
	--BW_DBSavedSetDropdown:SetShown(tab4)

	BW_SortDropDown:ClearAllPoints()

	if tab1 then
		WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.ItemsCollectionFrame
		BW_WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.ItemsCollectionFrame

		local _, isWeapon = C_TransmogCollection.GetCategoryInfo(WardrobeCollectionFrame.ItemsCollectionFrame:GetActiveCategory() or -1)
		BW_SortDropDown:SetPoint("TOPLEFT", WardrobeCollectionFrame.ItemsCollectionFrame.WeaponDropDown, "BOTTOMLEFT", 0, (atTransmogrifier and (isWeapon and 55 or 32)) or LegionWardrobeY)

	elseif tab2 then
		WardrobeCollectionFrame.SetsTransmogFrame:UpdateProgressBar()
		if atTransmogrifier  then
			WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsTransmogFrame
			BW_WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsTransmogFrame
			BW_SortDropDown:SetPoint("TOPRIGHT", WardrobeCollectionFrame.ItemsCollectionFrame, "TOPRIGHT", -137, -10)
		else
			WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsCollectionFrame
			BW_WardrobeCollectionFrame.activeFrame = WardrobeCollectionFrame.SetsCollectionFrame
			BW_SortDropDown:SetPoint("TOPLEFT", BW_WardrobeToggle, "TOPRIGHT")
		end

	elseif tab3 then
		BW_WardrobeCollectionFrame.BW_SetsTransmogFrame:UpdateProgressBar()
		if atTransmogrifier then
			WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsTransmogFrame
			BW_WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsTransmogFrame
			BW_SortDropDown:SetPoint("TOPRIGHT", WardrobeCollectionFrame.ItemsCollectionFrame, "TOPRIGHT",-137, -10)
		else
			WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsCollectionFrame
			BW_WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsCollectionFrame
			BW_SortDropDown:SetPoint("TOPLEFT", BW_WardrobeToggle, "TOPRIGHT")
		end
		
		WardrobeCollectionFrame.searchBox:Show()
	elseif tab4 then
		BW_SortDropDown.frame:Hide()
		--BW_WardrobeToggle.VisualMode = true
		local savedCount = #addon.GetSavedList()
		WardrobeCollectionFrame_UpdateProgressBar(savedCount, savedCount)
		--WardrobeCollectionFrame.searchBox:Hide()
--		UIDropDownMenu_DisableDropDown(BW_SortDropDown)
		if atTransmogrifier then
			WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsTransmogFrame
			BW_WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsTransmogFrame
			BW_SortDropDown:SetPoint("TOPRIGHT", WardrobeCollectionFrame.ItemsCollectionFrame, "TOPRIGHT",-137, -10)
		else
			WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsCollectionFrame
			BW_WardrobeCollectionFrame.activeFrame = BW_WardrobeCollectionFrame.BW_SetsCollectionFrame
			BW_SortDropDown:SetPoint("TOPLEFT", BW_WardrobeToggle, "TOPRIGHT")
		end
	end
end

