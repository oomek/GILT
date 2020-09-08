-- license:BSD-3-Clause
-- copyright-holders:Radek Dutkiewicz
local exports = {}
exports.name = "inputlag"
exports.version = "1.1.1"
exports.description = "Input Lag Test for G.I.L.T."
exports.license = "The BSD 3-Clause License"
exports.author = { name = "Radek Dutkiewicz" }

local inputlag = exports
local inputlag_folder = ''
local inputlag_settings = {
	enabled_box = false,
	enabled_bar = false,
	ratio_idx = 0,
	disp_inch = 21,
	mode_idx = 0
}

function inputlag.set_folder(path)
	inputlag_folder = path
end

function inputlag.startplugin()
	local KEY_GREEN =		"KEYCODE_0PAD"
	local KEY_BLACK =		"KEYCODE_1PAD"
	local KEY_GRAY =		"KEYCODE_2PAD"
	local KEY_WHITE =		"KEYCODE_3PAD" --temp
	local KEY_MODE_LCD =	"KEYCODE_4PAD"
	local KEY_MODE_CRT =	"KEYCODE_5PAD"
	local KEY_STROBE =		"KEYCODE_6PAD" --temp

	local COLOR_WHITE =		0xffffffff
	local COLOR_GRAY =		0xff808080
	local COLOR_BLACK =		0xff000000
	local COLOR_GREEN =		0xff64ff64
	local COLOR_TRANSP =	0x00000000

	local box_color_off = COLOR_BLACK
	local box_color = COLOR_BLACK

	local enabled_box = true
	local enabled_bar = true

	local ratio = {}
	local ratio_f = {}
	local ratio_idx = 0
	ratio[0] = "4:3"
	ratio[1] = "16:10"
	ratio[2] = "16:9"
	ratio[3] = "21:9"
	ratio_f[0] = 1.333333
	ratio_f[1] = 1.6
	ratio_f[2] = 1.777778
	ratio_f[3] = 2.333333

	local mode = {}
	local mode_idx = 0
	mode[0] = "Input Lag"
	mode[1] = "Perceived Lag"

	local scr = {}
	local inp = {}
	local tar = {}
	local con = {}
	local pressed = false
	local state = false
	local disp_inch = 27
	local disp_height = 0

	local sensor_width_mm = 50
	local sensor_height_mm = 75

	local sensor_width = 0
	local sensor_height = 0
	local sensor_y = 0

	local fix_width = 0;
	local fix_height = 0;

	local bar_x = 0
	local strobe = 0
	local blink_counter = 0
	local blink_mode = false
	local display_crt = false

	local json = require('json')

	local function save_settings()
		local file = io.open(inputlag_folder .. '/settings.cfg', 'w')
		if file then
			file:write(json.stringify(inputlag_settings, {indent = true}))
		end
		file:close()
	end

	local function load_settings()
		local file = io.open(inputlag_folder .. '/settings.cfg', 'r')
		if file then
			local settings = json.parse(file:read('a'))
			if settings then
				inputlag_settings = settings
			end
			file:close()
		end
	end

	local function draw_elements()
		if inputlag_settings.enabled_box then

			box_color = box_color_off

			if inp:code_pressed(inp:code_from_token(KEY_MODE_LCD)) then
				if blink_mode == false then
					blink_counter = scr:frame_number()
					blink_mode = true
					display_crt = false
				end
				if (scr:frame_number() - blink_counter) < 32 then
					if (scr:frame_number() - blink_counter) / 4.0 % 4.0 < inputlag_settings.mode_idx + 2 and (scr:frame_number() - blink_counter) % 4.0 < 2.0 then
						box_color = COLOR_WHITE
					else
						box_color = box_color_off
					end
				end

			elseif inp:code_pressed(inp:code_from_token(KEY_MODE_CRT)) then
				if blink_mode == false then
					blink_counter = scr:frame_number()
					blink_mode = true
					display_crt = true
				end
				if (scr:frame_number() - blink_counter) < 8 then
					if ((scr:frame_number() - blink_counter) % 4.0) <= (inputlag_settings.mode_idx) then
						box_color = COLOR_WHITE
					else
						box_color = box_color_off
					end
				end

			elseif inp:code_pressed(inp:code_from_token(KEY_BLACK)) then
				box_color_off = COLOR_BLACK
				box_color = box_color_off

			elseif inp:code_pressed(inp:code_from_token(KEY_GRAY)) then
				box_color_off = COLOR_GRAY
				box_color = box_color_off

			elseif inp:code_pressed(inp:code_from_token(KEY_GREEN)) then
				box_color_off = COLOR_GREEN
				box_color = box_color_off

			elseif inp:code_pressed(inp:code_from_token(KEY_WHITE)) then
				box_color = COLOR_WHITE

			elseif inp:code_pressed(inp:code_from_token(KEY_STROBE)) then
				if scr:frame_number() % 4 / 2 == 0 then
					box_color = COLOR_WHITE
				else
					box_color = box_color_off
				end

			elseif blink_mode == true then
				blink_mode = false
				blink_debug = 0
			end

			scr:draw_box(0, 0, sensor_width * 2, scr:height() + 10, COLOR_BLACK, 0)
			scr:draw_box(0, 0, fix_width, fix_height, COLOR_WHITE, 0)
			scr:draw_box(scr:width() - fix_width, 0, scr:width(), fix_height, COLOR_WHITE, 0)
			scr:draw_box(scr:width() - fix_width, scr:height() - fix_height, scr:width(), scr:height(), COLOR_WHITE, 0)
			scr:draw_box(0, scr:height() - fix_height, fix_width, scr:height(), COLOR_WHITE, 0)
			scr:draw_box(0, sensor_y, sensor_width, sensor_y + sensor_height, box_color, 0)
		end

		if inputlag_settings.enabled_bar then
			scr:draw_box(bar_x, 0, bar_x + scr:width() / 64, scr:height(), COLOR_GREEN, 0)
			bar_x = bar_x + 1
			if (bar_x > scr:width()) then
				bar_x = scr:width() / 2
			end
		end
	end

	local function update_box_size()
		box_color_off = COLOR_TRANSP
		disp_height = math.sqrt( inputlag_settings.disp_inch^2 / ((ratio_f[inputlag_settings.ratio_idx])^2 + 1)) * 25.4
		sensor_width = sensor_width_mm * scr:width() / disp_height / ratio_f[inputlag_settings.ratio_idx]
		sensor_height = sensor_height_mm * scr:height() / disp_height
		if inputlag_settings.mode_idx == 0 then
			sensor_y = 0
		else
			sensor_y = scr:height() / 2.0 - sensor_height * 0.08666;
		end
		fix_width = sensor_width_mm * scr:width() / disp_height / ratio_f[inputlag_settings.ratio_idx]
		fix_height = sensor_width_mm * scr:height() / disp_height
	end

	local function menu_populate()
		local menu = {}
		if inputlag_settings.enabled_box then
			menu[1] = { "Enabled", "On", "l" }
		else
			menu[1] = { "Enabled", "Off", "r" }
		end

		if inputlag_settings.mode_idx == 0 then
			menu[2] = { "Mode", mode[inputlag_settings.mode_idx], "r" }
		elseif inputlag_settings.mode_idx == 1 then
			menu[2] = { "Mode", mode[inputlag_settings.mode_idx], "l" }
		end

		if inputlag_settings.ratio_idx == 0 then
			menu[3] = { "Display Ratio", ratio[inputlag_settings.ratio_idx], "r" }
		elseif inputlag_settings.ratio_idx == 3 then
			menu[3] = { "Display Ratio", ratio[inputlag_settings.ratio_idx], "l" }
		else
			menu[3] = { "Display Ratio", ratio[inputlag_settings.ratio_idx], "lr" }
		end

		if inputlag_settings.disp_inch == 1 then
			menu[4] = { "Display Size", inputlag_settings.disp_inch .. " inch", "r" }
		elseif inputlag_settings.disp_inch == 99 then
			menu[4] = { "Display Size", inputlag_settings.disp_inch .. " inch", "l" }
		else
			menu[4] = { "Display Size", inputlag_settings.disp_inch .. " inch", "lr" }
		end

		if inputlag_settings.enabled_bar then
			menu[5] = { "Tearing test", "On", "l" }
		else
			menu[5] = { "Tearing test", "Off", "r" }
		end

		return menu
	end

	local function menu_callback(index, event)
		if index == 1 then
			if event == "left" then inputlag_settings.enabled_box = false end
			if event == "right" then inputlag_settings.enabled_box = true end
		end

		if index == 2 then
			if event == "left" then
				inputlag_settings.mode_idx = inputlag_settings.mode_idx - 1
				if inputlag_settings.mode_idx < 0 then inputlag_settings.mode_idx = 0 end
				update_box_size()
			end
			if event == "right" then
				inputlag_settings.mode_idx = inputlag_settings.mode_idx + 1
				if inputlag_settings.mode_idx > 1 then inputlag_settings.mode_idx = 1 end
				update_box_size()
			end
		end

		if index == 3 then
			if event == "left" then
				inputlag_settings.ratio_idx = inputlag_settings.ratio_idx - 1
				if inputlag_settings.ratio_idx < 0 then inputlag_settings.ratio_idx = 0 end
				update_box_size()
			end
			if event == "right" then
				inputlag_settings.ratio_idx = inputlag_settings.ratio_idx + 1
				if inputlag_settings.ratio_idx > 3 then inputlag_settings.ratio_idx = 3 end
				update_box_size()
			end
		end

		if index == 4 then
			if event == "left" then
				inputlag_settings.disp_inch = inputlag_settings.disp_inch - 1
				if inputlag_settings.disp_inch < 1 then inputlag_settings.disp_inch = 1 end
				update_box_size()
			end
			if event == "right" then
				inputlag_settings.disp_inch = inputlag_settings.disp_inch + 1
				if inputlag_settings.disp_inch > 99 then inputlag_settings.disp_inch = 99 end
				update_box_size()
			end
		end

		if index == 5 then
			if event == "left" then inputlag_settings.enabled_bar = false end
			if event == "right" then inputlag_settings.enabled_bar = true end
		end

		return true
	end

	local function start_init()
		load_settings()
		local k
		k, scr = next(manager:machine().screens)
		inp = manager:machine():input()
		tar = manager:machine():render():ui_target()
		con = manager:machine():render():ui_container()
		update_box_size()
		bar_x = scr:width() / 2
	end

	emu.register_start(start_init)
	emu.register_stop(save_settings)
	emu.register_frame_done(draw_elements)
	emu.register_menu(menu_callback, menu_populate, "Input Lag Test for G.I.L.T.")
end

return exports
