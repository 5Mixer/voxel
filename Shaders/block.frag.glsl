#version 450

in vec2 vUV;
in float vColour;
out vec4 fragColor;
uniform sampler2D textureSampler;

void main() {
    fragColor = vec4(vColour, vColour, vColour, 1.0) * texture(textureSampler, vUV);
}