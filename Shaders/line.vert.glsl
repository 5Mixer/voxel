#version 450

// Input vertex data, different for all executions of this shader
in vec3 pos;
in vec3 normal;
in vec3 colour;

out vec3 vColour;

uniform mat4 MVP;

void main() {
	vec4 clipSpace = MVP * vec4(pos, 1.0);
	vec2 ndcSpace = clipSpace.xy / clipSpace.w;
	gl_Position = clipSpace+vec4(normal,0)/80; // Problem is this normal should be in screen space, as in ndcspace.
	gl_Position = MVP * vec4(pos+normal*.01, 1.0);

	vColour = colour;
}