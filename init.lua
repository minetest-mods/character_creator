--[[
TODO List

Cape
Glasses(Accessories)
Face Style(Sam style, this style, MC style, etc.)
Colorize Textures(But Sokomine was against)
Skin Preview
Randomize Skin
Button Position
]]

character_creator = {}
local cc = character_creator

local modpath = minetest.get_modpath("character_creator")
local datafile = minetest.get_worldpath().."/character_creator.mt"

dofile(modpath.."/skins.lua")

local function to_numberkey_table(tbl)
	local tbl2 = {}
	for str in pairs(tbl) do
		tbl2[#tbl2+1] = str
	end
	return tbl2
end

local skins = {}
minetest.after(0, function()
	skins = {
		skin = to_numberkey_table(cc.skin),
		face = to_numberkey_table(cc.face),
		hair = to_numberkey_table(cc.hair),
		hair_style = to_numberkey_table(cc.hair_style),
		eyes = to_numberkey_table(cc.eyes),
		tshirt = to_numberkey_table(cc.tshirt),
		pants = to_numberkey_table(cc.pants),
		shoes = to_numberkey_table(cc.shoes)
	}
end)

local playerdata = {}

local function show_formspec(name)
	local data = playerdata[name]
	minetest.show_formspec(name, "character_creator",
		"size[15,9.5]"..
		"bgcolor[#00000000]"..
		-- Gender
		"button[10,;2.5,.5;cc_male;Male]"..
		"button[12.5,;2.5,.5;cc_female;Female]"..
		-- Height
		"button[10,1.1;2.5,.5;cc_taller;Taller]"..
		"button[10,2;2.5,.5;cc_shorter;Shorter]"..
		-- Width
		"button[12.5,1.1;2.5,.5;cc_wider;Wider]"..
		"button[12.5,2;2.5,.5;cc_thinner;Thinner]"..
		-- Skin
		"button[10,2.75;5,1;cc_skin;"..skins.skin[data.skin].."]"..
		"button[10,2.75;1,1;cc_skin_back;<<]"..
		"button[14,2.75;1,1;cc_skin_next;>>]"..
		-- Face
		"button[10,3.5;5,1;cc_face;"..skins.face[data.face].."]"..
		"button[10,3.5;1,1;cc_face_back;<<]"..
		"button[14,3.5;1,1;cc_face_next;>>]"..
		-- Hair
		"button[10,4.25;5,1;cc_hair;"..skins.hair[data.hair].."]"..
		"button[10,4.25;1,1;cc_hair_back;<<]"..
		"button[14,4.25;1,1;cc_hair_next;>>]"..
		-- Hair Style
		"button[10,5;5,1;cc_hair_style;"..skins.hair_style[data.hair_style].."]"..
		"button[10,5;1,1;cc_hair_style_back;<<]"..
		"button[14,5;1,1;cc_hair_style_next;>>]"..
		-- Eyes
		"button[10,5.75;5,1;cc_eyes;"..skins.eyes[data.eyes].."]"..
		"button[10,5.75;1,1;cc_eyes_back;<<]"..
		"button[14,5.75;1,1;cc_eyes_next;>>]"..
		-- T-Shirt
		"button[10,6.5;5,1;cc_tshirt;"..skins.tshirt[data.tshirt].."]"..
		"button[10,6.5;1,1;cc_tshirt_back;<<]"..
		"button[14,6.5;1,1;cc_tshirt_next;>>]"..
		-- Pants
		"button[10,7.25;5,1;cc_pants;"..skins.pants[data.pants].."]"..
		"button[10,7.25;1,1;cc_pants_back;<<]"..
		"button[14,7.25;1,1;cc_pants_next;>>]"..
		-- Shoes
		"button[10,8;5,1;cc_shoes;"..skins.shoes[data.shoes].."]"..
		"button[10,8;1,1;cc_shoes_back;<<]"..
		"button[14,8;1,1;cc_shoes_next;>>]"..
		-- Done
		"button_exit[10,9;2.5,.5;cc_done;Done]"..
		"button_exit[12.5,9;2.5,.5;cc_cancel;Cancel]"
	)
end

local input = io.open(datafile, "r")
if input then
	playerdata = minetest.deserialize(input:read("*all")) or {}
	input:close()
end

minetest.register_on_shutdown(function()
	local output = io.open(datafile, "w")
	output:write(minetest.serialize(playerdata))
	output:close()
end)

local skin_def = {
	gender = "Male",
	height = 1,
	width = 1,
	skin = 4,
	face = 4,
	hair = 8,
	hair_style = 3,
	eyes = 5,
	tshirt = 4,
	pants = 1,
	shoes = 3
}

local function change_skin(player)
	local name = player:get_player_name()
	local data = playerdata[name]

	local texture
	local flag = pcall(function()
		texture = cc.skin[skins.skin[data.skin]].."^"..
			cc.face[skins.face[data.face]][data.gender][skins.skin[data.skin]].."^"..
			cc.eyes[skins.eyes[data.eyes]].."^"..
			cc.hair[skins.hair[data.hair]][data.gender][skins.hair_style[data.hair_style]].."^"..
			cc.tshirt[skins.tshirt[data.tshirt]].."^"..
			cc.pants[skins.pants[data.pants]].."^"..
			cc.shoes[skins.shoes[data.shoes]]
	end)

	if not flag then
		playerdata[name] = table.copy(skin_def)
	end

	player:set_properties({
		visual_size = {x=data.width, y=data.height}
	})

	if minetest.get_modpath("3d_armor") then
		armor.textures[name].skin = texture
		armor:set_player_armor(player)
	else
		player:set_properties({textures={texture}})
	end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	playerdata[name] = playerdata[name] or table.copy(skin_def)

	for k, v in pairs(skin_def) do
		if (k == "gender" and type(playerdata[name][k]) ~= "string")
		or (k ~= "gender" and type(playerdata[name][k]) ~= "number") then
			playerdata[name][k] = v
		end
	end

	minetest.after(0, change_skin, player)
end)

local function switch_data(tbl, currrent_data, param)
	local data = currrent_data+param
	if tbl[data] then
		return data
	elseif data == 0 then
		return #tbl
	else
		return 1
	end
end

local skin_temp = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "character_creator" then
		return
	end

	local name = player:get_player_name()
	local data = playerdata[name]

	skin_temp[name] = skin_temp[name] or table.copy(data)

	if fields.cc_male then
		data.gender = "Male"
		data.width = 1
		data.height = 1
	elseif fields.cc_female then
		data.gender = "Female"
		data.width = 0.95
		data.height = 1
	end

	if fields.cc_taller
	and data.height < 1.25 then
		data.height = data.height+0.05
	elseif fields.cc_shorter
	and data.height > 0.75 then
		data.height = data.height-0.05
	end

	if fields.cc_wider
	and data.width < 1.25 then
		data.width = data.width+0.05
	elseif fields.cc_thinner
	and data.width > 0.75 then
		data.width = data.width-0.05
	end

	for field in pairs(fields) do
		local dataname = field:sub(4, -6)
		if field:match("_back") then
			data[dataname] = switch_data(skins[dataname], data[dataname], -1)
		elseif field:match("_next") then
			data[dataname] = switch_data(skins[dataname], data[dataname], 1)
		end
	end

	if fields.cc_done or fields.quit then
		skin_temp[name] = nil
	elseif fields.cc_cancel then
		playerdata[name] = table.copy(skin_temp[name])
		skin_temp[name] = nil
	else
		show_formspec(name)
	end

	change_skin(player)
end)

minetest.register_chatcommand("character_creator", {
	func = function(name)
		minetest.after(.1, show_formspec, name)
	end
})

if rawget(_G, "unified_inventory") then
	unified_inventory.register_button("character_creator", {
		type = "image",
		image = "inventory_plus_character_creator.png",
		action = function(player)
			show_formspec(player:get_player_name())
		end
	})
elseif rawget(_G, "inventory_plus") then
	minetest.register_on_joinplayer(function(player)
		inventory_plus.register_button(player, "character_creator", "Character Creator")
	end)
	minetest.register_on_player_receive_fields(function(player, _, fields)
		if fields.character_creator then
			show_formspec(player:get_player_name())
		end
	end)
end
