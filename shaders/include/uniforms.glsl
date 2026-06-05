
layout (r8ui) uniform uimage3D voxelBuffer;
layout (rgba8) uniform image3D lightBuffer;
layout (rgba8) uniform image2D imgSkyIrradiance;

uniform usampler3D voxelSampler;
uniform sampler3D lightSampler;
uniform sampler2D scattering;
uniform sampler2D transmittance;
uniform sampler2D skyIrradianceTex;

uniform sampler3D depthtex2;

uniform sampler2D noisetex0;
uniform sampler3D noisetex1;

uniform sampler2D specular;
uniform sampler2D gtexture;
uniform sampler2D normals;

uniform sampler2DShadow shadowtex1HW;
uniform sampler2DShadow shadowtex0HW;

uniform sampler2D shadowcolor1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowtex0;

uniform usampler2D colortex12;
uniform usampler2D colortex9;

uniform sampler2D colortex16;
uniform sampler2D colortex11;
uniform sampler2D colortex10;
uniform sampler2D colortex8;
uniform sampler2D colortex7;
uniform sampler2D colortex6;
uniform sampler2D colortex5;
uniform sampler2D colortex3;
uniform sampler2D colortex2;
uniform sampler2D colortex1;

uniform sampler2D lodDepthTex0;
uniform sampler2D lodDepthTex1;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform vec4 gbufferProjScale;
uniform vec4 gbufferProjScaleInv;
uniform vec4 gbufferProjScalePrev;
uniform vec4 gbufferProjScalePrevInv;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;

uniform vec3 shadowDir;
uniform vec3 moonDir;
uniform vec3 sunDir;

uniform vec3 cameraPosition;
uniform vec3 cameraPositionFract;
uniform vec3 cameraVelocity;

uniform vec3 playerLookVector;

uniform vec2 internalScreenSize;
uniform vec2 internalTexelSize;
uniform vec2 taa_offset_prev;
uniform vec2 taa_offset;
uniform vec2 screenSize;
uniform vec2 texelSize; 

uniform float shadowLightBrightness;
uniform float worldTimeErf;
uniform float worldAge;
uniform float eyeAltitude;
uniform float aspectRatio;
uniform float near;
uniform float far;

uniform ivec2 eyeBrightnessSmooth;

uniform ivec3 previousCameraPositionInt;
uniform ivec3 cameraPositionInt;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int renderStage;

uniform bool hideGUI;

uniform float frameTimeCounter;

uniform float viewDistance;

#ifdef VOXY
    uniform sampler2D vxDepthTexOpaque;
    uniform sampler2D vxDepthTexTrans;

    uniform mat4 vxViewProjInv;
    uniform mat4 vxProjInv;

    uniform int vxRenderDistance;
#endif