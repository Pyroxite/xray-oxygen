#include "common.h"

#ifdef GBUFFER_OPTIMIZATION
float4 main ( float2 tc : TEXCOORD0, float2 tcJ : TEXCOORD1, float4 col: COLOR, float4 pos2d : SV_Position ) : SV_Target
#else
float4 main ( float2 tc : TEXCOORD0, float2 tcJ : TEXCOORD1, float4 col: COLOR ) : SV_Target
#endif
{
#if MSAA_SAMPLES

#ifdef GBUFFER_OPTIMIZATION
	gbuffer_data gbd0 = gbuffer_load_data( tc, pos2d, 0 );
#else
	gbuffer_data gbd0 = gbuffer_load_data( tc, 0 );
#endif
	float3 P0 = gbd0.P;
	float3 N0 = gbd0.N;
	
	float3 P = gbd0.P / float(MSAA_SAMPLES);
	float3 N = gbd0.N / float(MSAA_SAMPLES);

	[unroll] for( int i = 1; i < MSAA_SAMPLES; i++ )
	{
#ifdef GBUFFER_OPTIMIZATION
		gbuffer_data gbd = gbuffer_load_data( tc, pos2d, i );
#else
		gbuffer_data gbd = gbuffer_load_data( tc, i );
#endif
		P += gbd.P / float(MSAA_SAMPLES);
		N += gbd.N / float(MSAA_SAMPLES);
	}
	
	if (all(P==P0 && N==N0))
	   discard;

#endif // #if MSAA_SAMPLES
	return float4(0,0,0,0);
}
