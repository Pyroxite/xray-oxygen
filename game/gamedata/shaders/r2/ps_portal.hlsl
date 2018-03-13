#include "common.h"

half4 	main	( half4 C:COLOR0 )	: COLOR
{
		half4	result;

#ifdef        USE_VTF
        result.rgb	= C;
#else
		half4	high;
        half    scale	= tex2D(s_tonemap,half2(.5h,.5h)).x;
//		tonemap			(result, high, C, scale*0.9);
		tonemap			(result, high, C, scale);
#endif

	result.a = C.a;

	return	result;
}
