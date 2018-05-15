/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSLinearAxialShading.h $
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

#import <Cocoa/Cocoa.h>

typedef struct
{
	double	fRed;
	double	fGreen;
	double	fBlue;
	double	fAlpha;
} RSAxialColorValues;

typedef struct
{
	RSAxialColorValues	fColor1;
	RSAxialColorValues	fColor2;
} RSAxialColors;

@interface RSLinearAxialShading : NSObject 
{
	RSAxialColors	fColors;
	CGFunctionRef	fBlendFunctionRef;
	CGColorSpaceRef	fColorSpaceRef;
}

- (id) initWithColor1: (NSColor*) color1 color2: (NSColor*) color2;
// Creates a linear blend shading from color1 to color2

- (void) drawFromPoint: (NSPoint) fromPoint toPoint: (NSPoint) toPoint;
// Draw the axial gradient fromPoint toPoint

@end
