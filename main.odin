package sis

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:math"
import "core:slice"

INIT_WIDTH   :: 1280
INIT_HEIGHT  :: 800
WINDOW_TITLE :: "Stvff's Image Splicer (currently in UI dev stage)"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3
UI_SCALE :: 10
MINIMUM_SIZE :: [2]i32{200, 100}
UI_MINIMUM_SIZE :: [2]i32{MINIMUM_SIZE.x/UI_SCALE, MINIMUM_SIZE.y/UI_SCALE}

main :: proc() {
	if !bool(glfw.Init()) {
		fmt.eprintln("GLFW has failed to init")
		return
	} defer glfw.Terminate()

	window_size: [2]i32
	window_handle: glfw.WindowHandle
	{
//		glfw.WindowHint(glfw.MAXIMIZED, 1)
		glfw.WindowHint(glfw.RESIZABLE, 1)
		window_handle = glfw.CreateWindow(INIT_WIDTH, INIT_HEIGHT, WINDOW_TITLE, nil, nil)
		if window_handle == nil {
			fmt.eprintln("GLFW has failed to create a window")
			return
		}
		glfw.MakeContextCurrent(window_handle)

		glfw.SetFramebufferSizeCallback(window_handle, window_size_changed)
		glfw.SetWindowSizeLimits(window_handle, MINIMUM_SIZE.x, MINIMUM_SIZE.y, glfw.DONT_CARE, glfw.DONT_CARE)
		window_size.x, window_size.y = glfw.GetFramebufferSize(window_handle)
		gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	} defer glfw.DestroyWindow(window_handle)


	shader_program: u32
	{ /* compile and link shaders */
		success: i32
		log_backing: [512]u8
		log := cast([^]u8) &log_backing
		vertex_shader_source := #load("./vertex.glsl", cstring)
		fragment_shader_source := #load("./fragment.glsl", cstring)
		/* compile vertex shader */
		vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
		defer gl.DeleteShader(vertex_shader)
		gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil)
		gl.CompileShader(vertex_shader)
		if gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success); !bool(success) {
			gl.GetShaderInfoLog(vertex_shader, len(log_backing), nil, log)
			fmt.eprintln("vertex shader error:", cstring(log) )
		}
		/* compile fragment shader */
		fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
		defer gl.DeleteShader(fragment_shader)
		gl.ShaderSource(fragment_shader, 1, &fragment_shader_source, nil)
		gl.CompileShader(fragment_shader)
		if gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success); !bool(success) {
			gl.GetShaderInfoLog(fragment_shader, len(log_backing), nil, log)
			fmt.eprintln("fragment shader error:", cstring(log) )
		}
		/* link fragment shader */
		shader_program = gl.CreateProgram()
		gl.AttachShader(shader_program, vertex_shader)
		gl.AttachShader(shader_program, fragment_shader)
		gl.LinkProgram(shader_program)
		if gl.GetShaderiv(shader_program, gl.LINK_STATUS, &success); !bool(success) {
			gl.GetShaderInfoLog(shader_program, len(log_backing), nil, log)
			fmt.eprintln("shader linking error:", cstring(log) )
		}
	} defer gl.DeleteProgram(shader_program)

	vertex_buffer_o, vertex_array_o, element_buffer_o: u32
	{ /* do some frankly insane triangle definition stuff */
		vertices := [?]f32 {
			/* triangle vertices */  /* texture coords */
			-2.0, -1.0, 0.0,         -0.5, 0.0,  // bottom left
			 2.0, -1.0, 0.0,         1.5, 0.0,   // bottom right
			 0.0,  3.0, 0.0,         0.5,  2,    // top
		}
		indices := [?]u32 {
			0, 1, 2, // first
			0, 1, 2  // second
		}
		gl.GenVertexArrays(1, &vertex_array_o) /* this has info about how to read the buffer */
		gl.GenBuffers(1, &vertex_buffer_o)     /* this has the actual data */
		gl.GenBuffers(1, &element_buffer_o)    /* this is a decoupling layer for the actual data for re-using vertices */

		gl.BindVertexArray(vertex_array_o) /* global state indicators */
		gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer_o)
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffer_o)

		gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)
		gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 5*size_of(f32), uintptr(0)) /* give info about how to read the buffer */
		gl.EnableVertexAttribArray(0) /* this zero is the same 0 as the first 0 in the call above */
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, 5*size_of(f32), uintptr(3*size_of(f32)))
		gl.EnableVertexAttribArray(1)
//		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	} defer {
		gl.DeleteVertexArrays(1, &vertex_array_o)
		gl.DeleteBuffers(1, &vertex_buffer_o)
		gl.DeleteBuffers(1, &element_buffer_o)
	}


	guil, imgl: Program_layer
	guil.size = window_size/UI_SCALE
	imgl.size = window_size
	fmt.println("sizes of texes", guil.size, imgl.size)

	guil.data = make([dynamic][4]byte, area(guil.size))
	imgl.data = make([dynamic][4]byte, area(imgl.size))
	defer delete(guil.data)
	defer delete(imgl.data)
	guil.tex = guil.data[:]
	imgl.tex = imgl.data[:]

	guil.tex[len(guil.tex)/2 + int(guil.size.x)/2] = 255
	for &pix, i in imgl.tex {
		pix = [4]byte{0, 0, 255 - byte((255*i) / len(imgl.tex)), 255}
	}

	gui_tex_o, img_tex_o: u32
	{
		gl.GenTextures(1, &gui_tex_o)
		gl.BindTexture(gl.TEXTURE_2D, gui_tex_o)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST); gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, expand_values(guil.size), 0, gl.RGBA, gl.UNSIGNED_BYTE, &guil.tex[0])

		gl.GenTextures(1, &img_tex_o)
		gl.BindTexture(gl.TEXTURE_2D, img_tex_o)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST); gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, expand_values(imgl.size), 0, gl.RGBA, gl.UNSIGNED_BYTE, &imgl.tex[0])
	}

	gl.UseProgram(shader_program)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "gui_texture"), 0)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "img_texture"), 1)


	t: u128 = 0
	lim :: 100
	for !glfw.WindowShouldClose(window_handle) { glfw.PollEvents()
		if glfw.GetKey(window_handle, glfw.KEY_ESCAPE) == glfw.PRESS do break

		{ /* if window size changes */
			new_window_size: [2]i32
			new_window_size.x, new_window_size.y = glfw.GetFramebufferSize(window_handle)
			if new_window_size != window_size {
				window_size = new_window_size
				fmt.println("thing changed:", window_size)
				guil.size = vecmax(window_size/UI_SCALE, UI_MINIMUM_SIZE)
				imgl.size = vecmax(window_size, MINIMUM_SIZE)
				fmt.println("gui size", guil.size)

				if area(guil.size) > len(guil.data) || area(imgl.size) > len(imgl.data) {
					fmt.println("realloced")
					resize(&guil.data, area(guil.size))
					resize(&imgl.data, area(imgl.size))
					guil.tex = guil.data[:]
					imgl.tex = imgl.data[:]
				} else {
					guil.tex = guil.data[0:area(guil.size)]
					imgl.tex = imgl.data[0:area(imgl.size)]
				}

				slice.fill(guil.tex, 0)
//				slice.fill(imgl.tex, 0)
				y: i32 = 0
				for &pix, i in imgl.tex {
//					pix = [4]byte{0, 0, 255 - byte((255*i) / len(imgl.tex)), 255}
//					pix = [4]byte{255 - byte((255*y)/imgl.size.x), 0, 255 - byte((255*i) / len(imgl.tex)), 255}
//					y = (y + 1)%imgl.size.x
					pix = {0, 0, 63, 255}
				}
				fmt.println("---------------------- new frame -----------------")
			}
		}

		slice.fill(guil.tex, 0)

		cursor_pos: [2]i32
		{
			cursor_pos_float: [2]f64
			cursor_pos_float.x, cursor_pos_float.y = glfw.GetCursorPos(window_handle)
			cursor_pos.x = clamp(i32(cursor_pos_float.x)/UI_SCALE, 0, guil.size.x-1)
			cursor_pos.y = clamp((window_size.y - i32(cursor_pos_float.y))/UI_SCALE, 0, guil.size.y-1)
		}


		draw_ui_box(guil, {20, 20}, {8, 8})
		draw_char(guil, {23, 21}, 'S')

		draw_ui_box(guil, {27, 16}, {8, 8})
		draw_char(guil, {30, 17}, 'I')

		draw_ui_box(guil, {21, 10}, {8, 8})
		draw_char(guil, {24, 11}, 'S')






















		/* render to screen with openGL */
		gl.ClearColor(0.5, 0.5, 0.5, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, gui_tex_o)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, expand_values(guil.size), 0, gl.RGBA, gl.UNSIGNED_BYTE, &guil.tex[0])
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, img_tex_o)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, expand_values(imgl.size), 0, gl.RGBA, gl.UNSIGNED_BYTE, &imgl.tex[0])

		gl.UseProgram(shader_program)
		gl.BindVertexArray(vertex_array_o)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		t += 1
	glfw.SwapBuffers(window_handle) }
}

area :: proc(v: [2]i32) -> int {
	return int(v.x)*int(v.y)
}

vecmax :: proc(v: [2]i32, n: [2]i32) -> [2]i32 {
	return [2]i32{max(v.x, n.x), max(v.y, n.y)}
}

window_size_changed :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
