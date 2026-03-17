package main

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import os "core:os"
import "core:path/filepath"
import time "core:time"

main :: proc(){
    // initialize first!
    if !glfw.Init() {
        fmt.println("glfw.Init() failed")
        return
    }
    defer glfw.Terminate()//after scope
    fmt.println("[DEBUG] GLFW initialized successfully")


    //hinting
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.REFRESH_RATE,glfw.DONT_CARE)
    fmt.println("[DEBUG] Window hints set")


    //window
    window:=glfw.CreateWindow(640,480,"My title",nil,nil)

    if window == nil {
        fmt.println("glfw.CreateWindow() failed")
    }
    defer glfw.DestroyWindow(window)// after out of scope:
    fmt.println("[DEBUG] Window created: 640x480")
    
    glfw.MakeContextCurrent(window) //make current context
    fmt.println("[DEBUG] Context made current")

    gl.load_up_to(4, 6, glfw.gl_set_proc_address)
    fmt.println("[DEBUG] OpenGL 4.6 loaded")
    
    //vertex data
    //x, y, depth
    vertex_data := [9]f32{
        0.0, 0.5, 0.0,// top
        -0.5, -0.5, 0.0,// bottom right
        0.5, -0.5, 0.0,// bottom left
    }
    fmt.println("[DEBUG] Vertex data created")
    
    // Calculate centroid -> array of x, y, z
    calculate_centroid :: proc(vertices: [9]f32) -> [3]f32 {
        centroid_x := (vertices[0] + vertices[3] + vertices[6]) / 3
        centroid_y := (vertices[1] + vertices[4] + vertices[7]) / 3
        centroid_z := (vertices[2] + vertices[5] + vertices[8]) / 3
        return [3]f32{centroid_x, centroid_y, centroid_z}
    }
    
    centroid := calculate_centroid(vertex_data)
    centroid_x := centroid[0]
    centroid_y := centroid[1]
    centroid_z := centroid[2]
    fmt.println("Centroid:", centroid_x, ",", centroid_y, ",", centroid_z)
    fmt.println("[DEBUG] Centroid calculated: (", centroid_x, ",", centroid_y, ",", centroid_z, ")")
    
    //vao, vbo
    VAO: u32
    gl.GenVertexArrays(1, &VAO)
    gl.BindVertexArray(VAO)
    VBO: u32
    gl.GenBuffers(1,&VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertex_data), &vertex_data, gl.STATIC_DRAW)
    fmt.println("[DEBUG] VAO ID:", VAO, "VBO ID:", VBO)

    //tell gl how to draw buffer
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    fmt.println("[DEBUG] Vertex attributes configured")

    //load shader files
    exe_dir := filepath.dir(os.args[0], context.allocator)
    vert_path := filepath.join({exe_dir, "vertexShader.vert"}, context.allocator)
    frag_path := filepath.join({exe_dir, "fragmentShader.frag"}, context.allocator)

    vert_src, vert_ok := os.read_entire_file(vert_path, context.allocator)
    frag_src, frag_ok := os.read_entire_file(frag_path, context.allocator)
    if !vert_ok || !frag_ok {
        fmt.println("failed to load shader files")
        return
    }
    fmt.println("[DEBUG] Shader files loaded successfully")

    //compile vertex shader
    vert := gl.CreateShader(gl.VERTEX_SHADER)
    vert_cstr := cstring(raw_data(vert_src))
    gl.ShaderSource(vert, 1, &vert_cstr, nil)
    gl.CompileShader(vert)
    defer gl.DeleteShader(vert)
    fmt.println("[DEBUG] Vertex shader compiled, ID:", vert)

    // compile fragment shader
    frag := gl.CreateShader(gl.FRAGMENT_SHADER)
    frag_cstr := cstring(raw_data(frag_src))
    gl.ShaderSource(frag, 1, &frag_cstr, nil)
    gl.CompileShader(frag)
    defer gl.DeleteShader(frag)
    fmt.println("[DEBUG] Fragment shader compiled, ID:", frag)

    // link shader program
    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vert)
    gl.AttachShader(shader_program, frag)
    gl.LinkProgram(shader_program)
    defer gl.DeleteProgram(shader_program)
    fmt.println("[DEBUG] Shader program linked, ID:", shader_program)

    //offsets
    offset_x: f32 = 0.0
    offset_y: f32 = 0.0
    speed: f32 = 0.01 //change?

    offset_loc := gl.GetUniformLocation(shader_program, "offset")
    fmt.println("[DEBUG] Offset uniform location:", offset_loc)
    fmt.println("[DEBUG] Initial offset_x:", offset_x, "offset_y:", offset_y, "speed:", speed)

    zoom: f32 = 1.0
    zoom_speed: f32 = 0.03
    min_zoom: f32 = 0.1
    max_zoom: f32 = 10.0
    zoom_loc := gl.GetUniformLocation(shader_program, "zoom")

    //rotation
    rot_x: f32 = 0.0
    rot_y: f32 = 0.0
    rot_speed: f32 = 0.05
    rot_x_loc := gl.GetUniformLocation(shader_program, "rot_x")
    rot_y_loc := gl.GetUniformLocation(shader_program, "rot_y")

    //centroid for zoom
    centroid_loc := gl.GetUniformLocation(shader_program, "zoom_center")

    //wait 2 sec
    //time.sleep(5 * time.Second)
    //main loop
    fmt.println("[DEBUG] === Ready to enter main loop ===")
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
        //bind keys EQ, zoom clamping
        if glfw.GetKey(window, glfw.KEY_E) == glfw.PRESS {
            new_zoom := zoom + zoom_speed
            if new_zoom <= max_zoom {
                zoom = new_zoom
            }
        }
        if glfw.GetKey(window, glfw.KEY_Q) == glfw.PRESS {
            new_zoom := zoom - zoom_speed
            if new_zoom >= min_zoom {
                zoom = new_zoom
            }
        }
        //bind keys ROT ARROWS
        if glfw.GetKey(window, glfw.KEY_UP) == glfw.PRESS { rot_x += rot_speed } 
        if glfw.GetKey(window, glfw.KEY_DOWN) == glfw.PRESS { rot_x -= rot_speed }
        if glfw.GetKey(window, glfw.KEY_LEFT) == glfw.PRESS { rot_y -= rot_speed }
        if glfw.GetKey(window, glfw.KEY_RIGHT) == glfw.PRESS { rot_y += rot_speed }

        //space uniform
        gl.Uniform2f(offset_loc, offset_x, offset_y)
        gl.Uniform1f(zoom_loc, zoom)
        gl.Uniform1f(rot_x_loc, rot_x)
        gl.Uniform1f(rot_y_loc, rot_y)
        gl.Uniform2f(centroid_loc, centroid_x, centroid_y)

        fmt.print("\x1b[2J\x1b[H")//genius way to clear console
        //debug info
        fmt.println("=== Transform Debug ===")
        fmt.println("Position - X:", offset_x, "Y:", offset_y)
        fmt.println("Zoom:", zoom)
        fmt.println("Rotation - X:", rot_x, "Y:", rot_y)
        fmt.println("Centroid:", centroid_x, ",", centroid_y)

                
        //draw
        gl.DrawArrays(gl.TRIANGLES, 0, 3)


        glfw.SwapBuffers(window)
    }
}