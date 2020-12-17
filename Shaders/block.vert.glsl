#version 450

// Input vertex data, different for all executions of this shader
in vec4 pos;
in vec2 uv;
in vec4 colour;

out vec2 vUV;
out float vColour;

uniform mat4 MVP;

void main() {
	// Just output position
	gl_Position = MVP * vec4(pos.xyz*32767, 1.0);
    vUV = vec2(uv.x,uv.y);
	vColour = colour.r;
}