#version 450

// Input vertex data, different for all executions of this shader
in vec3 pos;
in vec3 tangent;
in vec3 colour;

out vec3 vColour;

uniform mat4 MVP;
uniform mat4 View;

void main() {
	float depth = (MVP * vec4(pos,1.0)).z/(MVP * vec4(pos,1.0)).w/10;
	// Just output position
	gl_Position = MVP * vec4(pos+(tangent/depth/100), 1.0);
	// gl_Position += MVP * vec4(tangent/depth,0);
	// gl_Position /= gl_Position.w;
	// gl_Position += MVP * vec4(tangent,1)*gl_Position.w;

	vColour = colour;
}