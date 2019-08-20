-- license:BSD-3-Clause
-- copyright-holders:Radek Dutkiewicz
local exports = {}
exports.name = "inputlag"
exports.version = "1.0.0"
exports.description = "Input Lag Test for G.I.L.T."
exports.license = "The BSD 3-Clause License"
exports.author = { name = "Radek Dutkiewicz" }

local inputlag = exports
local inputlag_folder = ''
local inputlag_settings = {
	enabled_box = false,
	enabled_bar = false,
	ratio_idx = 0,
	disp_inch = 21
}

function inputlag.set_folder(path)
	inputlag_folder = path
end

function inputlag.startplugin()
	local enabled_box = true
	local enabled_bar = true
	local ratio = {"4:3", "16:10", "16:9", "21:9"}
	local ratio_f = { 1.333333, 1.6, 1.777778, 2.333333 }
	local ratio_idx = 0
	local scr = {}
	local inp = {}
	local tar = {}
	local con = {}
	local pressed = false
	local state = false
	local registered = false
	local disp_inch = 27
	local disp_height = 0
	
	local sensor_width_mm = 50
	local sensor_height_mm = 75

	local sensor_width = 0
	local sensor_height = 0
	
	local bar_x = 0
	local blink = 0
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
			scr:draw_box(0, 0, sensor_width, sensor_height, 0xff000000, 0)
			pressed = inp:code_pressed(inp:code_from_token("KEYCODE_LEFT"))
			if pressed then
				scr:draw_box(0, 0, sensor_width, sensor_height / 4, 0xffffffff, 0)
			end
			if inp:code_pressed(inp:code_from_token("KEYCODE_RIGHT")) then
				if blink == 0 then
					scr:draw_box(0, 0, sensor_width, sensor_height / 4, 0xffffffff, 0)
				end
				blink = blink + 1
				if blink > 4 then blink = 0 end
			end
		end
		
		if inputlag_settings.enabled_bar then
			scr:draw_box(bar_x, 0, bar_x + scr:width() / 64, scr:height(), 0xff80ff80, 0)
			bar_x = bar_x + 1
			if (bar_x > scr:width()) then
				bar_x = scr:width() / 2
			end
		end
	end

	local function update_box_size()
		disp_height = math.sqrt( inputlag_settings.disp_inch^2 / ((ratio_f[inputlag_settings.ratio_idx + 1])^2 + 1)) * 25.4
		sensor_width = sensor_width_mm * scr:width() / disp_height / ratio_f[inputlag_settings.ratio_idx + 1]
		sensor_height = sensor_height_mm * scr:height() / disp_height
	end

	local function menu_populate()
		local menu = {}
		if inputlag_settings.enabled_box then
			menu[1] = { "Enabled"   , "On", "l" }
		else
			menu[1] = { "Enabled"   , "Off", "r" }
		end
		
		if inputlag_settings.enabled_bar then
			menu[2] = { "Tearing test", "On", "l" }
		else
			menu[2] = { "Tearing test", "Off", "r" }
		end

		if inputlag_settings.ratio_idx == 0 then
			menu[3] = { "Display Ratio"   , ratio[inputlag_settings.ratio_idx + 1], "r" }
		elseif inputlag_settings.ratio_idx == 3 then
			menu[3] = { "Display Ratio"   , ratio[inputlag_settings.ratio_idx + 1], "l" }
		else
			menu[3] = { "Display Ratio"   , ratio[inputlag_settings.ratio_idx + 1], "lr" }
		end

		if inputlag_settings.disp_inch == 1 then
			menu[4] = { "Display Size"   , inputlag_settings.disp_inch .. " inch", "r" }
		elseif inputlag_settings.disp_inch == 99 then
			menu[4] = { "Display Size"   , inputlag_settings.disp_inch .. " inch", "l" }
		else
			menu[4] = { "Display Size"   , inputlag_settings.disp_inch .. " inch", "lr" }
		end
		return menu
	end

	local function menu_callback(index, event)
		if index == 1 then
			if event == "left" then inputlag_settings.enabled_box = false end
			if event == "right" then inputlag_settings.enabled_box = true end
		end

		if index == 2 then
			if event == "left" then inputlag_settings.enabled_bar = false end
			if event == "right" then inputlag_settings.enabled_bar = true end
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
		return true
	end

	emu.register_start(function()
		if not registered then
			load_settings()
			scr = manager:machine().screens[":screen"]
			inp = manager:machine():input()
			emu.register_frame_done(draw_elements)
			tar = manager:machine():render():ui_target()
			con = manager:machine():render():ui_container()
			update_box_size()			
			bar_x = scr:width() / 2
			emu.register_menu(menu_callback, menu_populate, "Input Lag Test for G.I.L.T.")
			registered = true
		end
	end)

	emu.register_stop(save_settings)
end

return exports
