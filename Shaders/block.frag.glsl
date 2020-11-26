#version 450

in vec2 vUV;
in vec3 vColour;
out vec4 fragColor;
uniform sampler2D textureSampler;

void main() {
    fragColor = vec4(vColour, 1.0) * texture(textureSampler, vUV);
}