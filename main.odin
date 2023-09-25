package sis

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:math"

INIT_WIDTH   :: 1600
INIT_HEIGHT  :: 900
WINDOW_TITLE :: "Take a look at this"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

main :: proc() {
	if !bool(glfw.Init()) {
		fmt.eprintln("GLFW has failed to init")
		return
	} defer glfw.Terminate()

	window_handle := glfw.CreateWindow(INIT_WIDTH, INIT_HEIGHT, WINDOW_TITLE, nil, nil)
	defer glfw.DestroyWindow(window_handle)
	if window_handle == nil {
		fmt.eprintln("GLFW has failed to create a window")
		return
	}

	{
		glfw.MakeContextCurrent(window_handle)
		glfw.SetFramebufferSizeCallback(window_handle, window_size_changed)
		gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	}

	shader_program: u32; { /* compile and link shaders */
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

	vertex_buffer_o, vertex_array_o, element_buffer_o: u32; { /* do some frankly insane triangle definition stuff */
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

		gl.BindVertexArray(vertex_array_o)
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


	gui_tex := make([][4]byte, 256*256)
	defer delete(gui_tex)
	img_tex := make([][4]byte, 1024*1024)
	defer delete(img_tex)
	x: u8 = 0
	for &pix, i in gui_tex {
		pix = [4]byte{byte((255*i) / len(gui_tex)), 0, x, 100}
		x = (x + 1)
	}
	for &pix, i in img_tex {
		pix = [4]byte{0, 255 - byte((255*i) / len(img_tex)), 0, 255}
	}

	gui_tex_o, img_tex_o: u32; {
		gl.GenTextures(1, &gui_tex_o)
		gl.BindTexture(gl.TEXTURE_2D, gui_tex_o)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 256, 256, 0, gl.RGBA, gl.UNSIGNED_BYTE, &gui_tex[0])

		gl.GenTextures(1, &img_tex_o)
		gl.BindTexture(gl.TEXTURE_2D, img_tex_o)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1024, 1024, 0, gl.RGBA, gl.UNSIGNED_BYTE, &img_tex[0])
	}

	gl.UseProgram(shader_program)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "gui_texture"), 0)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "img_texture"), 1)


	t: u128 = 0
	lim :: 100
	for !glfw.WindowShouldClose(window_handle) {
		// Process all incoming events like keyboard press, window resize, and etc.
		glfw.PollEvents()

//		gl.ClearColor(0.5, 0.0, 0.5 + math.sin(f32(t)/f32(lim))/2.0, 1.0)
		gl.ClearColor(0.5, 0.5, 0.5, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gui_tex[800] = [4]byte{255, byte(255*math.sin(f32(t)/f32(lim))), 255, 255}
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, gui_tex_o)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 256, 256, 0, gl.RGBA, gl.UNSIGNED_BYTE, &gui_tex[0])
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, img_tex_o)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1024, 1024, 0, gl.RGBA, gl.UNSIGNED_BYTE, &img_tex[0])

		gl.UseProgram(shader_program)
		gl.BindVertexArray(vertex_array_o)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		t += 1

	glfw.SwapBuffers(window_handle) }
}


import "core:runtime"
window_size_changed :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	fmt.println("thing changed:", width, height, window)
	gl.Viewport(0, 0, width, height)
}
