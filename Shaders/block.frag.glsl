#version 450

in vec2 vUV;
out vec4 fragColor;
uniform sampler2D textureSampler;

void main() {
	// Just output red color
	// fragColor = vec4(1.0, 0.0, 0.0, 1.0);
    fragColor = texture(textureSampler, vUV);
}