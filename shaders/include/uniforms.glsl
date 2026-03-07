#ifndef INCLUDE_UNIFORMS
    #define INCLUDE_UNIFORMS

    uniform sampler2D specular;
    uniform sampler2D gtexture;

    uniform usampler2D colortex9;
    uniform usampler2D colortex8;

    uniform sampler2D colortex7;
    uniform sampler2D colortex6;
    uniform sampler2D colortex1;

    uniform sampler2D depthtex1;

    uniform mat4 gbufferPreviousProjection;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelView;

    uniform vec3 cameraVelocity;

    uniform vec2 internalScreenSize;
    uniform vec2 internalTexelSize;
    uniform vec2 taa_offset_prev;
    uniform vec2 taa_offset;
    uniform vec2 screenSize;
    uniform vec2 texelSize; 
    
   

#endif