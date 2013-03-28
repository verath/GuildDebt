local L = LibStub("AceLocale-3.0"):NewLocale(
	"GuildDebt", 
	"enUS"
	--@debug@
	,true
	--@end-debug@
)

if L then

	-- Core
	L['enabled'] = true

	-- Options
	L['Version'] = true
	L['Show load message'] = true
	L['Display a message when the addon is loaded or enabled.'] = true
	L['Restore Defaults'] = true
	L['Restores ALL settings to their default values. Does not clear the database.'] = true
	L['Are you sure you want to restore ALL settings?'] = true
	L['Reset Database'] = true
	L['Resets the whole database (including settings).'] = true
	L['Are you sure you want to reset the whole database? This can not be undone!'] = true
end
