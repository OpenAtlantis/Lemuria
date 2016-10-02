/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSLinearAxialShading.mm $
 * $Revision: #2 $
 * $Author: twenty3 $
 * $Date: 2006/10/22 $
 *
 * Created by Jeff Argast on 9/27/06.
 *
 * Description:
 *
 **************************************************************************************/
/*
Copyright (c) 2006 RogueSheep Incorporated 

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions: The above copyright notice and this permission
notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "RSLinearAxialShading.h"

//
// For the CGShadings
//

static void RSLinearColorBlendFunction (void *info, const float *in, float *out);

static const CGFunctionCallbacks kRSLinearFunctionCallbacks = { 0, &RSLinearColorBlendFunction, nil };

//////////////////////////////////////////////////////////////////////////////
// RSLinearAxialShading
//////////////////////////////////////////////////////////////////////////////

@implementation RSLinearAxialShading

- (id) initWithColor1: (NSColor*) color1 color2: (NSColor*) color2
{
    self = [super init];
	
    if ( self ) 
	{
		//
		// We need the device colorspace versions to get the components
		//
		
		NSColor* deviceColor1 = [color1 colorUsingColorSpaceName: NSDeviceRGBColorSpace];
		NSColor* deviceColor2 = [color2 colorUsingColorSpaceName: NSDeviceRGBColorSpace];
		
		//
		// Now get the components
		//

		[deviceColor1 getRed: &fColors.fColor1.fRed 
					   green: &fColors.fColor1.fGreen
					    blue: &fColors.fColor1.fBlue
					   alpha: &fColors.fColor1.fAlpha];

		[deviceColor2 getRed: &fColors.fColor2.fRed 
					   green: &fColors.fColor2.fGreen
					    blue: &fColors.fColor2.fBlue
					   alpha: &fColors.fColor2.fAlpha];

		static const float domainAndRange[8] = { 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0 };
		
		fBlendFunctionRef	= CGFunctionCreate ( &fColors, 1, domainAndRange, 4, domainAndRange, &kRSLinearFunctionCallbacks);
		fColorSpaceRef		= CGColorSpaceCreateDeviceRGB();
    }

    return self;
}

- (void) dealloc
{
	CGFunctionRelease ( fBlendFunctionRef );
	CGColorSpaceRelease ( fColorSpaceRef );
	
	[super dealloc];
}

- (void) drawFromPoint: (NSPoint) fromPoint toPoint: (NSPoint) toPoint
{
	CGContextRef context	= (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];

	CGPoint cgFromPoint		= CGPointMake ( fromPoint.x, fromPoint.y );
	CGPoint cgToPoint		= CGPointMake ( toPoint.x, toPoint.y );
	
	CGShadingRef cgShading	= CGShadingCreateAxial ( fColorSpaceRef, cgFromPoint, cgToPoint, fBlendFunctionRef, NO, NO );
	
	CGContextDrawShading ( context, cgShading );
	
	CGShadingRelease ( cgShading );
}

@end

//////////////////////////////////////////////////////////////////////////////
// RSLinearColorBlendFunction
//////////////////////////////////////////////////////////////////////////////

void RSLinearColorBlendFunction (void *info, const float *in, float *out)
{
	RSAxialColors* colors = (RSAxialColors *)info;
	
	//
	// There is only a single input
	//
	
	float inVal= in[0];
	
	out[0] = (1.0 - inVal) * colors->fColor1.fRed	+ inVal * colors->fColor2.fRed;
	out[1] = (1.0 - inVal) * colors->fColor1.fGreen	+ inVal * colors->fColor2.fGreen;
	out[2] = (1.0 - inVal) * colors->fColor1.fBlue	+ inVal * colors->fColor2.fBlue;
	out[3] = (1.0 - inVal) * colors->fColor1.fAlpha	+ inVal * colors->fColor2.fAlpha;
}
