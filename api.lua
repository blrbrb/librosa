-- rosa/api.lua

-- this is needed because in order to register plants marked as pottable with flowerpot, we need to call flowerpot.register_craft() after mods have loaded.
-- so we keep track of the registered plant defs with a table attached to the global namespace
Librosa.registered_plants = {}


Librosa.tprint = function(tbl, indent)
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



-- prettify the description of the plant, so that the name of the genus and species appear neatly when hoevered over in the inventory.
local function format_description(name, def)
    if def.species and not def.genus then
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", "Unknown") .. "\n" .. core.colorize("#d0ffd0", def.species)
    elseif def.genus and not def.species then
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", def.genus) .. "\n" .. core.colorize("#d0ffd0", "Unknown")
    elseif not def.genus and not def.species then
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", "Unknown") .. "\n" .. core.colorize("#d0ffd0", "Unknown")
    else
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", def.genus) .. "\n" .. core.colorize("#d0ffd0", def.species)
    end

    -- TD: Add qualifiers for temperature, biome, progagation (seed/cutting) etc
end

local function pottable_plant(name)
    if core.global_exists("flowerpot") then
        flowerpot.register_node(name)
    else
        core.debug("(librosa)[WARN] a mod attempted to register " ..
            name .. "as pottable, but flowerpot is not installed!!")
    end
end


-- Register a plant as a simple decoration, nothing more. Nothing less.
--:
-- {
--      // Basic Parameters:
--      name (str)[required]: A name for the plant (this is required for generating the seed / cutting nodes)
--      description (str)[required]: A simple description
--      texture (str)[required]: The main image texture
--      mesh (str)[default=nil]: It's possible to create a plant with a 3d mesh. (the texture supplied will become the diffuse)
--      genus (str)[default="Unknown"]: Optionally, provide a genus to add to the description
--      species (str)[default="Unknown"]: Optionally, provide a species to add to the description
--      inventory_image (str)[default=texture]: Optionally, provide an inventory image
--
--      // Worldgen Parameters:
--      biomes (table)[required]: A list of biomes where it's appropriate to place this plant e.g {"default:swamp","othermod:marsh"}
--      surface_nodes (table)[required]: A list of surface nodes where it's appropriate to place the plant  e.g { "default:dirt_with_grass,default:dirt_with_snow" }
--      y_min (num)[default=1]: Y minimum range where the plant can spawn
--      y_max (num)[default=31000]: Y maximum range where the plant can spawn
--      visual_scale (float)[default=1.0]: optionally refine the visual size of the plant node.
--
--      // Plant Seed Parameters:
--      seed (true/false)[default=false]: If set. Plant will have seeds craft items registered.
--      seed_texture (str)[default=blank.png]: Optional, if no texture is given default fallback will be used.
--
--      // Dye Parameters
--      dye (true/false)[default=false]: Default false, if set. Plant will have a dye recipe registered.
--      dye_color (str)[required]: Specify a dye color for the plant to produce when used in the crafting grid
--      dye_craft_amount (num) [default=1]: Optional, specify how many dye items are crafted per one instance of this plant
--
--      // Misc Parameters
--      pottable (true/false)[default=false]: Optional, specify whether or not the plant should be placeable with the flowerpot mod (if installed)
--
-- }
function Librosa.register_simple_plant(name, def)
    assert(type(def) == "table", "[librosa] Plant definition must be a table")
    assert(def.texture, "[librosa] this plant has no texture!")
    assert(def.name, "[librosa] A name needs to be given to this plant!")
    assert(def.description, "[librosa] A basic description is required.")
    assert(def.biomes and type(def.biomes) == "table", "[librosa] Biomes must be provided as a table.")

    Librosa.registered_plants[name] = def


    local groups = { snappy = 3, flammable = 2, flower = 1, flora = 1 }
    local drawtype = "plantlike"
    local place_on = {}

    if def.dye then
        groups["color_" .. def.dye_color] = 1
    end

    if def.mesh then
        drawtype = "mesh"
    end

    --if surface_nodes is nil, make guesses on which surface nodes are appropriate to place the plant on based on the supplied biomes
    if not def.surface_nodes then
        if #def.biomes > 1 then
            core.debug("no biomes supplied")
            for i, biome in pairs(def.biomes) do
                core.debug(biome)
                core.debug(Librosa.surface_nodes[biome])
                table.insert(place_on, Librosa.surface_nodes[biome])
            end
        else
            table.insert(place_on, Librosa.surface_nodes[def.biomes[#def.biomes]])
        end
    else
        place_on = def.surface_nodes
    end
    core.debug("placing this plant on")
    core.debug(tprint(place_on))
    format_description(name, def)

    core.register_node(name, {
        description = def.description,
        drawtype = "plantlike",
        mesh = def.mesh or nil,
        tiles = { def.texture },
        visual_scale = def.visual_scale or 1.0,
        inventory_image = def.inventory_image or def.texture,
        wield_image = def.texture,
        waving = 1,
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        groups = groups,
        sounds = default.node_sound_leaves_defaults(),
        floodable = true,
        drop = def.drop or nil,
        selection_box = {
            type = "fixed",
            fixed = { -0.25, -0.5, -0.25, 0.25, 0.3, 0.25 },
        },
    })
    --core.debug(def.biomes[#def.biomes])
    --core.debug(Librosa.tprint(Librosa.surface_nodes))
    -- core.debug(Librosa.tprint(def.biomes))
    -- Register world decoration
    minetest.register_decoration({
        name = name .. "_decoration",
        deco_type = "simple",
        species = def.species or "",
        genus = def.genus or "",
        visual_scale = 1.0,
        place_on = place_on, --def.surface_nodes or Librosa.surface_nodes[def.biomes[#def.biomes]],
        sidelen = 16,
        waving = true,
        fill_ratio = def.fill_ratio or 0.01,
        biomes = def.biomes or def.biomes[#def.biomes],
        y_min = def.y_min or 1,
        y_max = def.y_max or 31000,
        decoration = name,
    })

    -- AFTER the node is registered, check def for pottable. Then register with flowerpot
    if def.pottable then
        pottable_plant(name)
    end
end
