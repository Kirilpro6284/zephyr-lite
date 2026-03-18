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

    uniform sampler2D colortex12;
    uniform sampler2D colortex11;
    uniform sampler2D colortex10;
    uniform sampler2D colortex7;
    uniform sampler2D colortex6;
    uniform sampler2D colortex5;
    uniform sampler2D colortex3;
    uniform sampler2D colortex1;

    uniform sampler2D vxDepthTexOpaque;

    uniform sampler2D depthtex1;

    uniform vec4 lodProjMat_0;
    uniform vec4 lodProjMat_1;
    uniform vec4 lodProjMat_2;
    uniform vec4 lodProjMat_3;

    uniform vec4 lodProjMatPrev_0;
    uniform vec4 lodProjMatPrev_1;
    uniform vec4 lodProjMatPrev_2;
    uniform vec4 lodProjMatPrev_3;

    uniform vec4 lodProjMatInv_0;
    uniform vec4 lodProjMatInv_1;
    uniform vec4 lodProjMatInv_2;
    uniform vec4 lodProjMatInv_3;

    #define lodProjMat0 mat4( \
        lodProjMat_0, \
        lodProjMat_1, \
        lodProjMat_2, \
        lodProjMat_3 \
    )

    #define lodProjMatPrev0 mat4( \
        lodProjMatPrev_0, \
        lodProjMatPrev_1, \
        lodProjMatPrev_2, \
        lodProjMatPrev_3 \
    )

    #define lodProjMatInv0 mat4( \
        lodProjMatInv_0, \
        lodProjMatInv_1, \
        lodProjMatInv_2, \
        lodProjMatInv_3 \
    )

    uniform mat4 gbufferPreviousProjection;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 shadowModelViewInverse;
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelView;
    uniform mat4 shadowModelView;
    
    uniform mat4 vxViewProjInv;
    uniform mat4 vxProjInv;

    uniform vec3 shadowDir;
    uniform vec3 moonDir;
    uniform vec3 sunDir;

    uniform vec3 cameraPositionFract;
    uniform vec3 playerLookVector;
    uniform vec3 cameraVelocity;

    uniform vec2 internalScreenSize;
    uniform vec2 internalTexelSize;
    uniform vec2 taa_offset_prev;
    uniform vec2 taa_offset;
    uniform vec2 screenSize;
    uniform vec2 texelSize; 

    uniform float shadowLightBrightness;
    uniform float eyeAltitude;
    uniform float near;

    uniform ivec3 previousCameraPositionInt;
    uniform ivec3 cameraPositionInt;

    #ifdef VOXY
        uniform int vxRenderDistance;
    #endif

    uniform int frameCounter;
    uniform int renderStage;

    uniform bool hideGUI;

    #define lodDepthTex1 colortex11

#endif