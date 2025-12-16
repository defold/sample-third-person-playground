local M = {}

M.LOW = "low_material"
M.MID = "mid_material"
M.HIGH = "high_material"

M.MSG_CHANGE_TIER = hash("MSG_CHANGE_TIER")
M.MSG_DECIDE = hash("MSG_DECIDE")
M.MSG_REMOVE_FROM_TIER = hash("MSG_REMOVE_FROM_TIER")

M.PROP_MATERIAL = hash("material")

local current_tier = M.HIGH

local listeners = {}
local materials = {}

function M.change_tier(tier)
    current_tier = tier
    for _, listener in pairs(listeners) do
        if go.exists(listener) then
            msg.post(listener, M.MSG_CHANGE_TIER, { tier = tier })
        end
    end
end

function M.register()
    listeners[tostring(msg.url())] = msg.url()
end

function M.unregister()
    listeners[tostring(msg.url())] = nil
end

function M.get_tier_for_material(name)
    if not materials[name] then
        materials[name] = {}
        materials[name][M.LOW] = name .. "_" .. M.LOW
        materials[name][M.MID] = name .. "_" .. M.MID
        materials[name][M.HIGH] = name .. "_" .. M.HIGH
    end
    return materials[name][current_tier]
end

function M.is_shadows_ignored()
    return M.LOW == current_tier
end

function M.is_top_tier()
    return M.HIGH == current_tier
end

function M.is_mid_tier()
    return M.MID == current_tier
end

return M
