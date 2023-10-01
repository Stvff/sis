package sis

import "core:fmt"

Program_layer :: struct {
	size: [2]i32,
	tex: [][4]byte,
	data: [dynamic][4]byte
}

ON_STATE :: enum{
	nothing,
	image_bin_up_down_button,
	dial_begin,
		dial_dial,
		dial_button,
	dial_end,
	save_button,
}
Mouse :: struct {
	pos: [2]i32,
	left, right: bool,
	left_was, right_was: bool,

	is_on: ON_STATE,
	was_on: ON_STATE,
	fpos: [2]f64,
}

Dial_box :: struct {
	title: string,
	pos: [2]i32,
	target: int,
	is_on: enum{one, two},
	input_len: [2]int,
	input_cursor: [2]int,
	input_field: [2][64]byte,
}

UI_BORDER_COLOR :: [4]byte{100, 70, 100, 255}
UI_BODY_COLOR :: [4]byte{180, 150, 180, 255}
UI_TEXT_COLOR :: [4]byte{0, 0, 30, 255}
UI_ACTIVATED_COLOR :: [4]byte{230, 50, 50, 255}
UI_PRESSED_COLOR :: [4]byte{70, 60, 220, 255}

draw_box_button :: proc(ui: Program_layer, mouse: Mouse, but_pos: [2]i32, but_size: [2]i32, check_press: bool,
							 dyn := true, border_color := UI_BORDER_COLOR, body_color := UI_BODY_COLOR,
							 activated_color := UI_ACTIVATED_COLOR, pressed_color := UI_PRESSED_COLOR) -> (state: enum{none, on, press}) {
	but_pos, border_color := but_pos, border_color
	if check_press && is_in_rect(mouse.pos, but_pos, but_size) {
		border_color = pressed_color if mouse.left else activated_color
		state = .press if !mouse.left && mouse.left_was else .on
	}
	if dyn do draw_box(ui, but_pos, but_size, border_color, body_color)
	else do draw_ui_box(ui, but_pos, but_size, border_color, body_color)
	return state
}

draw_text_box_button :: proc(ui: Program_layer, mouse: Mouse, but_pos: [2]i32, text: string, check_press: bool,
							 dyn := true, border_color := UI_BORDER_COLOR, body_color := UI_BODY_COLOR, text_color := UI_TEXT_COLOR,
							 activated_color := UI_ACTIVATED_COLOR, pressed_color := UI_PRESSED_COLOR) -> (state: enum{none, on, press}) {
	but_pos, border_color := but_pos, border_color
	button_size := [2]i32{text_box_width(len(text)), TEXT_BOX_HEIGHT}
	if check_press && is_in_rect(mouse.pos, but_pos, button_size) {
		border_color = pressed_color if mouse.left else activated_color
		state = .press if !mouse.left && mouse.left_was else .on
	}
	draw_text_in_box(ui, but_pos, text, dyn, border_color, body_color, text_color)
	return state
}

draw_box :: proc(ui: Program_layer, box_pos: [2]i32, box_size: [2]i32, border_color := UI_BORDER_COLOR, body_color := UI_BODY_COLOR) {
	for y in box_pos.y..<box_pos.y + box_size.y {
	for x in box_pos.x..<box_pos.x + box_size.x {
		color := body_color
		if y == box_pos.y || y == box_pos.y + box_size.y - 1 do color = border_color
		if x == box_pos.x || x == box_pos.x + box_size.x - 1 do color = border_color
		if is_in_space({x, y}, ui.size) do ui.tex[x + y*ui.size.x] = color
	}}
}

draw_line :: proc(l: Program_layer, begin: [2]i32, r: [2]i32, color: [4]byte){
//	r := end - begin
	total_steps: i32 = abs(r.x) < abs(r.y) ? r.y : r.x
	increment: i32 = total_steps > 0 ? 1 : -1
	for t: i32 = 0; t != total_steps; t += increment {
		pos := begin + t*r/total_steps
		draw_pixel(l, pos, color)
	}
}

SMALL_ARROW_SIZE :: [2]i32{5, 5}
draw_small_arrow :: proc(ui: Program_layer, arw_pos: [2]i32, direction: enum{up, down, left, right}, clr: [4]byte){
	switch direction {
	case .up:
		for x in i32(0)..<5 do draw_pixel(ui, arw_pos + {x, 2}, clr)
		for x in i32(1)..<4 do draw_pixel(ui, arw_pos + {x, 3}, clr)
		draw_pixel(ui, arw_pos + {2, 4}, clr)
	case .down:
		for x in i32(0)..<5 do draw_pixel(ui, arw_pos + {x, 2}, clr)
		for x in i32(1)..<4 do draw_pixel(ui, arw_pos + {x, 1}, clr)
		draw_pixel(ui, arw_pos + {2, 0}, clr)
	case .left:
		for y in i32(0)..<5 do draw_pixel(ui, arw_pos + {2, y}, clr)
		for y in i32(1)..<4 do draw_pixel(ui, arw_pos + {1, y}, clr)
		draw_pixel(ui, arw_pos + {0, 2}, clr)
	case .right:
		for y in i32(0)..<5 do draw_pixel(ui, arw_pos + {2, y}, clr)
		for y in i32(1)..<4 do draw_pixel(ui, arw_pos + {3, y}, clr)
		draw_pixel(ui, arw_pos + {4, 2}, clr)
	}
}

draw_pixel :: proc(ui: Program_layer, pix_pos: [2]i32, clr: [4]byte) {
	if 0 > pix_pos.x || pix_pos.x >= ui.size.x do return
	if 0 > pix_pos.y || pix_pos.y >= ui.size.y do return
	ui.tex[pix_pos.x + pix_pos.y*ui.size.x] = clr
}

TEXT_BOX_HEIGHT :: 9
draw_text_in_box :: proc(ui: Program_layer, box_pos: [2]i32, txt: string, dyn := true, border_color := UI_BORDER_COLOR, body_color := UI_BODY_COLOR, text_color := UI_TEXT_COLOR) -> (size: [2]i32) {
	box_size := [2]i32{i32(len(txt))*4 + 4, TEXT_BOX_HEIGHT}
	txt_pos: [2]i32
	if dyn do txt_pos = draw_ui_box(ui, box_pos, box_size, border_color, body_color)
	else {
		txt_pos = box_pos
		draw_box(ui, box_pos, box_size, border_color, body_color)
	}
	draw_text(ui, txt_pos + {3, 1}, txt, text_color)
	return box_size
}
text_box_width :: #force_inline proc(len: int) -> i32 {
	return i32(len*4 + 4)
}

draw_text :: proc(ui: Program_layer, txt_pos: [2]i32, txt: string, color := UI_TEXT_COLOR){
	txt_pos := txt_pos
	for c in txt {
		draw_char(ui, txt_pos, c, color)
		txt_pos.x += 4
	}
}

// font from fenster
// ascii - 32
font5x3 := [?]u16{0x0000,0x2092,0x002d,0x5f7d,0x279e,0x52a5,0x7ad6,0x0012,0x4494,0x1491,0x017a,0x05d0,0x1400,0x01c0,0x0400,0x12a4,0x2b6a,0x749a,0x752a,0x38a3,0x4f4a,0x38cf,0x3bce,0x12a7,0x3aae,0x49ae,0x0410,0x1410,0x4454,0x0e38,0x1511,0x10e3,0x73ee,0x5f7a,0x3beb,0x624e,0x3b6b,0x73cf,0x13cf,0x6b4e,0x5bed,0x7497,0x2b27,0x5add,0x7249,0x5b7d,0x5b6b,0x3b6e,0x12eb,0x4f6b,0x5aeb,0x388e,0x2497,0x6b6d,0x256d,0x5f6d,0x5aad,0x24ad,0x72a7,0x6496,0x4889,0x3493,0x002a,0xf000,0x0011,0x6b98,0x3b79,0x7270,0x7b74,0x6750,0x95d6,0xb9ee,0x5b59,0x6410,0xb482,0x56e8,0x6492,0x5be8,0x5b58,0x3b70,0x976a,0xcd6a,0x1370,0x38f0,0x64ba,0x3b68,0x2568,0x5f68,0x54a8,0xb9ad,0x73b8,0x64d6,0x2492,0x3593,0x03e0}
draw_char :: proc(ui: Program_layer, chr_pos: [2]i32, char: rune, color := UI_TEXT_COLOR) {
	bmp: u16
	if 32 > char && char >= len(font5x3) do bmp = 0
	else do bmp = font5x3[char - 32]
	for y in i32(0)..<5 {
		for x in i32(0)..<3 {
			i_x := chr_pos.x + x
			i_y := chr_pos.y + (5 - y)
			if 0 > i_x || i_x >= ui.size.x do continue
			if 0 > i_y || i_y >= ui.size.y do continue
			if ((bmp >> uint(x + y*3)) & 1) == 1 do ui.tex[i_x + i_y*ui.size.x] = color
		}
	}
}

// FIXME: goes out of bounds when box is too big and texture is too small?
// It has to do with the window becoming too small and the mouse coordinates getting real confused
draw_ui_box :: proc(ui: Program_layer, box_pos: [2]i32, box_size: [2]i32, border_color := UI_BORDER_COLOR, body_color := UI_BODY_COLOR) -> (actual_pos: [2]i32) {
	box_pos, box_size := box_pos, box_size
	assert(box_size.x > 0 && box_size.y > 0)
	right_edge_color, top_edge_color := border_color, border_color
	if box_size.x > ui.size.x do right_edge_color = body_color
	if box_size.y > ui.size.y do top_edge_color = body_color

	box_size = vec_clamp(box_size, 0, ui.size)
	box_pos = vec_clamp(box_pos, 0, vec_max(0, ui.size - box_size))

	lower_row := box_pos.x + box_pos.y*ui.size.x
	for i in lower_row..<lower_row + box_size.x do ui.tex[i] = border_color

	for y in box_pos.y + 1..<box_pos.y + box_size.y - 1 {
		i := box_pos.x + y*ui.size.x 
		ui.tex[i] = border_color
		for x in 1..<box_size.x - 1 {
			ui.tex[x + i] = body_color
		}
		ui.tex[i + box_size.x - 1] = right_edge_color
	}

	upper_row := box_pos.x + (box_pos.y + box_size.y - 1)*ui.size.x
	for i in upper_row..<upper_row + box_size.x do ui.tex[i] = top_edge_color

	return box_pos
}

RED         :: [4]byte{0xFF, 0x00, 0x00, 0xFF}
GREEN       :: [4]byte{0x00, 0xFF, 0x00, 0xFF}
BLUE        :: [4]byte{0x00, 0x00, 0xFF, 0xFF}
WHITE       :: [4]byte{0xFF, 0xFF, 0xFF, 0xFF}
BLACK       :: [4]byte{0x00, 0x00, 0x00, 0xFF}
GRAY        :: [4]byte{0xAA, 0xAA, 0xAA, 0xFF}
GREY        :: [4]byte{0x22, 0x22, 0x22, 0xFF}
PASTEL_RED  :: [4]byte{0xFF, 0x40, 0x40, 0xFF}
PASTEL_PINK :: [4]byte{0xF5, 0xA9, 0xB8, 0xFF}
PASTEL_BLUE :: [4]byte{0x5B, 0xCE, 0xFA, 0xFF}
