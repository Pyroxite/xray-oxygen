#include "common.h"

//	Igor: used for volumetric light
#ifndef USE_MSAA
Texture2D 							s_vollight;
#else
Texture2DMS<float4, MSAA_SAMPLES>	s_vollight;
#endif

struct	_input      
{
	float4	tc0	: TEXCOORD0;	// tc.xy, tc.w = tonemap scale
};

struct	_out
{
        float4	low		: SV_Target0;
        float4	high	: SV_Target1;
};

//	TODO: DX10: Use load instead of sample
_out main( _input I )
{
	// final tone-mapping
	float          	tm_scale        = I.tc0.w;	// interpolated from VS

	_out	o;
	float4	color;

#ifndef USE_MSAA
	color = s_vollight.Load(int3(I.tc0.xy*pos_decompression_params2.xy, 0));
#else // USE_MSAA
	color = s_vollight.Load(int3(I.tc0.xy*pos_decompression_params2.xy, 0), 0);
	[unroll] for(int iSample = 1; iSample < MSAA_SAMPLES; ++iSample)
	{
		color	+= s_vollight.Load(int3(I.tc0*pos_decompression_params2.xy, 0), iSample);
	}
	color /= MSAA_SAMPLES;
#endif // USE_MSAA

	tonemap(o.low, o.high, color, tm_scale );

	return o;
}
