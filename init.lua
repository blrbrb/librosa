local S = core.get_translator(core.get_current_modname())

-- namespace for flower registration
Librosa = {}

Librosa.surface_nodes = {}

function tprint(tbl, indent)
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

-- Function to get all nodes in a specified group
local function get_nodes_in_group(groupname)
    local nodes_in_group = {}

    for nodename, def in pairs(minetest.registered_nodes) do
        if def.groups and def.groups[groupname] then
            table.insert(nodes_in_group, nodename)
        end
    end

    table.sort(nodes_in_group)
    return nodes_in_group
end

-- Chat command to list nodes in a group
minetest.register_chatcommand("nodesingroup", {
    params = "<groupname>",
    description = "Lists all registered nodes that are in the given group",
    privs = { server = true },
    func = function(name, param)
        local groupname = param:trim()
        if groupname == "" then
            return false, "Usage: /nodesingroup <groupname>"
        end

        local nodes = get_nodes_in_group(groupname)
        if #nodes == 0 then
            return true, "No nodes found in group '" .. groupname .. "'."
        end

        -- Truncate output if too long
        local output = table.concat(nodes, ", ")
        if #output > 60000 then -- Limit for chat message
            return true, "Too many nodes in group '" .. groupname .. "' to display."
        end

        return true, "Nodes in group '" .. groupname .. "': " .. output
    end,
})

dofile(core.get_modpath("librosa") .. "/api.lua")

-- This is so that modders can simplify the process of adding custom plant generation spreads, even if many different biome altering mods are installed.
-- The list of surface nodes collected here are used as a default fallback if nothing is provided at plant registration
--
function list_all_node_groups()
    local groups_found = {}

    for nodename, def in pairs(minetest.registered_nodes) do
        if def.groups then
            for group, _ in pairs(def.groups) do
                groups_found[group] = true
            end
        end
    end

    local group_list = {}
    for group, _ in pairs(groups_found) do
        table.insert(group_list, group)
    end

    table.sort(group_list)
    return group_list
end

function Librosa.extract_surface_nodes()
    for _, biome in pairs(core.registered_biomes) do
        --core.debug(biome.name)

        if biome and biome.node_top then
            local node_name = biome.node_top
            if node_name and core.registered_nodes[node_name] then
                if not Librosa.surface_nodes[biome.name] then
                    Librosa.surface_nodes[biome.name] = {}
                    table.insert(Librosa.surface_nodes[biome.name], node_name)
                end
                --table.insert(Librosa.surface_nodes[biome.name], node_name)
                --core.debug(tprint(Librosa.surface_nodes))
                --core.debug("action",
                -- "[librosa] Registering surface node from biome: " .. biome.name .. " " .. node_name)
            end
        end
    end
end

core.register_on_mods_loaded(function()
    -- get a list of all registered biome surface nodes.
    Librosa.extract_surface_nodes()
    -- do mapspread
    --dofile(core.get_modpath("librosa") .. "/spread.lua")
end)

core.log(tprint(list_all_node_groups()))
