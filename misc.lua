--
-- 		Misc functions
-- --------------------------------------------

-- addon, locale
local A, L = unpack(select(2, ...))


-- Local functions
local floor = math.floor;
local strlen, strupper, strsub = strlen, strupper, strsub


-- Capitalizes the first letter of a string
function A:capitalize(str)
	if strlen(str) < 2 then
		return strupper(str)
	else 
		return strupper(strsub(str, 1, 1)) .. strsub(str, 2);
	end
end


-- Takes an amount of copper and returns as gold, silver, copper 
-- and negative
function A:moneyFromCopper(copper)
	local negative = false
	
	if copper < 0 then
		copper = copper * (-1);
		negative = true;
	end

	local COPPER_PER_GOLD = COPPER_PER_SILVER * SILVER_PER_GOLD;

	local gold = floor(copper / COPPER_PER_GOLD);
	copper = copper - (gold * COPPER_PER_GOLD);

	local silver = floor(copper / COPPER_PER_SILVER);
	copper = copper - (silver * COPPER_PER_SILVER);

	return gold, silver, copper, negative
end