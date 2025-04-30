-- rosa/api.lua
Rosa.registered_plants = {}

-- generate unique node names per. stage
local function get_stage_node_name(base_name, stage)
    return base_name .. "_stage_" .. stage
end

-- Register nodes for each growth stage
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

-- Register nodes for each growth stage
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

local function format_description(name, def)
    if def.species and not def.genus then
        def.description = def.description ..
<<<<<<< HEAD
            "\n" .. core.colorize("#d0ffd0", "Unknown") .. "/n" .. core.colorize("#d0ffd0", def.species)
    elseif def.genus and not def.species then
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", def.genus) .. "/n" .. core.colorize("#d0ffd0", "Unknown")
    elseif not def.genus and not def.species then
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", "Unknown") .. "/n" .. core.colorize("#d0ffd0", "Unknown")
    else
        def.description = def.description ..
            "\n" .. core.colorize("#d0ffd0", def.genus) .. "/n" .. core.colorize("#d0ffd0", def.species)
=======
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
>>>>>>> 0b23def (initial)
    end
end


local function register_seeds(name, def)
    minetest.register_craftitem(name, {
        description = def.name .. " Seed",
        inventory_image = def.seed_texture or "blank.png",
        on_place = function(itemstack, placer, pointed_thing)
            local pos = pointed_thing.under
            local node = minetest.get_node(pos)

            -- Check if the node is soil?
            if minetest.get_item_group(node.name, "soil") ~= 0 then
                local above = { x = pos.x, y = pos.y + 1, z = pos.z }
                local above_node = minetest.get_node(above)

                if above_node.name == "air" then
                    minetest.set_node(above, { name = "my_mod:plant_stage_1" })
                    itemstack:take_item()
                    return itemstack
                end
            end
            return itemstack
        end
    })
end

-- Node timer callback to handle plant growth
local function grow_plant(pos, node)
    for plant_id, def in pairs(Rosa.registered_plants) do
        for stage = 1, #def.textures - 1 do
            if node.name == get_stage_node_name(plant_id, stage) then
                minetest.set_node(pos, { name = get_stage_node_name(plant_id, stage + 1) })
                minetest.get_node_timer(pos):start(def.growth_time)
                return
            end
        end
    end
end

-- Register the plant and its logic
--
-- Plant Def:
--
-- {
--
--      description: (str) A simple description
--
--      textures: (table) a list of textures to use for each growth stage, at least two must be provided.
--
--      growth_time: (num) Maximum amount of time until a growth update can occur
-- }
function Rosa.register_plant(name, def)
    assert(type(def) == "table", "Plant definition must be a table")
    assert(type(def.textures) == "table" and #def.textures > 1, "Plant must have at least 2 growth stage textures")
    assert(def.growth_time, "growth_time must be specified (in seconds)")
    assert(def.description, "description must be provided")

    Rosa.registered_plants[name] = def

    register_growth_nodes(name, def)

    -- Register planting node (stage 1 only)
    local initial_node = get_stage_node_name(name, 1)
    minetest.override_item(initial_node, {
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(def.growth_time)
        end,
        on_timer = grow_plant
    })

    -- Add timer function to later stages
    for stage = 2, #def.textures - 1 do
        local node_name = get_stage_node_name(name, stage)
        minetest.override_item(node_name, {
            on_timer = grow_plant
        })
    end
end

-- Register a plant as a simple decoration, without updating growth stages
--
-- Simple Plant Def:
-- {
--      // Basic Parameters:
--      name (str): A name for the plant (this is required for generating the seed / cutting nodes)
--      description (str): A simple description
--      genus (str): Optionally, provide a genus to add to the description
--      species (str): Optionally, provide a species to add to the description
--      texture: The main image texture
--
--      // Worldgen Parameters:
--      biomes (table): A list of biomes where it's appropriate to place this plant e.g {"default:swamp","othermod:marsh"}
--      surface_nodes (table): A list of surface nodes where it's appropriate to place the plant  e.g { "default:dirt_with_grass,default:dirt_with_snow" }
--      fill_ratio (num):
--      y_min (num): Y minimum range where the plant can spawn
--      y_max (num): Y maximum range where the plant can spawn
--      visual_scale (float): optionally refine the visual size of the plant node.
--      dye_color (str): Optionally, provide a dye color for compat
--
--      // Plant Seed Parameters:
--      seed (true/false): Default false, if set. Plant will have seeds craft items registered.
--      seed_texture: Optional, if no texture is given default fallback will be used.
--
-- }
function Rosa.register_simple_plant(name, def)
    assert(type(def) == "table", "Plant definition must be a table")
    assert(def.texture, "no texture!")
    assert(def.name, "A name needs to be given to this plant!")
    assert(def.description, "A basic description is required.")
    assert(def.biomes and type(def.biomes) == "table", "Biomes must be provided as a table.")

    Rosa.registered_plants[name] = def

    format_description(name, def)

    minetest.register_node(name, {
        description = def.description,
        drawtype = "plantlike",
        tiles = { def.texture },
        visual_scale = def.visual_scale or 1,
        inventory_image = def.texture,
        wield_image = def.texture,
        waving = 1,
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        groups = { snappy = 3, flammable = 2, flower = 1, flora = 1 },
        sounds = default.node_sound_leaves_defaults(),
        dye_color = def.dye_color or "",
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
        visual_scale = 0.2,
        place_on = def.surface_nodes or Rosa.surface_nodes[def.biomes[#def.biomes]],
        sidelen = 16,
        waving = true,
        fill_ratio = def.fill_ratio or 0.01,
        biomes = def.biomes or def.biomes[#def.biomes],
        y_min = def.y_min or 1,
        y_max = def.y_max or 31000,
        decoration = name,
        flags = "force_placement",
        dye_color = def.dye_color or "",
        inventory_overlay = function(itemstack)
            local meta = itemstack:get_meta()
            local info = meta:get_string("custom_info") or "unknown"
            return "Owner: " .. info
        end
    })

    if def.seed then
        register_seeds(name, def)
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
function Rosa.register_vine(vname, vinedef)
    local stages = vinedef.stages

    Rosa.registered_plants[vname] = def
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
