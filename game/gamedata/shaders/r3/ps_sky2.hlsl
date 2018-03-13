#include "common.h"

struct         v2p
{
	float4	factor	: COLOR0;        // for SM3 - factor.rgb - tonemap-prescaled
	float3	tc0		: TEXCOORD0;
	float3	tc1		: TEXCOORD1;
};
struct        _out
{
	float4	low		: SV_Target0;
	float4	high	: SV_Target1;
};


TextureCube	s_sky0	:register(t0);
TextureCube	s_sky1	:register(t1);

//////////////////////////////////////////////////////////////////////////////////////////
// Pixel
_out main( v2p I )
{
//        float3         	s0  	= texCUBE        (s_sky0,I.tc0);
//        float3         	s1      = texCUBE        (s_sky1,I.tc1);
	float3	s0		= s_sky0.Sample( smp_rtlinear, I.tc0 );
	float3	s1		= s_sky1.Sample( smp_rtlinear, I.tc1 );
	float3	sky		= I.factor*lerp( s0, s1, I.factor.w );
			sky		*= 0.33f;

	// final tone-mapping
	_out			o;

	o.low        	=		sky.xyzz		;
	o.high        	=		o.low/def_hdr	;

	return        	o;
}
