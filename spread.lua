local function tprint(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end




local function default_spread(pos, node)
    local positions = minetest.find_nodes_in_area_under_air(
        { x = pos.x - 1, y = pos.y - 2, z = pos.z - 1 },
        { x = pos.x + 1, y = pos.y + 1, z = pos.z + 1 },
        node.place_on)

    if #positions == 0 then
        return
    end
    local pos0 = vector.subtract(pos, 6)
    local pos1 = vector.add(pos, 6)
    if #minetest.find_nodes_in_area(pos0, pos1, "group:flora") > 3 then
        return
    end

    local pos2 = positions[math.random(#positions)]
    pos2.y = pos2.y + 1
    if minetest.get_node_light(pos2, 0.5) >= 11 then
        minetest.set_node(pos2, { name = generate_flowers() })
    end
end




local function do_plant_spread()
    for i, plant in pairs(Librosa.registered_plants) do
        core.debug(tprint(plant))

        local place_on = {}

        for i, biome in pairs(plant.biomes) do
            table.insert(place_on, Librosa.surface_nodes[biome])
        end
        biome_lib.register_on_generate({
            spawn_plants = plant.name,
            sdelay = 0.2,
            spawn_chance = 300,
            surface = place_on[#place_on],
            surface_nodes = Librosa.surface_nodes[plant.biome]
        })
        --core.log(tprint(core.registered_biomes))
    end
end

do_plant_spread()
