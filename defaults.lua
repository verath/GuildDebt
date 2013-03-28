--
--	Default DB values
-- --------------------------------------------

-- addon, locale
local A, L = unpack(select(2, ...))

A.defaults = {
	-- Global Data. All characters on the same account share this database.
	global = {
		settings = { },
		guilds = {
			['*'] = {
				chars = {
					['*'] = {
						name = '',
						moneyBalance = -1,
						lastUpdate = -1
					},
				},
			},
		},
	},



	-- Character-specific data. Every character has its own database.
	char = {
		settings = {
			loadMessage = true,
		}
	},
}
