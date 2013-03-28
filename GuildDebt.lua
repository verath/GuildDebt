-- 
-- 		GuildDebt Main file
-- ---------------------------------------------

-- The "..." passed by wow is explained over at
-- http://www.wowinterface.com/forums/showthread.php?t=36308
local addonName, addonTable = ...;

local addon = LibStub("AceAddon-3.0"):NewAddon("GuildDebt", 
	"AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0");
local locale = LibStub("AceLocale-3.0"):GetLocale("GuildDebt", true);
local A, L = addon, locale;

addon.versionName = GetAddOnMetadata(addonName, "Version");
--@debug@
addon.versionName = '0.0.0-dev';
--@end-debug@
addon.addonName = addonName;

addonTable[1] = addon;
addonTable[2] = locale;

-- Make methods accessible from outside of addon.
_G[addonName] = addonTable;


-- Local functions
local strlower = strlower;


-- ###########################################
-- Global Methods
-- ###########################################

-- Returns the balance for the specifed character or nil on error
function A:getBalanceForChar(charName)
	charName = strlower(charName)
	if not GuildDebt_getGuildName() then return nil end

	if type(GuildDebt[ GuildDebt_getGuildName() ]) == "table" and type(GuildDebt[ GuildDebt_getGuildName() ]["Chars"][ charName ]) == "table" then
		return GuildDebt[ GuildDebt_getGuildName() ]["Chars"][ charName ].MoneyBalance
	else return nil end
end

-- Sets up the addon DB
function A:setupDB()
	self.db = LibStub("AceDB-3.0"):New("GuildDebtDB", A.defaults, true)
end

-- ###########################################
-- Helper Functions
-- ###########################################

-- Converts all info into a fingerprint of a transaction
local function logInfoToFingerprint( transType, name, amount )
	name = strlower(name)
	transType = strlower(transType)
	return format("%s#%s#%d", transType, name, amount)
end

-- FUNCTION updateLogEntry
-- Goes trough a log entry extracting required information
-- and updating the list if required
local function updateLogEntry( transType, name, amount, years, months, days, hours )
	if name == nil then return end;
	
	name = strlower(name)

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

	-- Loop trough each entry, 
	for i = GetNumGuildBankMoneyTransactions(), 1, -1 do
		if updateLogEntry( GetGuildBankMoneyTransaction(i) ) then 
			numUpdated = numUpdated +1
		else 
			break
		end
	end

	if numUpdated == 1 then defaultOutput( "1 new entry added.")
	else defaultOutput( numUpdated .. " new entries added.") end
end


-- ###########################################
-- Event Handling
-- ###########################################

-- Called by ace3 once saved variables are available
function A:OnInitialize()
	-- Set up the db
	self:setupDB()
end


-- Gets called during the PLAYER_LOGIN event or
-- when addon is enabled.
function A:OnEnable()
	-- Display load message
	if self.db.char.settings.loadMessage then
		A:Print(A.addonName .. " " .. L['enabled'] .. "!")
	end

	-- Start listening for slash commands
	self:RegisterChatCommand('guilddebt', "slashHandler")
	self:RegisterChatCommand('gdt', "slashHandler")

	if IsInGuild() then
		-- Start listening for events
		self:RegisterEvent('GUILDBANKLOG_UPDATE', 'OnGuildBankLogUpdate');
		self:RegisterEvent('GUILDBANKFRAME_OPENED', 'OnGuildBankFrameOpened');

		-- Get the guild name
		local guildName, rank, rankIndex = GetGuildInfo("player")
		A.guildName = guildName;
	end
end

-- Gets called if the addon is disabled
function A:OnDisable()
	-- Unregister Events
	self:UnregisterEvent('GUILDBANKLOG_UPDATE')
	self:UnregisterEvent('GUILDBANKFRAME_OPENED')

	-- Unregister slash commands
	self:UnregisterChatCommand('guilddebt')
	self:UnregisterChatCommand('gdt')

	-- Unset guild name
	A.guildName = nil
end


-- When the guild log is updated
function A:OnGuildBankLogUpdate(event, arg1, ...)
	-- Make sure we have a money log
	if GetNumGuildBankMoneyTransactions() == 0 then return end

	-- Fetch info about latest transaction 
	--[[
		NOTE about name: "A nil return indicates that this data is 
		cached or possibly invalid!"
	--]]
	
	--[[
	local transType, name, amount, years, months, days, hours

	for i = GetNumGuildBankMoneyTransactions(), 1, -1 do
		transType, name, amount, years, months, days, hours = GetGuildBankMoneyTransaction(i)
		if name ~= nil then 
			break 
		end
	end
	
	-- If we couldn't find a valid name
	if name == nil then 
		return false 
	end
	
	-- Convert it into a fingerprint
	local fingerprint = logInfoToFingerprint( transType, name, amount, years, months, days, hours )

	-- Compare it to the latest update. If we got a new one, update
	if GuildDebt[GuildDebt_getGuildName()].UpdateFingerprint ~= fingerprint then
		updateGuildDebt()
		GuildDebt[GuildDebt_getGuildName()].UpdateFingerprint = fingerprint
	end
	--]]
end

-- When the guild bank frame is opened
function A:OnGuildBankFrameOpened(...)
	-- When we open guild bank, query the server for the guild money tab
	QueryGuildBankLog(MAX_GUILDBANK_TABS+1);
end


-- ###########################################
-- Slash Commands
-- ###########################################

-- Slash handler
function A:slashHandler(input)
	if input == '' then
		--self.GUI:ShowMainFrame()
	end
end