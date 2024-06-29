#version 450

in vec2 vUV;
in vec3 vPos;
out vec4 fragColor;
uniform sampler2D textureSampler;
in vec4 vMvpPos;

float fogMax = 120.0;
float fogMin = 100.0;
vec4 fogColour = vec4(172.0/255.0, 219.0/255.0, 252.0/255.0, 1.0);

void main() {
    vec4 diffuse = texture(textureSampler, vUV);


    // Calculate fog
    float dist = length(vMvpPos.xyz);
    float fogFactor = (fogMax - dist) / (fogMax - fogMin);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    fragColor = mix(fogColour, diffuse, fogFactor);
}