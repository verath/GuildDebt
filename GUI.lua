--[[
	The frame, GuildDebt_FRAME is defined in the GuildDebt.lua file as;
	GuildDebt_FRAME = CreateFrame("Frame", "GuildDebt_FRAME", nil);
--]]

local GUILD_ROSTER_BUTTON_OFFSET = 2;
local GUILD_ROSTER_BUTTON_HEIGHT = 20;

local GuildDebt_tab;

local GuildDebt_sorted = {};
local last_sortBy = "balance";
local sort_reverse = false;
-- Function to sort by column
function GuildDebt_SortByColumn(column, keepSorting) 
	GuildDebt_sorted = {};
	if not GuildDebt[GuildDebt_getGuildName()] or not GuildDebt[GuildDebt_getGuildName()].Chars then return end
	for k,v in pairs(GuildDebt[GuildDebt_getGuildName()].Chars) do 
		table.insert(GuildDebt_sorted, {["Balance"] = v.MoneyBalance, ["Name"] = v.CharName, ["Update"] = v.LastUpdate}); 
	end
	if #GuildDebt_sorted < 1 then return; end
	
	local sortBy = last_sortBy
	if column ~= nil then sortBy = column.sortBy end
	
	if last_sortBy == sortBy and keepSorting ~= true then
		sort_reverse = not sort_reverse;
	elseif last_sortBy ~= sortBy and keepSorting ~= true then
		-- Names are sorted in reverse order compared to numbers
		if sortBy ~= "name" then sort_reverse = false;
		else sort_reverse = true; end
	end
	
	local function sortFunc(a, b, reverse, sortBy)
		if reverse then return a[sortBy] < b[sortBy]
		else return a[sortBy] > b[sortBy] end
	end
	
	if sortBy == "name" then
		table.sort(GuildDebt_sorted, function(a,b) return sortFunc(a, b, sort_reverse, "Name"); end)
	elseif sortBy == "balance" then
		table.sort(GuildDebt_sorted, function(a,b) return sortFunc(a, b, sort_reverse, "Balance"); end)
	elseif sortBy == "update" then
		table.sort(GuildDebt_sorted, function(a,b) return sortFunc(a, b, sort_reverse, "Update"); end)
	end
	
	last_sortBy = sortBy;
	GuildDebt_Update();
end

-- When a list item is clicked
local highlighted_chars = {};
local highlighted_buttons = {};
local num_highlighted  = 0;
function GuildDebt_Button_OnClick(self, mouseButton)
	if not self.charName then return end

	if mouseButton == "LeftButton" then
		if not IsShiftKeyDown() then
			for k,v in pairs(highlighted_buttons) do
				v:UnlockHighlight();
				highlighted_buttons[k] = nil;
				highlighted_chars[k] = nil;
			end
		end
		
		if not self.isHighlighted then
			self:LockHighlight();
			self.isHighlighted = true;
			highlighted_chars[self.charName] = 1;
			highlighted_buttons[self.charName] = self;
			num_highlighted = num_highlighted +1;
		else
			self:UnlockHighlight();
			self.isHighlighted = false;
			highlighted_chars[self.charName] = nil;
			highlighted_buttons[self.charName] = nil;
			num_highlighted = num_highlighted -1
		end
	end
	
	if highlighted_chars == 0 then
		GuildDebtReportGuildButton:Disable();
		GuildDebtReportPartyButton:Disable();
		GuildDebtReportSayButton:Disable();
		GuildDebtReportSelfButton:Disable();
	else
		GuildDebtReportGuildButton:Enable();
		GuildDebtReportPartyButton:Enable();
		GuildDebtReportSayButton:Enable();
		GuildDebtReportSelfButton:Enable();
	end
end

function GuildDebt_ReportButtonClicked(button)
	for k,v in pairs(highlighted_buttons) do
		GuildDebt_balanceOutput( k, button.reportType ) 
	end
end

-- The update handler for the scroll frame
function GuildDebt_Update()
	GuildDebtReportGuildButton:Disable();
	GuildDebtReportPartyButton:Disable();
	GuildDebtReportSayButton:Disable();
	GuildDebtReportSelfButton:Disable();

	local scrollFrame = GuildDebtContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index, class;
	local totalChars = #GuildDebt_sorted;

	----[[
	-- numVisible
	local visibleChars = totalChars;
	for i = 1, numButtons do
		button = buttons[i];		
		index = offset + i;

		local online = true;
		if ( GuildDebt_sorted[index] and index <= visibleChars ) then
			local name = GuildDebt_capitalize(GuildDebt_sorted[index].Name);
			local balance = GuildDebt_formatMoneyColor(GuildDebt_sorted[index].Balance);
			local update = date("%x %H:%M", GuildDebt_sorted[index].Update);

			button.charName = GuildDebt_sorted[index].Name;
			button.string1:SetText(name);
			button.string2:SetText(balance);
			button.string3:SetText(update);
			button.string1:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			
			button:Show();
			if ( mod(index, 2) == 0 ) then
				button.stripe:SetTexCoord(0.36230469, 0.38183594, 0.95898438, 0.99804688);
			else
				button.stripe:SetTexCoord(0.51660156, 0.53613281, 0.88281250, 0.92187500);
			end
				button:UnlockHighlight();
		else
			button:Hide();
		end
	end
	local totalHeight = visibleChars * (GUILD_ROSTER_BUTTON_HEIGHT + GUILD_ROSTER_BUTTON_OFFSET);
	local displayedHeight = numButtons * (GUILD_ROSTER_BUTTON_HEIGHT + GUILD_ROSTER_BUTTON_OFFSET);
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
	
	--]]
end

local first_load = true;
-- When the frame is shown, set up stuff
function GuildDebt_OnGuildShow()
	if first_load then 
		-- Set up our frame
		GuildDebt_FRAME:SetParent( GuildFrame );
		GuildDebt_FRAME:SetAllPoints();
		GuildDebt_FRAME:Hide();
		
		
		-- The column header buttons (Name, Balance, Updated at)
		local btn_name = CreateFrame( "Button", "GuildDebtColumnButton2", GuildDebt_FRAME, "GuildRosterColumnButtonTemplate" );
		btn_name:SetScript("OnClick", GuildDebt_SortByColumn);
		btn_name.sortBy = "name";
		btn_name:SetText("Name");
		btn_name:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 7, -68);
		WhoFrameColumn_SetWidth(btn_name, 101);
		
		local btn_balance = CreateFrame( "Button", "GuildDebtColumnButton1", GuildDebt_FRAME, "GuildRosterColumnButtonTemplate" );
		btn_balance:SetScript("OnClick", GuildDebt_SortByColumn);
		btn_balance.sortBy = "balance";
		btn_balance:SetText("Balance");
		btn_balance:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 7+(101-2), -68);
		WhoFrameColumn_SetWidth(btn_balance, 103);
		
		local btn_updated = CreateFrame( "Button", "GuildDebtColumnButton3", GuildDebt_FRAME, "GuildRosterColumnButtonTemplate" );
		btn_updated:SetScript("OnClick", GuildDebt_SortByColumn);
		btn_updated.sortBy = "update";
		btn_updated:SetText("Updated at");
		btn_updated:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 7+(101-2)+(103-2), -68);
		WhoFrameColumn_SetWidth(btn_updated, 103);
		
		-- The scroll frame
		local container = CreateFrame("ScrollFrame", "GuildDebtContainer", GuildDebt_FRAME, "HybridScrollFrameTemplate" );
		container:SetSize(302, 300);
		container:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", -27, -95);
		
		-- The scroller
		local scroll = CreateFrame("Slider", "$parentScrollBar", container, "HybridScrollBarTemplate" );
		scroll:SetPoint("TOPLEFT", "$parent", "TOPRIGHT", 0, -12);
		scroll:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMRIGHT", 0, 12);
		
		-- Set up the scroll frame
		container.update = GuildDebt_Update;
		HybridScrollFrame_CreateButtons(container, "GuildRosterButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, -2, "TOP", "BOTTOM");
		scroll.doNotHide = true;
		
		-- process the button strings
		local buttons = container.buttons;
		local button, fontString;
		for buttonIndex = 1, #buttons do
			button = buttons[buttonIndex];
			button:SetScript("OnClick", GuildDebt_Button_OnClick);
			button["string1"]:SetPoint("LEFT", 6, 0);
			button["string2"]:SetPoint("LEFT", 6 + 101, 0);
			button["string3"]:SetPoint("LEFT", 6 + 101 + 103, 0);
			button["string1"]:SetWidth(101-14);
			button["string2"]:SetWidth(103-14);
			button["string3"]:SetWidth(103-14);
			for i=1, 3 do
				button["string" .. i]:SetJustifyH("LEFT");
				button["string" .. i]:Show();
			end
			button.icon:Hide();
			button.barLabel:Show();
			button.header:Hide();
		end
		
		-- Set up buttons for report to guild, party and say
		local btn_reportGuild = CreateFrame( "Button", "GuildDebtReportGuildButton", GuildDebt_FRAME, "MagicButtonTemplate" );
		btn_reportGuild.reportType = "GUILD";
		btn_reportGuild:SetText("Guild");
		btn_reportGuild:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 4, 4);
		btn_reportGuild:SetScript("OnClick", GuildDebt_ReportButtonClicked);
		
		local btn_reportParty = CreateFrame( "Button", "GuildDebtReportPartyButton", GuildDebt_FRAME, "MagicButtonTemplate" );
		btn_reportParty.reportType = "PARTY";
		btn_reportParty:SetText("Party");
		btn_reportParty:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 4+2+80, 4);
		btn_reportParty:SetScript("OnClick", GuildDebt_ReportButtonClicked);
		
		local btn_reportSay = CreateFrame( "Button", "GuildDebtReportSayButton", GuildDebt_FRAME, "MagicButtonTemplate" );
		btn_reportSay.reportType = "SAY";
		btn_reportSay:SetText("Say");
		btn_reportSay:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 4+2+80+2+80, 4);
		btn_reportSay:SetScript("OnClick", GuildDebt_ReportButtonClicked);
		
		local btn_reportSelf = CreateFrame( "Button", "GuildDebtReportSelfButton", GuildDebt_FRAME, "MagicButtonTemplate" );
		btn_reportSelf.reportType = "SELF";
		btn_reportSelf:SetText("Self");
		btn_reportSelf:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 4+2+80+2+80+2+80, 4);
		btn_reportSelf:SetScript("OnClick", GuildDebt_ReportButtonClicked);
		
		-- Registering the tab means we can make use of blizz functions (see below)
		GuildFrame_RegisterPanel( GuildDebt_FRAME );
	
		-- Adjust all guild ui tabs more to the left
		GuildFrameTab1:SetPoint("BOTTOMLEFT", GuildFrame, "BOTTOMLEFT", -5, -30);
		
		-- Set up our own tab
		GuildDebt_tab = CreateFrame("Button", "GuildFrameTab6", GuildFrame, "CharacterFrameTabButtonTemplate");
		GuildDebt_tab:SetID(6);
		GuildDebt_tab:SetPoint("LEFT", "GuildFrameTab5", "RIGHT", -15, 0 );
		GuildDebt_tab:SetText("Debt");
		
		-- Set up scripts
		GuildDebt_tab:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		GuildDebt_tab:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("GuildDebt", 1.0,1.0,1.0 );
		end)
		GuildDebt_tab:SetScript("OnClick", function(self)
			GuildFrame_TabClicked(self);
			PanelTemplates_Tab_OnClick(self, GuildFrame);
			PlaySound("igCharacterInfoTab");
		end)
		GuildDebt_tab:SetScript("OnLeave", function(self) GameTooltip_Hide() end)
		
		-- Hook the tab on click function
		hooksecurefunc("GuildFrame_TabClicked", function(self)
			local tabIndex = self:GetID();
			if ( tabIndex == 6 ) then -- GuildDebt
				ButtonFrameTemplate_HideButtonBar(GuildFrame);
				GuildFrame_ShowPanel("GuildDebt_FRAME");
				GuildFrameInset:SetPoint("TOPLEFT", 4, -90);
				GuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 26);
				GuildFrameBottomInset:Hide();
				GuildXPFrame:Hide();
				GuildFactionFrame:Hide();
				GuildFrameMembersCountLabel:Hide();
				
				GuildDebt_SortByColumn(nil, true);
			end
		end);
		
		PanelTemplates_DeselectTab(GuildDebt_tab);
		PanelTemplates_SetNumTabs(GuildFrame, 6);
		first_load = false;
	end
	
	PanelTemplates_TabResize(GuildDebt_tab, 3, nil, nil, nil);
	GuildDebt_Update();
	GuildDebt_SortByColumn(nil, true);
end