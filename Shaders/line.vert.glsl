#version 450

// Input vertex data, different for all executions of this shader
in vec3 pos;
in vec3 colour;

out vec3 vColour;

uniform mat4 MVP;

void main() {
	// Just output position
	gl_Position = MVP * vec4(pos, 1.0);
	// gl_Position /= gl_Position.w;
	vColour = colour;
}