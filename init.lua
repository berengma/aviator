-- aviator, place block and fly, now also TNT resistant

aviation = {}
aviator_hud_id = {}

local getsetting = tonumber((minetest.settings:get("active_block_range")) or 1) * 32
local flength = tonumber((minetest.settings:get("aviator_flight_length")) or 30) * 60		-- how many seconds you can fly
local checktime = 1     -- check interval
local maxdistance = tonumber((minetest.settings:get("aviator_flight_radius")) or 50)			-- maxradius
local timer = 0
local trans = true																--  no permanent forceload block if server shuts down
local force = false

if minetest.get_modpath("mesecons_mvps") then										-- pull and push resistant to pistons
	mesecon.register_mvps_stopper("aviator:aviator")
end

if maxdistance > getsetting then force = true end



local function aviator_get_air_pos(pos)
	local nodes = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y, z=pos.z-1}, {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {"air"})
	if not nodes or #nodes < 1 then
		return nil
	else
		return nodes[math.random(#nodes)]
	end
end


local function aviator_update_hud(player,name,leftover,distance)				-- hud_change(id, stat, value)  `position`, `name`, `scale`, `text`, `number`, `item`, `dir`
	
	if distance > maxdistance and distance < (maxdistance+10) then
		player:hud_change(aviator_hud_id[name], 'text', ">>> Warning, you left fly area <<<")
		player:hud_change(aviator_hud_id[name], 'position' , {x=0.5, y=0.80})
		player:hud_change(aviator_hud_id[name], 'number', 0xFF0000)
		leftover = -1
	end
	
	if leftover > 10 then
		if distance < (maxdistance-10) then
			player:hud_change(aviator_hud_id[name], 'text', ">>> "..math.floor(leftover/60).." minutes left, Distance: "..distance.." <<<")
			player:hud_change(aviator_hud_id[name], 'position' , {x=0.5, y=0.80})
			player:hud_change(aviator_hud_id[name], 'number', 0xFFFF00)
		end
		if distance >= (maxdistance-10) and distance <= maxdistance then
			player:hud_change(aviator_hud_id[name], 'text', ">>> "..math.floor(leftover/60).." minutes left, Distance: "..distance.. " <<< !NEAR MAXRADIUS!")
			player:hud_change(aviator_hud_id[name], 'position' , {x=0.5, y=0.80})
			player:hud_change(aviator_hud_id[name], 'number', 0xFFA500)
		end
	end
	
	if leftover <= 10 and leftover >0 then
		player:hud_change(aviator_hud_id[name], 'text', ">>> "..leftover.." <<<")
		player:hud_change(aviator_hud_id[name], 'position' , {x=0.5, y=0.45})
		player:hud_change(aviator_hud_id[name], 'number', 0xFF0000)
	end
	
	return leftover
end


local function aviator_remove(pos, player, leave)
	local name = player:get_player_name()
			if aviation[name] ~= nil then
				local items = ItemStack("aviator:aviator 1")
				local meta = minetest.deserialize(items:get_metadata()) or {}
				local ntime = minetest.get_node_timer(aviation[name])
				local timeout = ntime:get_timeout() 
				local elapsed = ntime:get_elapsed()
				local inv = minetest.get_inventory({type="player", name=name})
				local privs = minetest.get_player_privs(name)
				meta.runtime = -1
				items:set_metadata(minetest.serialize(meta))
				
				if not inv:room_for_item("main", items) and not leave then
					minetest.chat_send_player(name, core.colorize('#ff0000', ">>> ERROR: could not take aviator, inventory full !"))
					player:set_pos(aviation[name])
					return
				end
				
				
				if vector.distance(pos, aviation[name]) == 0 then
					meta.runtime = timeout - elapsed
					items:set_metadata(minetest.serialize(meta))
					if inv:room_for_item("main", items) then
						inv:add_item("main", items)
					else
						local dpos = player:get_pos()
						minetest.spawn_item(dpos, items)
					end
					ntime:stop()
					if aviator_hud_id[name] then
						player:hud_remove(aviator_hud_id[name])
					end
					privs.fly = nil
					minetest.set_player_privs(name, privs)
					minetest.set_node(aviation[name], {name = "air"})
					aviation[name] = nil
					if force then core.forceload_free_block(pos,trans) end
					
				end
			end
	return
end



if minetest.get_modpath("technic") and minetest.get_modpath("moreores") then
	minetest.register_craft({
		output = 'aviator:aviator',
		recipe = {
			{"moreores:mithril_ingot", 'default:diamond', "moreores:mithril_ingot"},
			{'default:diamond', "technic:uranium35_ingot", 'default:diamond'},
			{"moreores:mithril_ingot", 'default:diamond', "moreores:mithril_ingot"},
		}
	})
elseif minetest.get_modpath("basic_machines") then
  
	-- do it with constructor !
	    basic_machines.craft_recipes["aviator"] = {item = "aviator:aviator", description = "let you fly "..math.floor(flength/60).."min in an area of "..maxdistance.." nodes", craft = {"default:diamondblock 16","basic_machines:power_rod 25", "default:mese 16","basic_machines:keypad"}, tex = "aviator_aviator_side"}
	    table.insert(basic_machines.craft_recipe_order,"aviator")
	    basic_machines.hardness["aviator:aviator"] = 999999
  
else
	minetest.register_craft({
		output = 'aviator:aviator',
		recipe = {
			{"default:gold_ingot", 'default:diamond', "default:gold_ingot"},
			{'default:diamond', "default:diamondblock", 'default:diamond'},
			{"default:gold_ingot", 'default:diamond', "default:gold_ingot"},
		}
	})
end



minetest.register_node("aviator:aviator", {
	description = "aviation device, fly priv for "..(flength/60).." min",
	tiles = {"aviator_aviator_top.png",
		"aviator_aviator_bottom.png",
		"aviator_aviator_side.png",
		"aviator_aviator_side.png",
		"aviator_aviator_side.png",
		"aviator_aviator_side.png"},
	is_ground_content = false,
	diggable = true,
	groups = {oddly_breakable_by_hand=3},
	liquids_pointable = true,
	light_source = 12,
	node_placement_prediction = "",			-- important to avoid double placement
	
	on_blast = function() end, -- TNT resistant

	on_place = function(itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		local meta = minetest.deserialize(itemstack:get_metadata()) or {}
		local pos = aviator_get_air_pos(pointed_thing.under)
                                           
		if not pos then return itemstack end
	
		if not aviation[name] then
			local nname = itemstack:get_name()
			local timer = minetest.get_node_timer(pos)
			local leftover = 0
                                           
			minetest.set_node(pos, {name=nname})
			itemstack:take_item()
			aviation[name]=pos
			if force then
			      if core.forceload_block(pos,trans) == false then
					      -- minetest.chat_send_all("Forceload Error")
					      end
			end
                                           
			if not meta.runtime then
				timer:start(flength)
				leftover = flength
			else
				leftover = meta.runtime
				timer:start(meta.runtime)
				meta = {}
				itemstack:set_metadata(minetest.serialize(meta))
			end
			
			aviator_hud_id[name] = placer:hud_add({
			hud_elem_type = "text";
			position = {x=0.5, y=0.80};
			text = ">>> "..math.floor(leftover/60).." minutes left <<<";number = 0xFFFF00;})
		else
			minetest.chat_send_player(name,core.colorize('#eeee00', "You placed already one Aviator at: "..aviation[name].x..","..aviation[name].y..","..aviation[name].z))
		end
	
	return itemstack
	end,

	on_dig = function(pos, node, player)
		aviator_remove(pos, player)	
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local name = digger:get_player_name()
		local ctime = minetest.get_node_timer(pos)
	
		if aviation[name] ~= nil or ctime:is_started() then
			local inv = minetest.get_inventory({type="player", name=name})
			local items = ItemStack("aviator:aviator 1")
			inv:remove_item("main", items)
			minetest.set_node(pos,oldnode)
		end
	end	
})



minetest.register_globalstep(function(dtime)
    
	timer = timer + dtime
	if timer >= checktime then
		
		local players = minetest.get_connected_players();		
		for _,player in pairs(players) do
			              
		local name = player:get_player_name()

		
		if player:is_player() then
			local checkhere = minetest.get_player_privs(name)
			if checkhere.permfly then
                            checkhere.fly = true
                            minetest.set_player_privs(name, checkhere)
			end
				
		end
		
		if aviation[name] ~= nil and aviation[name] ~= {} then
				local pos = player:get_pos()
				local ntime = minetest.get_node_timer(aviation[name])
				local timeout = ntime:get_timeout() 
				local elapsed = ntime:get_elapsed()
				local leftover = timeout - elapsed
				local distance = math.floor(vector.distance(pos, aviation[name]))
				local privs = minetest.get_player_privs(name)
				
				if timeout > 0 then
					if distance <= maxdistance then 
						privs.fly = true
						minetest.set_player_privs(name, privs)
						leftover = aviator_update_hud(player,name,leftover,distance)
					else
						
						if distance > (maxdistance+10) then
							player:hud_remove(aviator_hud_id[name])
							aviator_remove(aviation[name], player)
							leftover = -1
						end
						privs.fly = nil
						minetest.set_player_privs(name, privs)
					end
					leftover = aviator_update_hud(player,name,leftover,distance)
				else
					if aviator_hud_id[name] then
						player:hud_remove(aviator_hud_id[name])
					end
					privs.fly = nil
					minetest.set_player_privs(name, privs)
					minetest.set_node(aviation[name], {name = "air"})
					aviation[name] = nil
				end				
			end		
		end	
	timer = 0
	end
end)


-- add aviator to inventory if any
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if aviation[name] ~= nil then
		local privs = minetest.get_player_privs(name)
		privs.fly = nil
		minetest.set_player_privs(name, privs)
		aviator_remove(aviation[name], player, true)
		aviation[name] = nil
	end
end)


-- still someone with fly priv ? strange.
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local privs = minetest.get_player_privs(name)
	

	if privs.fly and (not privs.server or not privs.permfly) then
		privs.fly = nil
		minetest.set_player_privs(name, privs)
	end
end)


-- add aviator to inventory if any
minetest.register_on_shutdown(function()
	local players = minetest.get_connected_players()
	for _,player in pairs(players) do
		local name = player:get_player_name()
		if aviation[name] ~= nil then
			local privs = minetest.get_player_privs(name)
			privs.fly = nil
			minetest.set_player_privs(name, privs)
			aviator_remove(aviation[name], player, true)
			aviation[name] = nil
		end
	end
end)

-- add chatcommand to call back aviator

minetest.register_chatcommand("7", {
	params = "",
	description = "Calls your aviator back to inventory",
	privs = {interact = true},
	func = function(name, param)
                local player = minetest.get_player_by_name(name)

		if aviation[name] ~= nil then

			aviator_remove(aviation[name], player)
		
		else

			local colorstring = core.colorize('#ff0000', " >>> you did not place an aviator ")
			minetest.chat_send_player(name,colorstring)

		end
	end

			
})


minetest.register_privilege("permfly", {
	description = "permanent fly priv without aviator",
	give_to_singleplayer= false,
})
