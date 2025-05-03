function Librosa.generate_tree(pos, tname, tree_def)
    local height = tree_def.height + math.random(0, tdef.max_height_variation)
    local trunk_radius = tdef.trunk_radius
    local leaf_radius = tdef.leaf_radius

    -- Generate trunk
    for y = 0, height - 1 do
        for x = -trunk_radius, trunk_radius do
            for z = -trunk_radius, trunk_radius do
                if math.abs(x) + math.abs(z) <= trunk_radius then
                    core.set_node({ x = pos.x + x, y = pos.y + y, z = pos.z + z },
                        { name = tname .. "_trunk" })
                end
            end
        end
    end

    -- Generate leaves
    local leaves_height = height - 3
    for y = leaves_height, leaves_height + leaf_radius do
        for x = -leaf_radius, leaf_radius do
            for z = -leaf_radius, leaf_radius do
                if math.abs(x) + math.abs(z) <= leaf_radius then
                    core.set_node({ x = pos.x + x, y = pos.y + y, z = pos.z + z },
                        { name = tname .. "_leaves" })
                end
            end
        end
    end
end
