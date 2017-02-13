-- aviator place block and fly
aviation = {}
aviator_hud_id = {}

local flength = 600     -- how many seconds you can fly
local checktime = 1     -- check interval
local maxdistance = 20  -- maxradius
local timer = 0

local function aviator_remove(pos, player)
	local name = player:get_player_name()
			if aviation[name] ~= nil then
				local items = ItemStack("aviator:aviator 1")
				local meta = minetest.deserialize(items:get_metadata()) or {}
				local ntime = minetest.get_node_timer(aviation[name])
				local timeout = ntime:get_timeout() 
				local elapsed = ntime:get_elapsed()
				local inv = minetest.get_inventory({type="player", name=name})
				local privs = minetest.get_player_privs(name)

			
				if vector.distance(pos, aviation[name]) == 0 then
					meta.runtime = timeout - elapsed
					items:set_metadata(minetest.serialize(meta))
					inv:add_item("main", items)
					ntime:stop()
					if aviator_hud_id[name] then
						player:hud_remove(aviator_hud_id[name])
					end
					privs.fly = nil
					minetest.set_player_privs(name, privs)
					minetest.set_node(aviation[name], {name = "air"})
					aviation[name] = nil
				end
			end
	return
end


minetest.register_craft({
	output = 'aviator:aviator',
	recipe = {
		{"moreores:mithril_ingot", 'default:diamond', "moreores:mithril_ingot"},
		{'default:diamond', "technic:uranium35_ingot", 'default:diamond'},
		{"moreores:mithril_ingot", 'default:diamond', "moreores:mithril_ingot"},
	}
})

minetest.register_node("aviator:aviator", {
	description = "aviation device, fly priv for 10min",
	tiles = {"aviator_aviator_top.png",
		"aviator_aviator_bottom.png",
		"aviator_aviator_side.png",
		"aviator_aviator_side.png",
		"aviator_aviator_side.png",
		"aviator_aviator_side.png"},
	is_ground_content = false,
	diggable = true,
	groups = {oddly_breakable_by_hand=3},
	light_source = 12,

	on_place = function(itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		local meta = minetest.deserialize(itemstack:get_metadata()) or {}
	
		if not aviation[name] then
			
			local timer = minetest.get_node_timer(pointed_thing.above)
			minetest.set_node(pointed_thing.above, {name="aviator:aviator"})
			itemstack:take_item()
			aviation[name]=pointed_thing.above
			if not meta.runtime then
				timer:start(flength)
			else
				timer:start(meta.runtime)
				meta = {}
				itemstack:set_metadata(minetest.serialize(meta))
			end	
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
			if aviation[name] ~= nil and aviation[name] ~= {} then
				local pos = player:getpos()
				local ntime = minetest.get_node_timer(aviation[name])
				local timeout = ntime:get_timeout() 
				local elapsed = ntime:get_elapsed()
				local leftover = timeout - elapsed
				local distance = math.floor(vector.distance(pos, aviation[name]))
				local privs = minetest.get_player_privs(name)
				if aviator_hud_id[name] then
					player:hud_remove(aviator_hud_id[name])
				end
				if timeout > 0 then
					if distance <= maxdistance then 
					privs.fly = true
					minetest.set_player_privs(name, privs)
					else
					if distance > maxdistance and distance < (maxdistance+10) then
						minetest.chat_send_player(name, core.colorize('#eeee00',"You left fly area ! "))
					end
					privs.fly = nil
					minetest.set_player_privs(name, privs)
					end
					if leftover > 10 then
						aviator_hud_id[name] = player:hud_add({
						hud_elem_type = "text";
						position = {x=0.5, y=0.80};
						text = ">>> "..math.floor(leftover/60).." minutes left, Distance: "..distance.." <<<";number = 0xFFFF00;})
					end
					if leftover <= 10 then		
						aviator_hud_id[name] = player:hud_add({
						hud_elem_type = "text";
						position = {x=0.5, y=0.45};
						text = ">>> "..leftover.." <<<";
						number = 0xFFFF00;})
					end	
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

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if aviation[name] ~= nil then
		local privs = minetest.get_player_privs(name)
		privs.fly = nil
		minetest.set_player_privs(name, privs)
		aviator_remove(aviation[name], player)
		aviation[name] = nil
	end
end)


minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local privs = minetest.get_player_privs(name)
	

	if privs.fly and not privs.server then
		privs.fly = nil
		minetest.set_player_privs(name, privs)
	end
end)


minetest.register_on_shutdown(function()
	local players = minetest.get_connected_players()
	for _,player in pairs(players) do
		local name = player:get_player_name()
		if aviation[name] ~= nil then
			local privs = minetest.get_player_privs(name)
			privs.fly = nil
			minetest.set_player_privs(name, privs)
			aviator_remove(aviation[name], player)
			aviation[name] = nil
		end
	end
end)
	

