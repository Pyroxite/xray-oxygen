#include "common.h"

uniform half3x4                        m_v2w                ;
uniform	sampler2D	s_half_depth;

#include "ps_ssao_blur.hlsl"
#include "ps_ssao.hlsl"
#include "ps_ssao_hbao.hlsl"

struct	_input
{
	float4	hpos : POSITION;
#ifdef        USE_VTF
	float4	tc0  : TEXCOORD0;		// tc.xy, tc.w = tonemap scale
#else
	float2	tc0  : TEXCOORD0;		// tc.xy
#endif
	float2	tcJ	 : TEXCOORD1;		// jitter coords
};

struct	v2p
{
	float2	tc0 : TEXCOORD0;
	float2	tc1 : TEXCOORD1;
};

float4	main(_input I) : COLOR0
{
        float4 	P	= tex2D         (s_position,      I.tc0);                // position.(mtl or sun)
        float4 	N	= tex2D         (s_normal,        I.tc0);                // normal.hemi
#ifndef USE_HBAO
        float	o	= calc_ssao(P, N, I.tc0, I.tcJ);
#else
		//	NOw is not supported
		float   o   = 1.0f;//hbao_calc(P, N, I.tc0.xy, I.hpos);
#endif
        return  float4(o, P.z, 0, 0);
}
