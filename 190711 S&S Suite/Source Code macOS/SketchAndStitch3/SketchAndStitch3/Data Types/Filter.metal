#include <metal_stdlib>
using namespace metal;

struct FilterParameters {
    float minR;
    float minG;
    float minB;
    float maxR;
    float maxG;
    float maxB;
};

struct ColorParameters {
    float R;
    float G;
    float B;
};


kernel void filter_rgb(constant FilterParameters *params [[ buffer(0) ]],
                       texture2d<half, access::read> inTexture [[ texture(0) ]],
                       texture2d<half, access::read_write> outTexture [[ texture(1) ]],
                       uint2 gid [[ thread_position_in_grid ]]) {
    
    half4 color = inTexture.read(gid).rgba;
    
    float minR = params->minR;
    float minG = params->minG;
    float minB = params->minB;
    
    float maxR = params->maxR;
    float maxG = params->maxG;
    float maxB = params->maxB;
    
    if(color.r < minR or color.g < minG or color.b < minB or color.r > maxR or color.g > maxG or color.b > maxB){
        outTexture.write(half4(0, 0, 0, 0), gid);
    } else{
        outTexture.write(half4(color.r, color.g, color.b, color.a), gid);
    }
    
}

kernel void colorize_rgb(constant ColorParameters *params [[ buffer(0) ]],
                         texture2d<half, access::read> inTexture [[ texture(0) ]],
                         texture2d<half, access::read_write> outTexture [[ texture(1) ]],
                         uint2 gid [[ thread_position_in_grid ]]) {
    
    half4 color = inTexture.read(gid).rgba;
    
    float R = params->R;
    float G = params->G;
    float B = params->B;
    
    outTexture.write(half4(R, G, B, color.a), gid);
    
}
