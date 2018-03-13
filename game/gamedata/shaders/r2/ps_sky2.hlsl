#include "common.h"

struct         v2p
{
        half4        	factor:     COLOR0          ;        // for SM3 - factor.rgb - tonemap-prescaled
        half3        	tc0:        TEXCOORD0       ;
        half3        	tc1:        TEXCOORD1		;
};
struct        _out
{
        half4        	low: 		COLOR0;
        half4        	high:		COLOR1;
};


uniform samplerCUBE     s_sky0      : register(s0)	;
uniform samplerCUBE     s_sky1      : register(s1)	;

//////////////////////////////////////////////////////////////////////////////////////////
// Pixel
#if 1
_out         main               ( v2p I )
{
        half3         	s0  	= texCUBE        (s_sky0,I.tc0);
        half3         	s1      = texCUBE        (s_sky1,I.tc1);
        half3        	sky     = I.factor*lerp  (s0,s1,I.factor.w);
				sky		= sky*0.33;
        // final tone-mapping
        _out        	o;
#ifdef        USE_VTF
        o.low        	=		sky.xyzz		;
        o.high        	=		o.low/def_hdr	;
#else
        half    scale   = tex2D(s_tonemap,half2(.5h,.5h)).x;
        tonemap        	(o.low, o.high, sky, scale*2.0 );
#endif
        return        	o;
}
#else
_out         main               ( v2p I )
{
        half3         	s0  	= texCUBE        (s_sky0,I.tc0);
        half3         	s1      = texCUBE        (s_sky1,I.tc1);
        half3        	sky     = I.factor*lerp  (s0,s1,I.factor.w);

        // final tone-mapping
        _out        	o;
        half    scale   = 1 + tex2D(s_tonemap,half2(.5h,.5h)).x;
				sky		= sky*scale*2.0f		;
        o.low        	= sky.xyzz        	;
        o.high        	= o.low/def_hdr     ;
        return        	o;
}
#endif
