character_creator = {}
local cc = character_creator

local modpath = minetest.get_modpath("character_creator")
local datafile = minetest.get_worldpath().."/character_creator.mt"

dofile(modpath.."/skins.lua")

local function table_to_list(tbl)
	local list = ""
	for str in pairs(tbl) do
		list = list == "" and str or list..","..str
	end
	return list
end

local skin = table_to_list(cc.skin)
local face = table_to_list(cc.face)
local hair = table_to_list(cc.hair)
local hair_style = table_to_list(cc.hair_style)
local eyes = table_to_list(cc.eyes)
local tshirt = table_to_list(cc.tshirt)
local pants = table_to_list(cc.pants)
local shoes = table_to_list(cc.shoes)

local function show_formspec(name)
	minetest.show_formspec(name, "character_creator",
		"size[15,10]"..
		"button_exit[,;2,.5;;Close]"..
		"textlist[0.00,0.75;3.75,4;cc_skin;"..skin..";1;true]"..
		"textlist[3.75,0.75;3.75,4;cc_face;"..face..";1;true]"..
		"textlist[7.50,0.75;3.75,4;cc_hair;"..hair..";1;true]"..
		"textlist[11.25,0.75;3.75,4;cc_hair_style;"..hair_style..";1;true]"..
		"textlist[0.00,4.75;3.75,4;cc_eyes;"..eyes..";1;true]"..
		"textlist[3.75,4.75;3.75,4;cc_tshirt;"..tshirt..";1;true]"..
		"textlist[7.50,4.75;3.75,4;cc_pants;"..pants..";1;true]"..
		"textlist[11.25,4.75;3.75,4;cc_shoes;"..shoes..";1;true]"
	)
end

-- MEMO:skin>face>hair(hairstyle)>eyes>tshirt>pants>shoes

local playerdata = {}

local input = io.open(datafile, "r")
if input then
	playerdata = minetest.deserialize(input:read("*all")) or {}
	input:close()
end

local function change_skin(player)
	local name = player:get_player_name()
	local data = playerdata[name]
	local skin = {
		data.skin.."^"..
		data.face.."^"..
		data.eyes.."^"..
		data.hair.."^"..
		data.tshirt.."^"..
		data.pants.."^"..
		data.shoes
	}
	if minetest.get_modpath("3d_armor") then
		armor.textures[name].skin = skin
		armor:set_player_armor(player)
	else
		player:set_properties({textures = skin})
	end
end

minetest.register_chatcommand("character_creator", {
	func = function(name)
		minetest.after(.1, show_formspec, name)
	end
})

local old_param = {}

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	playerdata[name] = playerdata[name] or {
		skin = "cc_skin_fair.png",
		face = "cc_face_human_fair_M.png",
		hair = "cc_hair_medium_brown_M.png",
		eyes = "cc_eyes_brown.png",
		tshirt = "cc_tshirt_green.png",
		pants = "cc_pants_blue.png",
		shoes = "cc_shoes_leather.png",
	}
	old_param[name] = {
		skin = "Fair Skin",
		face = "Human Face (Male)",
		hair = "Brown Hair (Male)",
		hair_style = "Medium Hair",
	}
	minetest.after(0, change_skin, player)
end)

minetest.register_on_shutdown(function()
	local output = io.open(datafile, "w")
	output:write(minetest.serialize(playerdata))
	output.close()
end)

minetest.register_on_player_receive_fields(function(player, _, fields)
	local name = player:get_player_name()
	local e_skin = minetest.explode_textlist_event(fields.cc_skin)
	local e_face = minetest.explode_textlist_event(fields.cc_face)
	local e_hair = minetest.explode_textlist_event(fields.cc_hair)
	local e_hair_style = minetest.explode_textlist_event(fields.cc_hair_style)
	local e_eyes = minetest.explode_textlist_event(fields.cc_eyes)
	local e_tshirt = minetest.explode_textlist_event(fields.cc_tshirt)
	local e_pants = minetest.explode_textlist_event(fields.cc_pants)
	local e_shoes = minetest.explode_textlist_event(fields.cc_shoes)

	if e_skin.type == "CHG" then
		local face_name = face:split(",")[e_face.index] or old_param[name].face
		local skin_name = skin:split(",")[e_skin.index]
		playerdata[name].skin = cc.skin[skin_name]
		playerdata[name].face = cc.face[face_name][skin_name]
		old_param[name].skin = skin_name
	elseif e_face.type == "CHG" then
		local face_name = face:split(",")[e_face.index]
		local skin_name = skin:split(",")[e_skin.index] or old_param[name].skin
		playerdata[name].face = cc.face[face_name][skin_name]
		old_param[name].face = face_name
	elseif e_hair.type == "CHG" then
		local hair_name = hair:split(",")[e_hair.index]
		local hair_style_name = hair_style:split(",")[e_hair_style.index] or old_param[name].hair_style
		playerdata[name].hair = cc.hair[hair_name][hair_style_name]
		old_param[name].hair = hair_name
	elseif e_hair_style.type == "CHG" then
		local hair_name = hair:split(",")[e_hair.index] or old_param[name].hair
		local hair_style_name = hair_style:split(",")[e_hair_style.index]
		playerdata[name].hair = cc.hair[hair_name][hair_style_name]
		old_param[name].hair_style = hair_style_name
	elseif e_eyes.type == "CHG" then
		local eyes_name = eyes:split(",")[e_eyes.index]
		playerdata[name].eyes = cc.eyes[eyes_name]
	elseif e_tshirt.type == "CHG" then
		local tshirt_name = tshirt:split(",")[e_tshirt.index]
		playerdata[name].tshirt = cc.tshirt[tshirt_name]
	elseif e_pants.type == "CHG" then
		local pants_name = pants:split(",")[e_pants.index]
		playerdata[name].pants = cc.pants[pants_name]
	elseif e_shoes.type == "CHG" then
		local shoes_name = shoes:split(",")[e_shoes.index]
		playerdata[name].shoes = cc.shoes[shoes_name]
	end
	change_skin(player)
end)

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
