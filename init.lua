-- aviator place block and fly
aviation = {}
aviator_hud_id = {}
local flength = 600     -- how many seconds you can fly
local checktime = 1     -- check interval
local maxdistance = 20  -- maxradius
local timer = 0

minetest.register_craft({
	output = 'aviator:aviator',
	recipe = {
		{"moreores:mithril_ingot", 'default:diamond', "moreores:mithril_ingot"},
		{'default:diamond', "technic:uranium35_ingot", 'default:diamond'},
		{"moreores:mithril_ingot", 'default:diamond', "moreores:mithril_ingot"},
	}
})

minetest.register_node("aviator:aviator", {
	description = "aviation device",
	tiles = {"aviator_node.png"},
	is_ground_content = false,
	diggable = false,
	groups = {cracky=3, stone=1}, --, not_in_creative_inventory=1},

	on_place = function(itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		
	
		if not aviation[name] then
			
			local timer = minetest.get_node_timer(pointed_thing.above)
			minetest.set_node(pointed_thing.above, {name="aviator:aviator"})
			itemstack:take_item()
			aviation[name]=pointed_thing.above
			timer:start(flength)
		else
			minetest.chat_send_player(name,core.colorize('#eeee00', "You placed already one Aviator at: "..aviation[name].x..","..aviation[name].y..","..aviation[name].z))
		end
	
	return itemstack
	end



})

minetest.register_globalstep(function(dtime)
    
	timer = timer + dtime
	if timer >= checktime then
	  
	local players = minetest.get_connected_players();
		
		
		for _,player in pairs(players) do
			              
			local name = player:get_player_name()
		
			if aviation[name] ~= nil then
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
						minetest.chat_send_player(name, core.colorize('#eeee00',"You left fly area ! "))
						privs.fly = nil
						minetest.set_player_privs(name, privs)
					end
					if leftover > 10 then
						aviator_hud_id[name] = player:hud_add({
						hud_elem_type = "text";
						position = {x=0.5, y=0.80};
						text = ">>> "..math.floor(leftover/60).." minutes left <<<";
						number = 0xFFFF00;})
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
		minetest.set_node(aviation[name], {name = "air"})
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

