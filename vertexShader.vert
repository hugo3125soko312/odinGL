#version 330 core
layout (location = 0) in vec3 aPos;

uniform vec2 offset;
uniform float zoom;
uniform float rot_x;
uniform float rot_y;
uniform vec2 zoom_center;

void main() {
    vec3 pos = aPos;
    
    // Rotation around X axis
    float cos_x = cos(rot_x);
    float sin_x = sin(rot_x);
    pos = vec3(
        pos.x,
        pos.y * cos_x - pos.z * sin_x,
        pos.y * sin_x + pos.z * cos_x
    );
    
    // Rotation around Y axis
    float cos_y = cos(rot_y);
    float sin_y = sin(rot_y);
    pos = vec3(
        pos.x * cos_y + pos.z * sin_y,
        pos.y,
        -pos.x * sin_y + pos.z * cos_y
    );
    
    // Apply offset and zoom relative to centroid
    pos.x = (pos.x + offset.x - zoom_center.x) * zoom + zoom_center.x;
    pos.y = (pos.y + offset.y - zoom_center.y) * zoom + zoom_center.y;
    
    gl_Position = vec4(pos.x, pos.y, pos.z, 1.0);
}