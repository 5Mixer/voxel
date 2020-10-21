#version 330
#extension GL_ARB_compute_shader : require
#extension GL_ARB_shader_image_load_store : require
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

uniform writeonly image2D dest;
uniform vec4 color;

void main()
{
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    imageStore(dest, pos, color);
}

