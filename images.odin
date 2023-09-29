package sis

import "core:fmt"

Image :: struct {
	name: string,
	pos: [2]i32,
	size: [2]i32,
	data: [dynamic][4]byte,

	scale: f64
}

draw_images :: proc(l: Program_layer, imgs: []Image, do_center := true, origin: [2]i32 = {0, 0}){
	origin := origin
	if len(imgs) == 0 do return
	if do_center do origin = l.size/2 - imgs[0].size/2

	for img in imgs {
	if len(img.data) == 0 do continue
	for y in i32(0)..<img.size.y-1 {
	for x in i32(0)..<img.size.x-1 {
		p := origin + img.pos + {x, y}
		if !is_in_space(p, l.size) do continue
		ipix := img.data[x + (img.size.y - y - 1)*img.size.x]
		tpix := l.tex[p.x + p.y*l.size.x]
		a := f64(ipix.a)/255
		mix := [4]byte{
			byte(a*f64(ipix.r) + (1-a)*f64(tpix.r)),
			byte(a*f64(ipix.g) + (1-a)*f64(tpix.g)),
			byte(a*f64(ipix.b) + (1-a)*f64(tpix.b)),
			255
		}
		l.tex[p.x + p.y*l.size.x] = mix
	}}}
}

draw_preddy_gradient :: proc(layer: Program_layer){
	y: i32 = 0
	for &pix, i in layer.tex {
		pix = [4]byte{255 - byte((210*y)/layer.size.x), 0, 255 - byte((210*i) / len(layer.tex)), 255}
		y = (y + 1)%layer.size.x
//		pix = [4]byte{0, 0, 255 - byte((255*i) / len(imgl.tex)), 255}
//		pix = {0, 0, 63, 255}
	}
}

import "core:slice"
import "core:image/qoi"
import "core:bytes"
load_qoi :: proc(name: string) -> (my_img: Image) {
	qimg, err := qoi.load(name) // TODO: check if file exists/is proper
	if err != nil do panic("load_qoi: loading error")
	defer qoi.destroy(qimg)
	if qimg.channels != 4 do panic("load_qoi: wrong amount of channels")
	if qimg.depth != 8 do panic("load_qoi: wrong depth")
	my_img.name = name
	my_img.size.x = i32(qimg.width)
	my_img.size.y = i32(qimg.height)
	my_img.data = make([dynamic][4]byte, area(my_img.size))
	buf := slice.reinterpret([]byte, my_img.data[:])
	copy(buf, bytes.buffer_to_bytes(&qimg.pixels))
	return my_img
}
