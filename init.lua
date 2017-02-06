-- aviator place block and fly
aviation = {}
local flength = 60      -- how many seconds you can fly
local checktime = 1     -- check intervall
local maxdistance = 20  -- maxradius
local timer = 0



minetest.register_node("aviator:aviator", {
	description = "aviation device",
	tiles = {"aviator_node.png"},
	is_ground_content = false,
	diggable = false,
	groups = {cracky=3, stone=1, not_in_creative_inventory=1},

	on_place = function(itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		
	
		if not aviation[name] then
			
			local timer = minetest.get_node_timer(pointed_thing.above)
			minetest.set_node(pointed_thing.above, {name="aviator:aviator"})
			itemstack:take_item()
			aviation[name]=pointed_thing.above
			timer:start(flength)
		else
			minetest.chat_send_player(name, "You placed already one Aviator at: "..aviation[name].x..","..aviation[name].y..","..aviation[name].z)
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
			
				if timeout > 0 then
	
					if distance <= maxdistance then 
						privs.fly = true
						minetest.set_player_privs(name, privs)
					else
						minetest.chat_send_player(name, "You left fly area ! ")
						privs.fly = nil
						minetest.set_player_privs(name, privs)
					end

					if leftover <= 10 then
						minetest.chat_send_player(name,core.colorize('#ff0000'," >>> "..leftover.." <<< ").."seconds left")
					end

					
				else

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

