package sis

import "core:fmt"

Program_layer :: struct {
	size: [2]i32,
	tex: [][4]byte,
	data: [dynamic][4]byte
}

UI_BORDER_COLOR :: [4]byte{100, 100, 100, 255}
UI_BODY_COLOR :: [4]byte{200, 200, 200, 255}
UI_TEXT_COLOR :: [4]byte{100, 50, 50, 255}

// font from fenster
// ascii - 32
font5x3 := [?]u16{0x0000,0x2092,0x002d,0x5f7d,0x279e,0x52a5,0x7ad6,0x0012,0x4494,0x1491,0x017a,0x05d0,0x1400,0x01c0,0x0400,0x12a4,0x2b6a,0x749a,0x752a,0x38a3,0x4f4a,0x38cf,0x3bce,0x12a7,0x3aae,0x49ae,0x0410,0x1410,0x4454,0x0e38,0x1511,0x10e3,0x73ee,0x5f7a,0x3beb,0x624e,0x3b6b,0x73cf,0x13cf,0x6b4e,0x5bed,0x7497,0x2b27,0x5add,0x7249,0x5b7d,0x5b6b,0x3b6e,0x12eb,0x4f6b,0x5aeb,0x388e,0x2497,0x6b6d,0x256d,0x5f6d,0x5aad,0x24ad,0x72a7,0x6496,0x4889,0x3493,0x002a,0xf000,0x0011,0x6b98,0x3b79,0x7270,0x7b74,0x6750,0x95d6,0xb9ee,0x5b59,0x6410,0xb482,0x56e8,0x6492,0x5be8,0x5b58,0x3b70,0x976a,0xcd6a,0x1370,0x38f0,0x64ba,0x3b68,0x2568,0x5f68,0x54a8,0xb9ad,0x73b8,0x64d6,0x2492,0x3593,0x03e0}

draw_char :: proc(ui: Program_layer, chr_pos: [2]i32, char: rune) {
	bmp := font5x3[char]
	for y in i32(0)..<5 {
		for x in i32(0)..<3 {
			i_x := chr_pos.x + x
			i_y := chr_pos.y + (5 - y)
			if 0 > i_x || i_x >= ui.size.x do continue
			if 0 > i_y || i_y >= ui.size.y do continue
			if ((bmp >> uint(x + y*3)) & 1) == 1 do ui.tex[i_x + i_y*ui.size.x] = UI_TEXT_COLOR
		}
	}

//	fmt.println(font5x3[char-32])
}

// FIXME: goes out of bounds when box is too big and texture is too small?
// It has to do with the window becoming too small and the mouse coordinates getting real confused
draw_ui_box :: proc(ui: Program_layer, box_pos: [2]i32, box_size: [2]i32){
	box_pos := box_pos
	assert(box_size.x > 0 && box_size.y > 0)
	box_pos.x = clamp(box_pos.x, 0, max(ui.size.x - box_size.x - 1, UI_MINIMUM_SIZE.x))
	box_pos.y = clamp(box_pos.y, 0, max(ui.size.y - box_size.y - 1, UI_MINIMUM_SIZE.y))

	lower_row := box_pos.x + box_pos.y*ui.size.x
	for i in lower_row..=lower_row + box_size.x do ui.tex[i] = UI_BORDER_COLOR

	for y in box_pos.y + 1..<box_pos.y + box_size.y {
		i := box_pos.x + y*ui.size.x 
		ui.tex[i] = UI_BORDER_COLOR
		for x in 1..<box_size.x {
			ui.tex[x + i] = UI_BODY_COLOR
		}
		ui.tex[i + box_size.x] = UI_BORDER_COLOR
	}
	upper_row := box_pos.x + (box_pos.y + box_size.y)*ui.size.x
	for i in upper_row..=upper_row + box_size.x do ui.tex[i] = UI_BORDER_COLOR
}

