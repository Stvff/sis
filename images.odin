package sis

import "core:fmt"

Image :: struct {
	name: string,
	size: [2]i32,
	pos: [2]i32,
	data: [dynamic][4]byte
}

draw_images :: proc(l: Program_layer, imgs: []Image, do_center := true, origin: [2]i32 = {0, 0}){
	origin := origin
	if len(imgs) == 0 do return
	if do_center do origin = {l.size.x/2 - imgs[0].size.x/2, l.size.y/2 - imgs[0].size.y/2}

	for img in imgs {
	if len(img.data) == 0 do continue
	for y in i32(0)..<img.size.y-1 {
	for x in i32(0)..<img.size.x-1 {
		p := origin + img.pos + {x, y}
		if 0 > p.x || p.x >= l.size.x do continue
		if 0 > p.y || p.y >= l.size.y do continue
		l.tex[p.x + p.y*l.size.x] = img.data[x + y*img.size.x]
	}}}
}
