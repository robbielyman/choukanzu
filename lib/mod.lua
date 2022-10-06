local mod = require "core/mods"

local tCONTROL  = 3
local tTAPER    = 5
local tNUMBER   = 1

local param_options = {"none"}
local watched = 0
local formation = {}
local exclude = {}

mod.hook.register("script_pre_init", "choukanzu_script_pre_init", function()
    local script_init = init
    init = function()
        for id, _ in pairs(params.lookup) do
            table.insert(exclude, id)
        end
        script_init()
        for id, _ in pairs(params.lookup) do
            local param = params:lookup_param(id)
            if param.t == tCONTROL or param.t == tTAPER then
                local flag = true
                for _, compare in pairs(exclude) do
                    if id == compare then flag = false break end
                end
                if flag then
                    table.insert(param_options, param.id)
                end
            end
        end
        params:add_separator("choukanzu", "~ choukanzu ~")
        params:add{
            type    = "control",
            id      = "choukanzu_fly",
            name    = "fly",
            action  = function(val)
                local steps = #formation
                if steps <= 1 then return end
                local prev = math.floor(util.linlin(0, 1, 1, steps, val))
                local next = math.ceil(util.linlin(0, 1, 1, steps, val))
                for i = 1, watched do
                    local id = param_options[params:get("choukanzu_bird_" .. i)]
                    if id ~= "none" and formation[prev][id] and formation[next][id] then
                        local newval = util.linlin(prev, next, formation[prev][id], formation[next][id], val)
                        params:set(id, newval)
                    end
                end
            end
        }
        params:add{
            type    = "trigger",
            id      = "choukanzu_flock",
            name    = "flock",
            action  = function()
                watched = watched + 1
                params:add{
                    type    = "option",
                    id      = "choukanzu_bird_" .. watched,
                    name    = "bird " .. watched,
                    options = param_options,
                    default = 1,
                    action  = function() formation = {} end
                }
                _menu.rebuild_params()
            end
        }
        params:add{
            type    = "trigger",
            id      = "choukanzu_watch",
            name    = "watch",
            action  = function()
                local index = #formation+1
                formation[index] = {}
                for i = 1,watched do
                    local id = param_options[params:get("choukanzu_bird_" .. i)]
                    if id ~= "none" then
                        formation[index][id] = params:get(id)
                    end
                    params:set("choukanzu_fly", 1)
                end
            end
        }
    end
end)
