#version 450

in vec3 pos;
in vec2 uv;
in float colour;

out vec2 vUV;
out float vColour;

uniform mat4 MVP;

void main() {
	// Just output position
	gl_Position = MVP * vec4(pos.xyz, 1.0);
    vUV = vec2(uv.x,uv.y);
	vColour = colour;
}