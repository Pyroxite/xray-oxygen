//	Allow dynamic branching usage for HW PCF support
#ifdef	USE_HWSMAP_PCF
#define SUNSHAFTS_DYNAMIC
#endif	//	USE_HWSMAP_PCF

#include "common.h"
#include "shadow.h"

#define RAY_PATH	2.0h

//#define	JITTER_SUN_SHAFTS

#ifdef	SUN_SHAFTS_QUALITY
	#if SUN_SHAFTS_QUALITY==1
		#define	FILTER_LOW
		#define RAY_SAMPLES	20
	#elif SUN_SHAFTS_QUALITY==2
		#define RAY_SAMPLES	20
	#elif SUN_SHAFTS_QUALITY==3
		#define RAY_SAMPLES	40
	#endif
#endif

half4	volume_range;	//	x - near plane, y - far plane
half4	sun_shafts_intensity;

//#ifdef	USE_BRANCHING
//	"If" in loop
float4 	main (float2 tc : TEXCOORD0, float4 tcJ : TEXCOORD1 ) : COLOR
{
#ifndef	SUN_SHAFTS_QUALITY
	return half4(0,0,0,0);
#else	//	SUN_SHAFTS_QUALITY

	half3	P = tex2D(s_position, tc).xyz;
#ifndef	JITTER_SUN_SHAFTS
//	Fixed ray length, fixed step dencity
//	half3	direction = (RAY_PATH/RAY_SAMPLES)*normalize(P);	
//	Variable ray length, variable step dencity
	half3	direction = P/RAY_SAMPLES;
#else	//	JITTER_SUN_SHAFTS
//	Variable ray length, variable step dencity, use jittering
	half4	J0 	= tex2D		(jitter0,tcJ);
	half	coeff = (RAY_SAMPLES - 2*J0.x)/(RAY_SAMPLES*RAY_SAMPLES);		
	half3	direction = P*coeff;
//	half3	direction = P/(RAY_SAMPLES+(J0.x*4-2));
#endif	//	JITTER_SUN_SHAFTS

	half	depth = P.z;
	half	deltaDepth = direction.z;
	
	half4	current	= mul (m_shadow,float4(P,1));
	half4	delta 	= mul (m_shadow, float4(direction,0));

	half	res = 0;
	half	max_density = sun_shafts_intensity;
	half	density = max_density/RAY_SAMPLES;

	if (depth<0.0001)
		res = max_density;

	#ifndef SUNSHAFTS_DYNAMIC
	for ( int i=0; i<RAY_SAMPLES; ++i )
	{
		if (depth>0.3)
#ifndef	FILTER_LOW
				res += density*shadow(current);
#else	//	FILTER_LOW
				res += density*sample_hw_pcf(current, float4(0,0,0,0));
#endif	//	FILTER_LOW
		depth -= deltaDepth;
		current -= delta;
	}
	#else
	int n = (int)((P.z - 0.3) / deltaDepth);
	for ( int i=0; i<n; ++i )
	{		
#ifndef	FILTER_LOW
				res += density*shadow(current);
#else	//	FILTER_LOW
				res += density*sample_hw_pcf(current, float4(0,0,0,0));
#endif	//	FILTER_LOW
		depth -= deltaDepth;
		current -= delta;
	}
	#endif

	//	float fSturation = -dot(Ldynamic_dir, half3(0,0,1));
	float fSturation = -Ldynamic_dir.z;

	//	Normalize dot product to
	fSturation	= 0.5*fSturation+0.5;
	//	Map saturation to 0.2..1
	fSturation	= 0.80*fSturation+0.20;

	res		*= fSturation;

	return res*Ldynamic_color;
#endif	//	SUN_SHAFTS_QUALITY
}
