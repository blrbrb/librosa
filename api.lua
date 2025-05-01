-- rosa/api.lua

-- this is needed because in order to register plants marked as pottable with flowerpot, we need to call flowerpot.register_craft() after mods have loaded.
-- so we keep track of the registered plant defs with a table attached to the global namespace
Librosa.registered_plants = {}

-- generate unique node names per. stage, if needed
local function get_stage_node_name(base_name, stage)
    return base_name .. "_stage_" .. stage
end

-- Register nodes for each growth stage, if needed
local function register_growth_nodes(name, def)
    for stage, texture in ipairs(def.textures) do
        local node_name = get_stage_node_name(name, stage)
        minetest.register_node(node_name, {
            description = def.description .. " (Stage " .. stage .. ")",
            drawtype = "plantlike",
            tiles = { texture },
            inventory_image = texture,
            wield_image = texture,
            paramtype = "light",
            sunlight_propagates = true,
            walkable = false,
            groups = { snappy = 3, flammable = 2, plant = 1, not_in_creative_inventory = 1 },
            drop = "", -- No drop from stages directly
            sounds = default.node_sound_leaves_defaults(),
            selection_box = {
                type = "fixed",
                fixed = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
            },
        })
    end
end

-- Register nodes for each growth stage. if needed
local function register_vine_growth_nodes(name, def)
    for stage, texture in ipairs(def.textures) do
        local node_name = get_stage_node_name(name, stage)
        minetest.register_node(node_name, {
            description = def.description,
            drawtype = "plantlike",
            waving = 1,
            tiles = { texture },
            inventory_image = texture,
            wield_image = texture,
            paramtype = "light",
            sunlight_propagates = true,
            walkable = true,
            climbable = def.climbable,
            groups = { snappy = 3, vine = 1, flammable = 2, plant = 1, not_in_creative_inventory = 1 },
            drop = "", -- No drop from stages directly
            sounds = default.node_sound_leaves_defaults(),
            selection_box = {
                type = "fixed",
                fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 },
            },
            collision_box = {
                type = "fixed",
                fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 },
            }, -- Make it attach to sides
            paramtype2 = "wallmounted",
            placement = "wallmounted",
            -- Attach to wall
            on_construct = function(pos)
                minetest.get_node_timer(pos):start(math.random(30, 90))
            end,
            on_timer = function(pos, elapsed)
                local node = minetest.get_node(pos)
                local name = node.name
                local current_stage = tonumber(name:match("_(%d+)$"))
                if current_stage and current_stage < stages then
                    minetest.set_node(pos, { name = vname .. "_" .. (current_stage + 1), param2 = node.param2 })
                    minetest.get_node_timer(pos):start(math.random(vinedef.growth_rate_min, vinedef.growth_rate_max)) -- Start timer again for next growth
                end
            end,
            after_place_node = function(pos, placer, itemstack, pointed_thing)
                -- Ensure it attaches correctly
                local under = pointed_thing.under
                local above = pointed_thing.above
                local dir = {
                    x = under.x - above.x,
                    y = under.y - above.y,
                    z = under.z - above.z,
                }
                local wallmounted = minetest.dir_to_wallmounted(dir)
                local node = minetest.get_node(pos)
                node.param2 = wallmounted
                minetest.set_node(pos, node)
            end,
        })
    end
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


local function register_pottable_plant(name)
    if core.global_exists("flowerpot") then
        flowerpot.register_node(name)
    else
        core.debug("(librosa)[WARN] a mod attempted to register " ..
            name .. "as pottable, but flowerpot is not installed!!")
    end
end

local function register_seeds(name, def)
    minetest.register_craftitem(name, {
        description = def.name .. " Seed",
        inventory_image = def.seed_texture or "seeds_aster.png"
    })
    --- if core.global_exists("farming") then
    ---  farming.register_plant(name,
    ---  {
    ---     inventory_image =
    ---  })
    ---end
end

-- Node timer callback to handle plant growth
local function grow_plant(pos, node)
    for plant_id, def in pairs(Librosa.registered_plants) do
        for stage = 1, #def.textures - 1 do
            if node.name == get_stage_node_name(plant_id, stage) then
                minetest.set_node(pos, { name = get_stage_node_name(plant_id, stage + 1) })
                minetest.get_node_timer(pos):start(def.growth_time)
                return
            end
        end
    end
end

-- Register a plant as a decoration, and automatically as a crop if any farming mods are installed
--
-- Plant Def:
--
--      // Basic Parameters:
--      name (str)[required]: A name for the plant (this is required for generating the seed / cutting nodes)
--      description (str)[required]: A simple description
--      textures (table)[required]: The main image texture, one for each stage of growth
--      inventory_image (str)[default=texture]: Optionally, provide an inventory image other than the texture specified with texture=""
--      genus (str)[default="Unknown"]: Optionally, provide a genus to add to the description
--      species (str)[default="Unknown"]: Optionally, provide a species to add to the description
--
--      // Farming/ Growth Parameters:
--      steps (int)[required]: Number of growth stages to preform until the crop/plant is mature
--      minlight (float)[default=12]: Minimal light requirements for the crop/plant to be able to grow
--      maxlight (float)[default=99]: Maximum light level for the crop/plant to be able to grow
--      can_grow (function)[default=()]: Growth determinate function to provide the default farming mod
--
--
function Librosa.register_seeding_plant(name, def)
    assert(type(def) == "table", "Plant definition must be a table")
    assert(type(def.textures) == "table" and #def.textures > 1, "Plant must have at least 2 growth stage textures")
    assert(def.growth_time, "growth_time must be specified (in seconds)")
    assert(def.description, "description must be provided")

    Librosa.registered_plants[name] = def

    if core.global_exists("farming") then
        farming.register_plant(name, {
            description = def.description,
            steps = def.steps,
            inventory_image = def.inventory_image or def.texture,
            minlight = def.minlight or 13,
            maxlight = def.maxlight or 99,
            cangrow = def.cangrow or nil
        })
    elseif core.global_exists("xfarming") then
        core.debug("(librosa)[ERR] method not implemented")
    end
    core.debug("(librosa)[WARN] Trying to register " .. name .. " as a seeding plant, but farming is not installed!!")
end

-- Register a plant as a simple decoration
--
-- Simple Plant Def:
-- {
--      // Basic Parameters:
--      name (str)[required]: A name for the plant (this is required for generating the seed / cutting nodes)
--      description (str)[required]: A simple description
--      texture (str)[required]: The main image texture
--      genus (str)[default="Unknown"]: Optionally, provide a genus to add to the description
--      species (str)[default="Unknown"]: Optionally, provide a species to add to the description
--      inventory_image (str)[default=texture]: Optionally, provide an inventory image other than the texture specified with texture=""
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
    assert(type(def) == "table", "Plant definition must be a table")
    assert(def.texture, "no texture!")
    assert(def.name, "A name needs to be given to this plant!")
    assert(def.description, "A basic description is required.")
    assert(def.biomes and type(def.biomes) == "table", "Biomes must be provided as a table.")

    Librosa.registered_plants[name] = def

    local groups = { snappy = 3, flammable = 2, flower = 1, flora = 1 }

    if def.seed == true then
        minetest.debug("registering seeds for " .. def.name)
        register_seeds(name, def)
    elseif def.dye then
        groups["color_" .. def.dye_color] = 1
    end

    format_description(name, def)

    minetest.register_node(name, {
        description = def.description,
        drawtype = "plantlike",
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
        selection_box = {
            type = "fixed",
            fixed = { -0.25, -0.5, -0.25, 0.25, 0.3, 0.25 },
        },
    })

    -- Register world decoration
    minetest.register_decoration({
        name = name .. "_decoration",
        deco_type = "simple",
        species = def.species or "",
        genus = def.genus or "",
        visual_scale = 1.0,
        place_on = def.surface_nodes or Librosa.surface_nodes[def.biomes[#def.biomes]],
        sidelen = 16,
        waving = true,
        fill_ratio = def.fill_ratio or 0.01,
        biomes = def.biomes or def.biomes[#def.biomes],
        y_min = def.y_min or 1,
        y_max = def.y_max or 31000,
        decoration = name,
        flags = "force_placement",
    })

    -- AFTER the node is registered, check def for pottable. Then register with flowerpot
    if def.pottable then
        register_pottable_plant(name)
    end
end

-- vinedef
--  (note, the textures for each stage of the vine must begin with the name of your mod
--  a hyphen (_) and then the name of the vine. The textures must also have numerical indexes
--  e.g. yourmod_morningglory_stage_1.png or yourmod_clamantis_stage_1.png)
--     {
--          name: a basic title/name (str)
--          description: A description (str)
--          stages: number of growth stages (num)
--          climbable: Should the vine be climbable (true/false)
--          growth_rate_max: A maximum amount of time in ticks before the vine can grow
--          growth_rate_min: A minimum amount of time in ticks before the vine can grow
--     }
function Librosa.register_vine(vname, vinedef)
    local stages = vinedef.stages

    Librosa.registered_plants[vname] = def
    -- Register each stage as a separate node
    for stage = 1, stages do
        minetest.register_node(vname .. "_" .. stage, {
            description = vinedef.description .. "(Stage " .. stage .. ")",
            drawtype = "plantlike",
            waving = 1,
            tiles = { vname .. "_" .. stage .. ".png" },
            inventory_image = vname .. "_" .. stage .. ".png",
            wield_image = vname .. "_" .. stage .. ".png",
            paramtype = "light",
            sunlight_propagates = true,
            walkable = false,
            climbable = vinedef.climbable,
            groups = { snappy = 3, vine = 1, not_in_creative_inventory = 1, attached_node = 1 },
            drop = vname .. "_" .. stages, -- fully grown vine drops itself
            selection_box = {
                type = "fixed",
                fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 },
            },
            collision_box = {
                type = "fixed",
                fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 },
            },

            -- Make it attach to sides
            paramtype2 = "wallmounted",
            placement = "wallmounted",
            -- Attach to wall
            on_construct = function(pos)
                minetest.get_node_timer(pos):start(math.random(30, 90))
            end,
            on_timer = function(pos, elapsed)
                local node = minetest.get_node(pos)
                local name = node.name
                local current_stage = tonumber(name:match("_(%d+)$"))
                if current_stage and current_stage < stages then
                    minetest.set_node(pos, { name = vname .. "_" .. (current_stage + 1), param2 = node.param2 })
                    minetest.get_node_timer(pos):start(math.random(vinedef.growth_rate_min, vinedef.growth_rate_max)) -- Start timer again for next growth
                end
            end,
            after_place_node = function(pos, placer, itemstack, pointed_thing)
                -- Ensure it attaches correctly
                local under = pointed_thing.under
                local above = pointed_thing.above
                local dir = {
                    x = under.x - above.x,
                    y = under.y - above.y,
                    z = under.z - above.z,
                }
                local wallmounted = minetest.dir_to_wallmounted(dir)
                local node = minetest.get_node(pos)
                node.param2 = wallmounted
                minetest.set_node(pos, node)
            end,
        })
    end
end
