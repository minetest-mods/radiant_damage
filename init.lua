radiant_damage = {} --create a container for functions and constants

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/config.lua")

-- damage_def:
--{
--	damage_name = "radiant damage", -- a string used in logs to identify the type of damage dealt
--	interval = 1, -- number of seconds between each damage check
--	range = 3, -- range of the damage. Can be omitted if inverse_square_falloff is true, in that case it defaults to the range at which 1 point of damage is done.
--	inverse_square_falloff = true, -- if true, damage falls off with the inverse square of the distance. If false, damage is constant within the range.
--	damage = 10, -- number of damage points dealt each interval (if inverse square falloff is true, this is the damage done to players 1 node away)
--	nodenames = {}, -- nodes that cause this damage. Same format as the nodenames parameter for minetest.find_nodes_in_area
--	occlusion = true, -- if true, damaging effect only passes through air. Other nodes will cast "shadows".
--	above_only = false, -- if true, damage only propagates directly upward.
--	cumulative = false, -- if true, all nodes within range do damage. If false, only the nearest one does damage.
--}

-- The reason for this function is to avoid self-occlusion. We need to test whether the *faces* of the target node have line of sight to the player,
-- not whether the *center* of the target node has line of sight to the player (it never will).
local occlusion_check

if Raycast ~= nil then

occlusion_check = function(node_pos, player_pos)
	if player_pos.x > node_pos.x then
		if Raycast({x=node_pos.x+0.51, y=node_pos.y, z=node_pos.z}, player_pos, false, true):next() == nil then return true end
	else
		if Raycast({x=node_pos.x-0.51, y=node_pos.y, z=node_pos.z}, player_pos, false, true):next() == nil then return true end
	end

	if player_pos.y > node_pos.y then
		if Raycast({y=node_pos.y+0.51, x=node_pos.x, z=node_pos.z}, player_pos, false, true):next() == nil then return true end
	else
		if Raycast({y=node_pos.y-0.51, x=node_pos.x, z=node_pos.z}, player_pos, false, true):next() == nil then return true end
	end

	if player_pos.z > node_pos.z then
		if Raycast({z=node_pos.z+0.51, x=node_pos.x, y=node_pos.y}, player_pos, false, true):next() == nil then return true end
	else
		if Raycast({z=node_pos.z-0.51, x=node_pos.x, y=node_pos.y}, player_pos, false, true):next() == nil then return true end
	end
	return false
end

else

occlusion_check = function(node_pos, player_pos)
	if player_pos.x > node_pos.x then
		if minetest.line_of_sight({x=node_pos.x+0.51, y=node_pos.y, z=node_pos.z}, player_pos) then return true end
	else
		if minetest.line_of_sight({x=node_pos.x-0.51, y=node_pos.y, z=node_pos.z}, player_pos) then return true end
	end

	if player_pos.y > node_pos.y then
		if minetest.line_of_sight({y=node_pos.y+0.51, x=node_pos.x, z=node_pos.z}, player_pos) then return true end
	else
		if minetest.line_of_sight({y=node_pos.y-0.51, x=node_pos.x, z=node_pos.z}, player_pos) then return true end
	end

	if player_pos.z > node_pos.z then
		if minetest.line_of_sight({z=node_pos.z+0.51, x=node_pos.x, y=node_pos.y}, player_pos) then return true end
	else
		if minetest.line_of_sight({z=node_pos.z-0.51, x=node_pos.x, y=node_pos.y}, player_pos) then return true end
	end
	return false
end

end


radiant_damage.register_radiant_damage = function(damage_def)
	local interval = damage_def.interval or 1
	local timer = 0
	
	local damage = damage_def.damage
	local range = damage_def.range
	local inverse_square_falloff = (damage_def.inverse_square_falloff == nil) or damage_def.inverse_square_falloff -- default to true
	if inverse_square_falloff and range == nil then
		range = math.sqrt(damage)
	end
	
	local nodenames = damage_def.nodenames
	local occlusion = (damage_def.occlusion == nil) or damage_def.occlusion -- default to true
	local above_only = damage_def.above_only -- default to false
	local cumulative = (damage_def.cumulative == nil) or damage_def.cumulative -- default to true
	
	local damage_name = damage_def.damage_name or "unnamed"
	
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer >= interval then
			timer = timer - interval
			for _, player in pairs(minetest.get_connected_players()) do
				local player_pos = player:getpos() -- node player's feet are in this location. Add 1 to y to get chest height, more intuitive that way
				player_pos.y = player_pos.y + 1

				local rounded_pos = vector.round(player_pos)
				local nearby_nodes
				if above_only then
					nearby_nodes = minetest.find_nodes_in_area(vector.add(rounded_pos, {x=0, y= -range, z=0}), rounded_pos, nodenames)
				else
					nearby_nodes = minetest.find_nodes_in_area(vector.add(rounded_pos, -range), vector.add(rounded_pos, range), nodenames)
				end
				
				local total_damage = 0
				for _, node_pos in ipairs(nearby_nodes) do
					local distance = math.max(vector.distance(player_pos, node_pos), 1) -- clamp to 1 to avoid inverse falloff causing crazy huge damage when standing inside a node
					if distance <= range and (not occlusion or occlusion_check(node_pos, player_pos)) then
						if inverse_square_falloff then
							if cumulative then
								total_damage = total_damage + damage / (distance * distance)
							else
								total_damage = math.max(total_damage, damage / (distance * distance))
							end
						else
							if cumulative then
								total_damage = total_damage + damage
							else
								total_damage = damage
								break -- non-cumulative non-falloff damage will always just be the base "damage" value, no need to continue testing.
							end
						end
					end
				end				

				if total_damage >= 1 then
					total_damage = math.floor(total_damage)
					minetest.log("action", player:get_player_name() .. " takes " .. tostring(total_damage) .. " damage from " .. damage_name .. " radiant damage.")
					player:set_hp(player:get_hp() - total_damage)
				end
			end
		end
	end)
	
end

if radiant_damage.config.enable_lava_damage then
radiant_damage.register_radiant_damage({
	damage_name = "lava",
	interval = 1,
	range = radiant_damage.config.lava_range,
	inverse_square_falloff = true,
	damage = radiant_damage.config.lava_damage,
	nodenames = {"group:lava"},
	occlusion = true,
	cumulative = true,
})
end

if radiant_damage.config.enable_fire_damage then
radiant_damage.register_radiant_damage({
	damage_name = "fire",
	interval = 1,
	range = radiant_damage.config.fire_range,
	inverse_square_falloff = true,
	damage = radiant_damage.config.fire_damage,
	nodenames = {"fire:basic_flame"},
	occlusion = true,
	cumulative = true,
})
end

if radiant_damage.config.enable_mese_damage then
radiant_damage.register_radiant_damage({
	damage_name = "mese",
	interval = radiant_damage.config.mese_interval,
	range = radiant_damage.config.mese_range,
	inverse_square_falloff = true,
	damage = radiant_damage.config.mese_damage,
	nodenames = {"default:stone_with_mese", "default:mese"},
	occlusion = radiant_damage.config.mese_occlusion,
	cumulative = true,
})
end