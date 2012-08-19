--[[
-- STRUCTURE OF SAVED GLOBAL VAR

GuildDebt = {
	["GuildName"] = {
		["Chars"] = {
			["CharName"] = {
				-- In copper
				["MoneyBalance"] 	= 1,
				["LastUpdate"] = 0
				["CharName"] = ""
			}
		}
		["UpdateFingerprint"] = 2
	}
	["DATABASE_VERSION"] = 1;
}
--]]
local DATABASE_VERSION = "2.0";

-- ###################################################################################
-- GLOBAL VARIABLES
-- ###################################################################################
-- Since we also use this fram in the GUI.lua file, it got to be global.
GuildDebt_FRAME = CreateFrame("Frame", "GuildDebt_FRAME", nil);

-- ###################################################################################
-- LOCAL VARIABLES
-- ###################################################################################

local EVENTS = {};
local GUILD_NAME = nil;

-- Text values
local GuildDebt_PREFIX = "GuildDebt" .. ": "
local GOLD_TEXT = "g"
local GOLD_KILO_TEXT = "kg"
local SILVER_TEXT = "s"
local COPPER_TEXT = "c"
local POSITIVE_TEXT = "+"
local NEGATIVE_TEXT = "-"
-- Colored text values
local GuildDebt_PREFIX_COLOR = string.format("|cffE1E170%s|r", GuildDebt_PREFIX)
local GOLD_TEXT_COLOR = string.format('|cffffd700%s|r', GOLD_TEXT)
local GOLD_KILO_TEXT_COLOR = string.format('|cffffd700%s|r', GOLD_KILO_TEXT)
local SILVER_TEXT_COLOR = string.format('|cffc7c7cf%s|r', SILVER_TEXT)
local COPPER_TEXT_COLOR = string.format('|cffeda55f%s|r', COPPER_TEXT)
local POSITIVE_TEXT_COLOR = string.format('|cff39E01B%s|r', POSITIVE_TEXT)
local NEGATIVE_TEXT_COLOR = string.format('|cffE01B4C%s|r', NEGATIVE_TEXT)

-- Allowed chatTypes
local ALLOWED_CHAT_TYPES = {["PARTY"]="PARTY", ["P"]="PARTY", ["GUILD"]="GUILD", ["G"]="GUILD", ["SAY"]="SAY", ["S"] = "SAY"}

-- ###################################################################################
-- FUNCTIONS
-- ###################################################################################

-- FUNCTION GuildDebt_capitalize
-- Capitalizes the first letter of a string. 
function GuildDebt_capitalize(str)
	if strlen( str ) < 2 then return strupper( str ) end
	return strupper(strsub(str, 1, 1)) .. strsub(str, 2)
end


-- Function convertMoney
-- Takes copper and changes to gold, silver, copper
function convertMoney(money)
	local negative = false
	
	if money < 0 then
		negative = true
		money = money *-1
	end

	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
    local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
    local copper = mod(money, COPPER_PER_SILVER);

	return gold, silver, copper, negative
end

-- Function GuildDebt_formatMoneyColor
-- Formats copper, silver and gold using colors
function GuildDebt_formatMoneyColor(money)
	gold, silver, copper, negative = convertMoney(money)
    local goldStr = ""
    local silverStr = ""
    local copperStr = copper .. COPPER_TEXT_COLOR
	
		if silver > 0 or gold > 0 then 
		silverStr = silver .. SILVER_TEXT_COLOR .. " " 
	end
	
    if gold > 1000 then 
		goldStr = ceil(gold/10)/100 .. GOLD_KILO_TEXT_COLOR .. " ";
		copperStr = "";
		silverStr = "";
    elseif gold > 0 then 
		goldStr = gold .. GOLD_TEXT_COLOR .. " "; 
	end

    if negative then
    	return format("%s%s%s%s", NEGATIVE_TEXT_COLOR, goldStr, silverStr, copperStr)
	else
		return format("%s%s%s%s", POSITIVE_TEXT_COLOR, goldStr, silverStr, copperStr)
	end
end

-- Function GuildDebt_formatMoney
-- Formats copper, silver and gold without colors
function GuildDebt_formatMoney(money)
	gold, silver, copper, negative = convertMoney(money)
    local goldStr = ""
    local silverStr = ""
    local copperStr = copper .. COPPER_TEXT

	if silver > 0 or gold > 0 then 
		silverStr = silver .. SILVER_TEXT .. " " 
	end
	
    if gold > 1000 then 
		goldStr = ceil(gold/10)/100 .. GOLD_KILO_TEXT .. " ";
		copperStr = "";
		silverStr = "";
    elseif gold > 0 then 
		goldStr = gold .. GOLD_TEXT .. " "; 
	end

    if negative then
    	return format("%s%s%s%s", NEGATIVE_TEXT, goldStr, silverStr, copperStr)
	else
		return format("%s%s%s%s", POSITIVE_TEXT, goldStr, silverStr, copperStr)
	end
end

-- FUNCTION GuildDebt_getGuildName
-- returns the guild name of the player or false
-- if players isn't in a guild or we cant get it
function GuildDebt_getGuildName()
	if GUILD_NAME ~= nil then return GUILD_NAME end
	if IsInGuild() == nil then return false end
	
	local guildName = nil

	-- The GetGuildInfo seems to return nil sometimes even
	-- when in a guild. This loop should fix the problem FOR NOW.
	for i=0, 100, 1 do 
		guildName = GetGuildInfo("player")
		if guildName ~= nil then break end
	end

	if guildName == nil then return false end

	GUILD_NAME = gsub(guildName, "%A", "_")
	return GUILD_NAME
end


-- FUNCTION errorOutput
-- Prints an error to the user
local function errorOutput(err)
	local errorTable = {
		["noGuild"] = "You are not in a guild or your guild name was not found.",
		["notChatType"] = "The chat type provided was invalid."
	}

	if type(errorTable[err]) == "string" then
		DEFAULT_CHAT_FRAME:AddMessage("GuildDebt Error: " .. errorTable[err], 1.0, 0.0, 0.0 );
	else
		DEFAULT_CHAT_FRAME:AddMessage( "GuildDebt Error: An unexpected error occured.", 1.0, 0.0, 0.0 );
	end
end

-- Function chatOutput
-- Prints a message to a chat type
-- prefixed by GuildDebt: 
local function chatOutput(msg, chatType)
	chatType = strupper(chatType)
	if not ALLOWED_CHAT_TYPES[chatType] then return errorOutput("notChatType") end
	chatType = ALLOWED_CHAT_TYPES[chatType]
	if ( chatType == "GUILD" and not GuildDebt_getGuildName() ) or (chatType == "PARTY" and GetNumPartyMembers() < 1) then return end
	SendChatMessage(msg, chatType)
end


-- Function defaultOutput
-- Prints a message in the default color and 
-- prefixed by GuildDebt:
local function defaultOutput(str)
	DEFAULT_CHAT_FRAME:AddMessage( GuildDebt_PREFIX_COLOR .. str );
end

-- FUNCTION convertLogInfoToFingerprint
-- Converts all info into a fingerprint of a transaction
local function logInfoToFingerprint( transType, name, amount )
	name = strlower(name)
	transType = strlower(transType)
	return format("%s#%s#%d", transType, name, amount)
end

-- FUNCTION setupGuild
-- Checks the list for the specified guild name
-- if not exist, crete it
local function setupGuild( guildName )
	if type(GuildDebt[guildName]) == "table" then return end
	GuildDebt[ guildName ] = { ["UpdateFingerprint"] = 0, ["Chars"] = {}}
end

-- FUNCTION gotInfoAboutPlayer
-- Checks the list for the specified player name in guild
-- if not exist, create it
local function setupChar( guildName, charName )
	charName = strlower(charName)
	setupGuild( guildName )
	if type(GuildDebt[ guildName ]["Chars"][ charName ]) == "table" then return end
	GuildDebt[ guildName ]["Chars"][ charName ] = { ["MoneyBalance"] = 0, ["LastUpdate"] = 0, ["CharName"] = charName}
end

-- FUNCTION getBalanceForPlayer
-- Returns the balance for the specifed player or nil on error
local function getBalanceForChar(charName)
	charName = strlower(charName)
	if not GuildDebt_getGuildName() then return nil end

	if type(GuildDebt[ GuildDebt_getGuildName() ]) == "table" and type(GuildDebt[ GuildDebt_getGuildName() ]["Chars"][ charName ]) == "table" then
		return GuildDebt[ GuildDebt_getGuildName() ]["Chars"][ charName ].MoneyBalance
	else return nil end
end

-- Function GuildDebt_balanceOutput
-- Formats and prints balance information for
-- a character
function GuildDebt_balanceOutput( target, chatType ) 
	local balance = getBalanceForChar(target)
	if balance == nil then
		defaultOutput( format("No information available about %s's balance.", GuildDebt_capitalize(target)) )
	else
		if chatType == nil or strupper(chatType) == "SELF" then
			defaultOutput( format("%s's balance is %s", GuildDebt_capitalize(target), GuildDebt_formatMoneyColor(balance)) )
		else
			chatOutput( format("%s's balance is %s", GuildDebt_capitalize(target), GuildDebt_formatMoney(balance)), chatType )
		end
	end
end

-- FUNCTION updateLogEntry
-- Goes trough a log entry extracting required information
-- and updating the list if required
local function updateLogEntry( transType, name, amount, years, months, days, hours )
	if name == nil then return end;
	name = strlower(name)
	-- If we dont have an entry for the char in our var, create it
	setupChar( GuildDebt_getGuildName(), name )

	-- Get the fingerprint
	local fingerprint = logInfoToFingerprint( transType, name, amount )
	-- Compare it to the the one from last update. If this is the same, stop
	if GuildDebt[ GuildDebt_getGuildName() ].UpdateFingerprint == fingerprint then return false end
	
	-- Update the amount. Deposit is +, repair and whitdraw is -
	if transType ~= "deposit" then amount = amount*-1 end
	GuildDebt[ GuildDebt_getGuildName() ]["Chars"][name].MoneyBalance = GuildDebt[ GuildDebt_getGuildName() ]["Chars"][name].MoneyBalance + amount
	GuildDebt[ GuildDebt_getGuildName() ]["Chars"][name].LastUpdate = time();
	return true
end

-- FUNCTION updateGuildDebt
-- Updates the guild debt from the guild money log
local function updateGuildDebt()
	local numUpdated = 0
	-- Loop trough each entry
	for i = GetNumGuildBankMoneyTransactions(), 1, -1 do
		if not updateLogEntry( GetGuildBankMoneyTransaction(i) ) then break end
		numUpdated = numUpdated +1
	end

	if numUpdated == 1 then defaultOutput( "1 new entry added.")
	else defaultOutput( numUpdated .. " new entries added.") end
end

-- ###################################################################################
-- EVENT FUNCTIONS
-- ###################################################################################

-- When the guild log is updated
function EVENTS:GUILDBANKLOG_UPDATE(arg1, ...)
	-- Make sure we got the guild name
	if not GuildDebt_getGuildName() then return end
	
	-- And that the guild is set up
	setupGuild( GuildDebt_getGuildName() )

	-- Make sure we have a money log
	if GetNumGuildBankMoneyTransactions() == 0 then return end

	-- Fetch info about latest transaction
	local transType, name, amount, years, months, days, hours;
	for i = GetNumGuildBankMoneyTransactions(), 1, -1 do
		transType, name, amount, years, months, days, hours = GetGuildBankMoneyTransaction(i)
		if name ~= nil then break; end
	end
	
	if name == nil then return false; end
	
	-- Convert it into a fingerprint
	local fingerprint = logInfoToFingerprint( transType, name, amount, years, months, days, hours )

	-- Compare it to the latest update. If we got a new one, update
	if GuildDebt[GuildDebt_getGuildName()].UpdateFingerprint ~= fingerprint then
		updateGuildDebt()
		GuildDebt[GuildDebt_getGuildName()].UpdateFingerprint = fingerprint
	end
	
end

function EVENTS:GUILDBANKFRAME_OPENED(...)
	-- When we open guild bank, update the guild money tab
	QueryGuildBankLog(MAX_GUILDBANK_TABS+1);
end

function EVENTS:ADDON_LOADED(addon_name)
	-- If the addon being loaded is the blizzard guild ui, hook our function
	if addon_name == "Blizzard_GuildUI" and GuildDebt["NoGUI"] ~= true then
		GuildFrame:HookScript("OnShow", function(self)
			GuildDebt_OnGuildShow();
		end)
	end
	
	-- This is fired for each addon loaded... we only want to listen for when ours is loaded
	if addon_name ~= "GuildDebt" then return end

	if not GuildDebt or GuildDebt.DATABASE_VERSION ~= DATABASE_VERSION then
		GuildDebt = {["DATABASE_VERSION"] = DATABASE_VERSION;}-- Set up default value for GuildDebt variable
	end
	
	-- Load the guild name of the player
	if GuildDebt_getGuildName() then
		-- If we dont have an entry for the guild in our var, create it
		setupGuild( GuildDebt_getGuildName() )
	end
	
end


-- Event handling stuff from http://www.wowwiki.com/Handling_events
GuildDebt_FRAME:SetScript("OnEvent",
	function(self, event, ...)
		EVENTS[event](self, ...); -- call one of the functions above
	end
);

for k, v in pairs(EVENTS) do
	GuildDebt_FRAME:RegisterEvent(k); -- Register all events for which handlers have been defined
end


-- ###################################################################################
-- ** Slash Commands **
-- ###################################################################################
SLASH_GuildDebt1, SLASH_GuildDebt2 = '/gdt', '/guilddebt';
local function slashHandler(msg, editbox)

	-- If not in a guild or can't accuire guild name. Display error
	if not GuildDebt_getGuildName() then return errorOutput("noGuild") end

	local arg1, arg2, arg3 = strsplit(" ", msg, 3)

	if msg == "" then
		-- Usage message and version number.
		defaultOutput( format("%s", GetAddOnMetadata("GuildDebt", "Version")) )
		defaultOutput( format("Usage: /gdt |cffffd700<name>|r[ |cff26FF00<chat type>|r]") );
		defaultOutput( "|cffffd700<name>|r - The name of the character." );
		defaultOutput( "|cff26FF00<chat type>|r - self, g/guild, p/party, s/say." );
		defaultOutput( "/gdt #reset - Resets the addon database." );
		defaultOutput( "/gdt #gui - Toggles the tab on the guild frame." );
		return
	end

	if arg1 == "#reset" then
		GuildDebt = {}
		setupGuild( GuildDebt_getGuildName() )
		defaultOutput("The addon has been reset.")
		return
	end
	if arg1 == "#gui" then
		if GuildDebt["NoGUI"] then
			GuildDebt["NoGUI"] = false;
			defaultOutput("The tab will be |cff00ff00shown|r on the next reload.")
		else
			GuildDebt["NoGUI"] = true;
			defaultOutput("The tab will be |cffff0000hidden|r on the next reload.")
		end
		return
	end

	target = strlower(arg1)	
	if target == "%t" then
		if UnitName("target") then target = strlower(UnitName("target")) 
		else target = "<no target>" end
	end

	if target == "%p" then
		if UnitName("player") then target = strlower(UnitName("player")) 
		else target = "<no target>" end
	end

	outputType = arg2
	if outputType ~= nil then outputType = strlower(outputType) end
	
	GuildDebt_balanceOutput( target, outputType ) 
end
SlashCmdList["GuildDebt"] = slashHandler;