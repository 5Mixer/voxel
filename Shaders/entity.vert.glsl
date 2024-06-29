#version 450

in vec3 pos;
in vec2 uv;
in float colour;

out vec2 vUV;
out float vColour;
out vec3 vPos;
out vec4 vMvpPos;

uniform mat4 MVP;

void main() {
	// Just output position
	vMvpPos = MVP * vec4(pos.xyz, 1.0);
	gl_Position = vMvpPos;
    vUV = vec2(uv.x,uv.y);
	vColour = colour;
	vPos = pos;
}