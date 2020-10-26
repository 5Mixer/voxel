#version 450

// Input vertex data, different for all executions of this shader
in vec3 pos;
in vec2 uv;
in vec3 colour;

out vec2 vUV;
out vec3 vColour;

uniform mat4 MVP;

void main() {
	// Just output position
	gl_Position = MVP * vec4(pos, 1.0);
    vUV = uv;
	vColour = colour;
}