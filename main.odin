package main

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:os"

main :: proc(){
    // initialize first!
    if !glfw.Init() {
        fmt.println("glfw.Init() failed")
        return
    }
    defer glfw.Terminate()//after scope


    //hinting
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.REFRESH_RATE,glfw.DONT_CARE)


    //window
    window:=glfw.CreateWindow(640,480,"My title",nil,nil)

    if window == nil {
        fmt.println("glfw.CreateWindow() failed")
    }
    defer glfw.DestroyWindow(window)// after out of scope: 
    glfw.MakeContextCurrent(window) //make current context

    gl.load_up_to(4, 6, glfw.gl_set_proc_address)
    //vertex data
    vertices := [9]f32{
        0.0, 0.5, 0.0,// top
        -0.5, -0.5, 0.0,// bottom right
        0.5, -0.5, 0.0,// bottom left
    }
    //vao, vbo
    VAO: u32
    gl.GenVertexArrays(1, &VAO)
    gl.BindVertexArray(VAO)
    VBO: u32
    gl.GenBuffers(1,&VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    //tell gl how to draw buffer
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    //load shader files
    vert_src, vert_ok := os.read_entire_file("vertexShader.vert", context.allocator)
    frag_src, frag_ok := os.read_entire_file("fragmentShader.frag", context.allocator)
    if !vert_ok || !frag_ok {
        fmt.println("failed to load shader files")
        return
    }

    //compile vertex shader
    vert := gl.CreateShader(gl.VERTEX_SHADER)
    vert_cstr := cstring(raw_data(vert_src))
    gl.ShaderSource(vert, 1, &vert_cstr, nil)
    gl.CompileShader(vert)
    defer gl.DeleteShader(vert)

    // compile fragment shader
    frag := gl.CreateShader(gl.FRAGMENT_SHADER)
    frag_cstr := cstring(raw_data(frag_src))
    gl.ShaderSource(frag, 1, &frag_cstr, nil)
    gl.CompileShader(frag)
    defer gl.DeleteShader(frag)

    // link shader program
    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vert)
    gl.AttachShader(shader_program, frag)
    gl.LinkProgram(shader_program)
    defer gl.DeleteProgram(shader_program)

    //offsets
    offset_x: f32 = 0.0
    offset_y: f32 = 0.0
    speed: f32 = 0.01 //change?

    offset_loc := gl.GetUniformLocation(shader_program, "offset")


    //main loop
    for !glfw.WindowShouldClose(window){
        glfw.PollEvents()

        gl.ClearColor(1, 1, 1, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader_program)
        gl.BindVertexArray(VAO)
        
        //bind keys WASD
        if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS { offset_y += speed }
        if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS { offset_y -= speed }
        if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS { offset_x -= speed }
        if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS { offset_x += speed }
        //bind keys EQ
        if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS { offset_x -= speed }
        if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS { offset_x += speed }
        //bind keys ROT ARROWS
        if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS { offset_x -= speed }
        if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS { offset_x += speed }
        //space uniform
        gl.Uniform2f(offset_loc, offset_x, offset_y)

        //draw
        gl.DrawArrays(gl.TRIANGLES, 0, 3)


        glfw.SwapBuffers(window)
    }
}