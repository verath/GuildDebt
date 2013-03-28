--
-- 		Option table setup (interface->addons)
-- --------------------------------------------

-- addon, locale
local A,L = unpack(select(2, ...))

-- Options table
A.options = {
	name = A.addonName,
	type = 'group',
	args = {
		GD_Header = {
			order = 1,
			type = "header",
			name = L["Version"] .. ": " .. A.versionName,
			width = "Full",
		},

		LoadMessage = {
			order = 2,
			type = 'toggle',
			name = L['Show load message'],
			desc = L['Display a message when the addon is loaded or enabled.'],
			get = function(info) return A.db.char.settings.loadMessage end,
			set = function(info, value) A.db.char.settings.loadMessage = value end,
		},

		RestoreDefaults = {
			order = 3,
			type = 'execute',
			name = L['Restore Defaults'],
			desc = L['Restores ALL settings to their default values. Does not clear the database.'],
			confirm = function() return L['Are you sure you want to restore ALL settings?'] end,
			func = function() A.db.char.settings = nil; A.db.global.settings = nil; A:setupDB() end,
		},

		ResetDB = {
			order = 4,
			type = 'execute',
			name = L['Reset Database'],
			desc = L['Resets the whole database (including settings).'],
			confirm = function() return L['Are you sure you want to reset the whole database? This can not be undone!'] end,
			func = function() A.db:ResetDB('Default'); A:setupDB() end,
		},
	},
}



LibStub("AceConfig-3.0"):RegisterOptionsTable(A.addonName, A.options)
LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(A.addonName, A.options)
A.ConfigFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(A.addonName, A.addonName, nil)
