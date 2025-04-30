local S = minetest.get_translator(minetest.get_current_modname())

-- namespace for flower registration
Rosa = {}

Rosa.surface_nodes = {}

dofile(minetest.get_modpath("rosa") .. "/api.lua")

-- This is so that modders can simplify the process of adding custom plant generation spreads, even if many different biome altering mods are installed.
-- The list of surface nodes collected here are used as a default fallback if nothing is provided at plant registration
function Rosa.extract_surface_nodes()
    for _, biome in pairs(minetest.registered_biomes) do
        if biome and biome.node_top then
            local node_name = biome.node_top
            if node_name and minetest.registered_nodes[node_name] then
                if not Rosa.surface_nodes[biome.name] then
                    Rosa.surface_nodes[biome.name] = {}
                end
                table.insert(Rosa.surface_nodes[biome.name], node_name)
                minetest.log("action", "[Rosa] Registering surface node from biome: " .. biome.name .. " " .. node_name)
            end
        end
    end
end

-- debugging test

minetest.register_on_mods_loaded(function()
    -- get a list of all registered biome surface nodes.
    Rosa.extract_surface_nodes()
end)
