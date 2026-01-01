-- Matter Capture Tool


local USES = 331
local WEAR_PER_USE = math.floor(65535 / USES)

minetest.register_tool("matter_capture_tool:tool", {
    description = "Matter Capture Tool",
    inventory_image = "f_cannon.png",
    wield_image = "f_cannon_wield.png",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if not user then return itemstack end

        local player_name = user:get_player_name()
        local creative = player_name and minetest.is_creative_enabled(player_name)
        local pos = nil

        if pointed_thing.type == "node" then
            local under = pointed_thing.under
            local above = pointed_thing.above

            local under_node = minetest.get_node(under)
            local under_def = minetest.registered_nodes[under_node.name]

            if under_def then
                pos = under
            end

            if under_def and under_def.liquidtype == "source" then
                pos = under
            elseif above then
                local above_node = minetest.get_node(above)
                local above_def = minetest.registered_nodes[above_node.name]
                if above_def and above_def.liquidtype == "source" then
                    pos = above
                end
            end
        end

        if not pos then
            return itemstack
        end

        local node = minetest.get_node(pos)
        local nodedef = minetest.registered_nodes[node.name]

        if not nodedef or node.name == "air" then
            return itemstack
        end

        if nodedef.groups and nodedef.groups.unbreakable then
            return itemstack
        end

        if player_name and minetest.is_protected(pos, player_name) then
            minetest.record_protection_violation(pos, player_name)
            return itemstack
        end

        local meta = minetest.get_meta(pos)
        local node_inv = meta:get_inventory()
        if node_inv then
            for listname, _ in pairs(node_inv:get_lists()) do
                if not node_inv:is_empty(listname) then
                    if player_name then
                        minetest.chat_send_player(
                            player_name,
                            "Cannot capture containers with stored items."
                        )
                    end
                    return itemstack
                end
            end
        end

        local player_inv = user:get_inventory()
        local stack = ItemStack(node.name)

        if not player_inv:room_for_item("main", stack) then
            if player_name then
                minetest.chat_send_player(
                    player_name,
                    "Inventory full. Cannot store captured thing."
                )
            end
            return itemstack
        end

        player_inv:add_item("main", stack)
        minetest.remove_node(pos)

        if not creative then
            local wear = itemstack:get_wear()
            local will_break = (wear + WEAR_PER_USE) >= 65535

            if will_break then
                minetest.sound_play("default_tool_breaks", {
                    pos = user:get_pos(),
                    gain = 0.7,
                })
        end

        itemstack:add_wear(WEAR_PER_USE)
        end

        minetest.sound_play("default_place_node", {
            pos = pos,
            gain = 0.4,
        })

        return itemstack
    end,
})

-- craft
minetest.register_craft({
    output = "matter_capture_tool:tool",
    recipe = {
        {"default:gold_ingot", "default:diamond", "default:mese_crystal_fragment"},
        {"default:chest_locked", "default:mese_crystal", "default:obsidian_glass"},
        {"default:steel_ingot", "default:diamond", "default:mese_crystal_fragment"},
    }
})