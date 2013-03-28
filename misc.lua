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