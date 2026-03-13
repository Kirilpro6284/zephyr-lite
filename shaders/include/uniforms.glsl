#ifndef INCLUDE_UNIFORMS
    #define INCLUDE_UNIFORMS

    layout (std430, binding = 0) buffer render_state
    {
        float averageLuminance;
    } renderState;

    layout (r8ui) uniform uimage3D voxelBuffer;
    layout (rgba8) uniform image3D lightBuffer;
    layout (rgba8) uniform image2D imgScattering;

    uniform usampler3D voxelSampler;
    uniform sampler3D lightSampler;
    uniform sampler2D scattering;

    uniform sampler3D depthtex2;
    uniform sampler3D noisetex;

    uniform sampler2D specular;
    uniform sampler2D gtexture;
    uniform sampler2D normals;

    uniform sampler2DShadow shadowtex1HW;
    uniform sampler2DShadow shadowtex0HW;

    uniform sampler2D shadowcolor1;
    uniform sampler2D shadowcolor0;
    uniform sampler2D shadowtex1;
    uniform sampler2D shadowtex0;

    uniform usampler2D colortex9;
    uniform usampler2D colortex8;

    uniform sampler2D colortex11;
    uniform sampler2D colortex10;
    uniform sampler2D colortex7;
    uniform sampler2D colortex6;
    uniform sampler2D colortex1;

    uniform sampler2D vxDepthTexOpaque;

    uniform sampler2D depthtex1;

    uniform mat4 gbufferPreviousProjection;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 shadowModelViewInverse;
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelView;
    uniform mat4 shadowModelView;
    
    uniform mat4 vxViewProjInv;

    uniform vec3 shadowDir;
    uniform vec3 moonDir;
    uniform vec3 sunDir;

    uniform vec3 cameraPositionFract;
    uniform vec3 playerLookVector;
    uniform vec3 cameraVelocity;

	uniform vec2 depthLinearizationConst;
    uniform vec2 internalScreenSize;
    uniform vec2 internalTexelSize;
    uniform vec2 taa_offset_prev;
    uniform vec2 taa_offset;
    uniform vec2 screenSize;
    uniform vec2 texelSize; 

    uniform float eyeAltitude;

    uniform ivec3 previousCameraPositionInt;
    uniform ivec3 cameraPositionInt;

    uniform int frameCounter;
    uniform int renderStage;

    uniform bool hideGUI;

#endif