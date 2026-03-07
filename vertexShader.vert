#version 330 core
layout (location = 0) in vec3 aPos;

uniform vec2 offset;
uniform float zoom;
uniform vec3 rotation;//unfinished

void main() {
    gl_Position = vec4(
        (aPos.x + offset.x) * zoom,
        (aPos.y + offset.y) * zoom,
        aPos.z,
        1.0
    );
}