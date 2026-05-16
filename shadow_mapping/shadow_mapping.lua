local M = {}
local tiers = require("shadow_mapping.tiers")

local BUFFER_WIDTH = 1024
local BUFFER_HEIGHT = 1024
local BUFFER_NAME = "shadow_buffer"

local SHADOW_MATERIAL_NAME = "shadow"
local SHADOW_PREDICATE_NAME = "shadow"
local MODEL_PREDICATE_NAME = "shadow_model"
local SHADOW_SURFACE_PREDICATE_NAME = "shadow_surface"
local MODEL_PREDICATE_SKINNED_NAME = "shadow_model_skinned"

local FORWARDVEC = vmath.vector3(0, 0, -1)
local UPVEC = vmath.vector3(0, 1, 0)

local function calculate_view(position, rotation)
    local w_forward_vec = vmath.rotate(rotation, FORWARDVEC)
    local w_up_vec = vmath.rotate(rotation, UPVEC)
    local matrix = vmath.matrix4_look_at(position, position + w_forward_vec, w_up_vec)
    return matrix
end

local function create_depth_buffer(w, h)
    local color_params = {
        format = render.FORMAT_RGBA,
        width = w,
        height = h,
        min_filter = render.FILTER_NEAREST,
        mag_filter = render.FILTER_NEAREST,
        u_wrap = render.WRAP_CLAMP_TO_EDGE,
        v_wrap = render.WRAP_CLAMP_TO_EDGE
    }

    local depth_params = {
        format = render.FORMAT_DEPTH,
        width = w,
        height = h,
        min_filter = render.FILTER_NEAREST,
        mag_filter = render.FILTER_NEAREST,
        u_wrap = render.WRAP_CLAMP_TO_EDGE,
        v_wrap = render.WRAP_CLAMP_TO_EDGE
    }

    return render.render_target(BUFFER_NAME,
        {
            [render.BUFFER_COLOR_BIT] = color_params,
            [render.BUFFER_DEPTH_BIT] = depth_params
        })
end

function M.init()
    M.shadow_pred = render.predicate({ SHADOW_PREDICATE_NAME })
    M.shadow_surface_pred = render.predicate({ SHADOW_SURFACE_PREDICATE_NAME })
    M.shadow_model_pred = render.predicate({ MODEL_PREDICATE_NAME })
    M.shadow_model_skinned_pred = render.predicate({ MODEL_PREDICATE_SKINNED_NAME })

    M.light_buffer = create_depth_buffer(BUFFER_WIDTH, BUFFER_HEIGHT)
    M.light_transform = vmath.matrix4()
    M.light_projection = vmath.matrix4()
    M.light_constant_buffer = render.constant_buffer()
    M.light_position = vmath.vector4()
    M.shadow_target_options = { transient = { render.BUFFER_DEPTH_BIT } }
    M.shadow_clear_buffers = {
        [render.BUFFER_COLOR_BIT] = vmath.vector4(0, 0, 0, 1),
        [render.BUFFER_DEPTH_BIT] = 1
    }
    M.shadow_draw_options = { constants = M.light_constant_buffer }

    M.bias_matrix = vmath.matrix4()
    M.bias_matrix.c0 = vmath.vector4(0.5, 0.0, 0.0, 0.0)
    M.bias_matrix.c1 = vmath.vector4(0.0, 0.5, 0.0, 0.0)
    M.bias_matrix.c2 = vmath.vector4(0.0, 0.0, 0.5, 0.0)
    M.bias_matrix.c3 = vmath.vector4(0.5, 0.5, 0.5, 1.0)
end

function M.set_light_transform(light_transform)
    M.light_transform = vmath.matrix4(light_transform)
end

function M.set_light_projection(projection)
    M.light_projection = vmath.matrix4(projection)
end

---@param position vector3
---@param rotation quat quaternion
function M.calculate_light_transform(position, rotation)
    local view = calculate_view(position, rotation)
    M.light_transform = view
end

local render_shadow_counter = 0

function M.render_shadow()
    if tiers.is_shadows_ignored() then
        return
    end

    if not tiers.is_top_tier() then
        -- redraw shadows every second frame
        render_shadow_counter = render_shadow_counter + 1
        if render_shadow_counter == 2 then
            render_shadow_counter = 0
            return
        end
    end

    local w = render.get_render_target_width(M.light_buffer, render.BUFFER_DEPTH_BIT)
    local h = render.get_render_target_height(M.light_buffer, render.BUFFER_DEPTH_BIT)

    render.set_projection(M.light_projection)
    render.set_view(M.light_transform)
    render.set_viewport(0, 0, w, h)

    render.set_depth_mask(true)
    render.set_depth_func(render.COMPARE_FUNC_LEQUAL)
    render.enable_state(render.STATE_DEPTH_TEST)
    render.disable_state(render.STATE_BLEND)
    render.disable_state(render.STATE_CULL_FACE)

    -- This is something I would like to do to fix the "peter panning" issue,
    -- but it doesn't really work. Need to flip the normal on the plane I guess.
    -- render.set_cull_face(render.FACE_FRONT)
    -- render.enable_state(render.STATE_CULL_FACE)

    render.set_render_target(M.light_buffer, M.shadow_target_options)
    render.clear(M.shadow_clear_buffers)
    render.enable_material(tiers.get_tier_for_material(SHADOW_MATERIAL_NAME))
    render.draw(M.shadow_surface_pred)
    render.draw(M.shadow_model_pred)
    render.draw(M.shadow_model_skinned_pred)

    render.disable_material()
    render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

function M.prerender()
    render.set_color_mask(true, true, true, true)
    render.set_depth_func(render.COMPARE_FUNC_LEQUAL)
end

function M.render_shadow_model(view, proj, frustum)
    local mtx_light = M.bias_matrix * M.light_projection * M.light_transform
    local inv_light = vmath.inv(M.light_transform)
    local light = M.light_position

    light.x = inv_light.m03
    light.y = inv_light.m13
    light.z = inv_light.m23
    light.w = 1

    M.light_constant_buffer.mtx_light = mtx_light
    M.light_constant_buffer.light = light

    render.set_projection(proj)
    render.enable_state(render.STATE_DEPTH_TEST)
    render.disable_state(render.STATE_STENCIL_TEST)
    render.disable_state(render.STATE_CULL_FACE)
    render.set_cull_face(render.FACE_BACK)

    render.set_view(view)
    render.set_depth_mask(true)
    if not tiers.is_shadows_ignored() then
        render.enable_texture(1, M.light_buffer, render.BUFFER_COLOR_BIT)
    end
    local shadow_options = M.shadow_draw_options
    shadow_options.frustum = frustum

    -- The shadow receiver is transparent and must stay before opaque models so it does not darken actors.
    render.enable_state(render.STATE_BLEND)
    render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
    render.draw(M.shadow_surface_pred, shadow_options)

    -- Current model textures are fully opaque; disabling blend avoids unnecessary blend work.
    render.disable_state(render.STATE_BLEND)
    render.draw(M.shadow_model_pred, shadow_options)
    if not tiers.is_mid_tier() then
        render.draw(M.shadow_model_skinned_pred, shadow_options)
    end
    if not tiers.is_shadows_ignored() then
        render.disable_texture(1)
    end
    if tiers.is_mid_tier() then
        render.draw(M.shadow_model_skinned_pred, shadow_options)
    end
end

return M
