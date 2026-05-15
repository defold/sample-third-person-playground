local M = {}

local function bool_axis(negative_down, positive_down)
    return (positive_down and 1 or 0) - (negative_down and 1 or 0)
end

---@class SteeringKeyboardInput
---@field forward boolean
---@field back boolean
---@field left boolean
---@field right boolean

---@param input SteeringKeyboardInput
---@return number axis_x
---@return number axis_y
function M.digital_axis(input)
    return bool_axis(input.left, input.right), bool_axis(input.back, input.forward)
end

---@param digital_x number
---@param digital_y number
---@param analog_x number
---@param analog_y number
---@param touch_x number|nil
---@param touch_y number|nil
---@return number axis_x
---@return number axis_y
function M.combine_axes(digital_x, digital_y, analog_x, analog_y, touch_x, touch_y)
    local axis_x = digital_x + analog_x + (touch_x or 0)
    local axis_y = digital_y + analog_y + (touch_y or 0)
    local length = math.sqrt(axis_x * axis_x + axis_y * axis_y)
    if length <= 1 then
        return axis_x, axis_y
    end

    local scale = 1 / length
    return axis_x * scale, axis_y * scale
end

---@param axis_x number
---@param axis_y number
---@return any|nil direction
---@return number strength
function M.axis_to_direction(axis_x, axis_y)
    local length = math.sqrt(axis_x * axis_x + axis_y * axis_y)
    if length == 0 then
        return nil, 0
    end

    local scale = 1 / length
    return vmath.vector3(axis_x * scale, axis_y * scale, 0), math.min(length, 1)
end

---@param point any
---@param angle number
---@return any
function M.rotate_2d(point, angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    local result = vmath.vector3()
    result.x = point.x * cos - point.y * sin
    result.y = point.x * sin + point.y * cos
    return result
end

---@param axis_x number
---@param axis_y number
---@param yaw number
---@return any|nil direction
---@return number strength
function M.map_fixed_direction(axis_x, axis_y, yaw)
    local direction, strength = M.axis_to_direction(axis_x, axis_y)
    if not direction then
        return nil, 0
    end

    return M.rotate_2d(direction, yaw), strength
end

---@param axis_x number
---@param axis_y number
---@return number movement
---@return number rotation
function M.player_direction_steering(axis_x, axis_y)
    return axis_y, axis_x
end

return M
