#ifndef SLOAD_H
#define SLOAD_H

#include "common.h"

#ifdef	MSAA_ALPHATEST_DX10_1
#if MSAA_SAMPLES == 2
static const float2 MSAAOffsets[2] = { float2(4,4), float2(-4,-4) };
#endif
#if MSAA_SAMPLES == 4
static const float2 MSAAOffsets[4] = { float2(-2,-6), float2(6,-2), float2(-6,2), float2(2,6) };
#endif
#if MSAA_SAMPLES == 8
static const float2 MSAAOffsets[8] = { float2(1,-3), float2(-1,3), float2(5,1), float2(-3,-5), 
								               float2(-5,5), float2(-7,-1), float2(3,7), float2(7,-7) };
#endif
#endif	//	MSAA_ALPHATEST_DX10_1

//////////////////////////////////////////////////////////////////////////////////////////
// Bumped surface loader                //
//////////////////////////////////////////////////////////////////////////////////////////
struct	surface_bumped
{
	float4	base;
	float3	normal;
	float	gloss;
	float	height;

};

float4 tbase( float2 tc )
{
   return	s_base.Sample( smp_base, tc);
}

#if defined(ALLOW_STEEPPARALLAX) && defined(USE_STEEPPARALLAX)

static const float fParallaxStartFade = 8.0f;
static const float fParallaxStopFade = 12.0f;
//TODO: Check if this is correct compared to other implemntations
void UpdateTC( inout p_bumped I)
{
	if (I.position.z < fParallaxStopFade)
	{
		const float maxSamples = 32;
		const float minSamples = 4; //Reverted: too expensive
		const float fParallaxOffset = -0.02;

		float3	 eye = mul (float3x3(I.M1.x, I.M2.x, I.M3.x,
									 I.M1.y, I.M2.y, I.M3.y,
									 I.M1.z, I.M2.z, I.M3.z), -I.position.xyz);

		eye = normalize(eye);
		
		//	Calculate number of steps
		float nNumSteps = lerp( maxSamples, minSamples, eye.z );

		float	fStepSize			= 1.0 / nNumSteps;
		float2	vDelta				= eye.xy * fParallaxOffset*1.2;
		float2	vTexOffsetPerStep	= fStepSize * vDelta;

		//	Prepare start data for cycle
		float2	vTexCurrentOffset	= I.tcdh;
		float2 vddx = ddx_coarse(I.tcdh);
		float2 vddy = ddy_coarse(I.tcdh);
		float	fCurrHeight			= 0.0;
		float	fCurrentBound		= 1.0;

		for( int i=0; i<nNumSteps; ++i )
		{
			if (fCurrHeight < fCurrentBound)
			{	
				vTexCurrentOffset += vTexOffsetPerStep;		
				fCurrHeight = s_bumpX.SampleGrad( smp_linear, vTexCurrentOffset.xy, vddx, vddy ).a; 
				fCurrentBound -= fStepSize;
			}
		}

		//	Reconstruct previouse step's data
		vTexCurrentOffset -= vTexOffsetPerStep;
		float fPrevHeight = s_bumpX.SampleGrad( smp_linear, vTexCurrentOffset.xy, vddx, vddy ).a;

		//	Smooth tc position between current and previouse step
		float	fDelta2 = ((fCurrentBound + fStepSize) - fPrevHeight);
		float	fDelta1 = (fCurrentBound - fCurrHeight);
		float	fParallaxAmount = (fCurrentBound * fDelta2 - (fCurrentBound + fStepSize) * fDelta1 ) / ( fDelta2 - fDelta1 );
		float	fParallaxFade 	= smoothstep(fParallaxStopFade, fParallaxStartFade, I.position.z);
		float2	vParallaxOffset = vDelta * ((1- fParallaxAmount )*fParallaxFade);
		float2	vTexCoord = I.tcdh + vParallaxOffset;
	
		//	Output the result
		I.tcdh = vTexCoord;

#if defined(USE_TDETAIL) && defined(USE_STEEPPARALLAX)
		I.tcdbump = vTexCoord * dt_params;
#endif
	}

}

#elif	defined(USE_PARALLAX) //This HAD to be a mistake, applied parallax twice to same surfaces //|| defined(USE_STEEPPARALLAX)

void UpdateTC( inout p_bumped I)
{
	float3	 eye = mul (float3x3(I.M1.x, I.M2.x, I.M3.x,
								 I.M1.y, I.M2.y, I.M3.y,
								 I.M1.z, I.M2.z, I.M3.z), -I.position.xyz);
		float2 vddx = ddx_coarse(I.tcdh);
		float2 vddy = ddy_coarse(I.tcdh);								 
	float	height	= s_bumpX.SampleGrad( smp_linear, I.tcdh, vddx, vddy).w;
			height	= height*(parallax.x) + (parallax.y);
	float2	new_tc  = I.tcdh + height * normalize(eye);	//

	//	Output the result
	I.tcdh	= new_tc;
}

#else	//	USE_PARALLAX

void UpdateTC( inout p_bumped I)
{
	;
}

#endif	//	USE_PARALLAX
//Suggestion: We could get rid of one of the two normals entirely
//if someone compiled higher-quality normal maps
//in DXT5_NM format (compatible with DX9 even)
//Currently, it uses TWO normal maps
//the normal, and the "normal error map"
//this isn't done in modern games as it isn't necessary anymore
//and then s_bumpX could be height, and then three free texture
//slots for anything you want
surface_bumped sload_i( p_bumped I)
{
	surface_bumped	S;
   
	UpdateTC(I);	//	All kinds of parallax are applied here.

	float4 	Nu	= s_bump.Sample( smp_base, I.tcdh );		// IN:	normal.gloss
	float4 	NuE	= s_bumpX.Sample( smp_base, I.tcdh);	// IN:	normal_error.height

	S.base		= tbase(I.tcdh);				//	IN:  rgb.a
	S.normal	= Nu.wzy + (NuE.xyz - 1.0f);	
	S.gloss		= Nu.x*Nu.x;					//	S.gloss = Nu.x*Nu.x;
	S.height	= NuE.z;
	//S.height	= 0;

#ifdef        USE_TDETAIL
#ifdef        USE_TDETAIL_BUMP
	float4 NDetail		= s_detailBump.Sample( smp_base, I.tcdbump);
	float4 NDetailX		= s_detailBumpX.Sample( smp_base, I.tcdbump);
	S.gloss				= S.gloss * NDetail.x * 2;
	//S.normal			+= NDetail.wzy-.5;
	S.normal			+= NDetail.wzy + NDetailX.xyz - 1.0h; //	(Nu.wzyx - .5h) + (E-.5)

	float4 detail		= s_detail.Sample( smp_base, I.tcdbump);
	S.base.rgb			= S.base.rgb * detail.rgb * 2;

//	S.base.rgb			= float3(1,0,0);
#else        //	USE_TDETAIL_BUMP
	float4 detail		= s_detail.Sample( smp_base, I.tcdbump);
	S.base.rgb			= S.base.rgb * detail.rgb * 2;
	S.gloss				= S.gloss * detail.w * 2;
#endif        //	USE_TDETAIL_BUMP
#endif

	return S;
}

surface_bumped sload_i( p_bumped I, float2 pixeloffset )
{
	surface_bumped	S;
   
   // apply offset
#ifdef	MSAA_ALPHATEST_DX10_1
   I.tcdh.xy += pixeloffset.x * ddx(I.tcdh.xy) + pixeloffset.y * ddy(I.tcdh.xy);
#endif

	UpdateTC(I);	//	All kinds of parallax are applied here.

	float4 	Nu	= s_bump.Sample( smp_base, I.tcdh );		// IN:	normal.gloss
	float4 	NuE	= s_bumpX.Sample( smp_base, I.tcdh);	// IN:	normal_error.height

	S.base		= tbase(I.tcdh);				//	IN:  rgb.a
	S.normal	= Nu.wzyx + (NuE.xyz - 1.0f);	//	(Nu.wzyx - .5h) + (E-.5)
	S.gloss		= Nu.x*Nu.x;					//	S.gloss = Nu.x*Nu.x;
	S.height	= NuE.z;
	//S.height	= 0;

#ifdef        USE_TDETAIL
#ifdef        USE_TDETAIL_BUMP
#ifdef MSAA_ALPHATEST_DX10_1
#if ( (!defined(ALLOW_STEEPPARALLAX) ) && defined(USE_STEEPPARALLAX) )
   I.tcdbump.xy += pixeloffset.x * ddx(I.tcdbump.xy) + pixeloffset.y * ddy(I.tcdbump.xy);
#endif
#endif

	float4 NDetail		= s_detailBump.Sample( smp_base, I.tcdbump);
	float4 NDetailX		= s_detailBumpX.Sample( smp_base, I.tcdbump);
	S.gloss				= S.gloss * NDetail.x * 2;
	//S.normal			+= NDetail.wzy-.5;
	S.normal			+= NDetail.wzy + NDetailX.xyz - 1.0h; //	(Nu.wzyx - .5h) + (E-.5)

	float4 detail		= s_detail.Sample( smp_base, I.tcdbump);
	S.base.rgb			= S.base.rgb * detail.rgb * 2;

//	S.base.rgb			= float3(1,0,0);
#else        //	USE_TDETAIL_BUMP
#ifdef MSAA_ALPHATEST_DX10_1
   I.tcdbump.xy += pixeloffset.x * ddx(I.tcdbump.xy) + pixeloffset.y * ddy(I.tcdbump.xy);
#endif
	float4 detail		= s_detail.Sample( smp_base, I.tcdbump);
	S.base.rgb			= S.base.rgb * detail.rgb * 2;
	S.gloss				= S.gloss * detail.w * 2;
#endif        //	USE_TDETAIL_BUMP
#endif

	return S;
}

surface_bumped sload(p_bumped I)
{
	surface_bumped S	= sload_i(I);
	//S.normal.z		   *= -1.0;		//. make bump twice as contrast (fake, remove me if possible)
	S.height 			= 0;
	return S;
}

surface_bumped sload(p_bumped I, float2 pixeloffset)
{
	surface_bumped S	= sload_i(I, pixeloffset);
	//S.normal.z		   *= -1.0;		//. make bump twice as contrast (fake, remove me if possible)
	S.height 			= 0;
	return S;
}
#endif
