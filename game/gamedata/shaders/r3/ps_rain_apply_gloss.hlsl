#include "common.h"
#include "lmodel.h"
//#include "shadow.h"

#ifndef ISAMPLE
#define ISAMPLE 0
#endif

#ifndef USE_MSAA
Texture2D	s_patched_normal;
#else
Texture2DMS< float4, MSAA_SAMPLES >	s_patched_normal;
#endif

#ifdef MSAA_OPTIMIZATION
float4 main ( float2 tc : TEXCOORD0, float2 tcJ : TEXCOORD1, uint iSample : SV_SAMPLEINDEX ) : SV_Target
#else
float4 main ( float2 tc : TEXCOORD0, float2 tcJ : TEXCOORD1 ) : SV_Target
#endif
{
#ifndef USE_MSAA
	float Gloss = s_patched_normal.Sample( smp_nofilter, tc ).a;
#else
#ifndef MSAA_OPTIMIZATION
	float Gloss = s_patched_normal.Load(int3( tc * pos_decompression_params2.xy, 0 ), ISAMPLE ).a;
#else
	float Gloss = s_patched_normal.Load(int3( tc * pos_decompression_params2.xy, 0 ), iSample).a;
#endif	
#endif

//	float ColorIntencity = 1 - Gloss*0.5;

	float ColorIntencity = 1 - sqrt(Gloss);

//	ColorIntencity = max (ColorIntencity, 0.75);
	ColorIntencity = max (ColorIntencity, 0.5);

//	float ColorIntencity = (Gloss-0.1)/(Gloss+0.00001);

//	ColorIntencity = min (ColorIntencity, 1);

	//return float4(1,1,1,Gloss);
	return float4( ColorIntencity, ColorIntencity, ColorIntencity, Gloss*0.8);
}
