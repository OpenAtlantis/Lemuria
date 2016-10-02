/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSGradientSquareButtonCell.mm $
 * $Revision: #5 $
 * $Author: twenty3 $
 * $Date: 2006/10/22 $
 *
 * Created by 23 on 10/16/06.
 *
 * Description: NSButtonCell subclass that draws a square button with a gradient
 *				background that matches style of buttons used in Mail
 *              similar to 'Small Square Button' or NSSmallSquareBezelStyle 
 *              but also works in 10.3
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

#import "RSGradientSquareButtonCell.h"
#import "RSLinearAxialShading.h"

@implementation RSGradientSquareButtonCell

- (void) initializeShading
{
	fShading =
		[ [ RSLinearAxialShading alloc ] initWithColor1:[ NSColor whiteColor ]
												 color2:[ NSColor colorWithDeviceWhite:0.95
												                                alpha:1.0 ] ];	
}

- (id)initImageCell:(NSImage *)anImage
{
	return [ super initImageCell:anImage ];
}

- (id)initTextCell:(NSString*)title
{
	self = [ super initTextCell:title ];
	
	[ self setBezelStyle:NSRegularSquareBezelStyle ];
	
	fFillColor		= [ [ NSColor colorWithCalibratedWhite:0.9 alpha:1.0 ] retain ];
	fBorderColor	= [ [ NSColor colorWithCalibratedWhite:0.8 alpha:1.0 ] retain ];
	fThumbColor		= [ [ NSColor colorWithCalibratedWhite:0.4 alpha:1.0 ] retain ];
	
	fThumbWidth		= 15.0;
	fThumbHeight	= 10.0;
	fHasThumb = YES;
	
	[ self initializeShading ];
	
	return self;
}

- (void) dealloc
{
	[ fShading release ];
	[ fFillColor release ];
	[ fBorderColor release ];
	
	[super dealloc];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [ super initWithCoder:decoder ];
	
	fFillColor		= [ [ decoder decodeObjectForKey:@"fFillColor" ] retain ];
	fBorderColor	= [ [ decoder decodeObjectForKey:@"fBorderColor" ] retain ];
	fThumbColor		= [ [ decoder decodeObjectForKey:@"fThumbColor" ] retain ];
	fThumbWidth		= [ decoder decodeFloatForKey:@"fThumbWidth" ];
	fThumbHeight	= [ decoder decodeFloatForKey:@"fThumbHeight" ];
	fHasThumb		= [ decoder decodeBoolForKey:@"fHasThumb" ];
	
	//----- shading is not currently NSCoding compliant so we recreate it when initializing from coder
	//      rather than serialize and unserialize
	
	[ self initializeShading ];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[ super encodeWithCoder:encoder ];
	[ encoder encodeObject:fFillColor forKey:@"fFillColor" ];
	[ encoder encodeObject:fBorderColor forKey:@"fBorderColor" ];
	[ encoder encodeObject:fThumbColor forKey:@"fThumbColor" ];
	[ encoder encodeFloat:fThumbWidth forKey:@"fThumbWidth" ];
	[ encoder encodeFloat:fThumbHeight forKey:@"fThumbHeight" ];
	[ encoder encodeBool:fHasThumb forKey:@"fHasThumb" ];

}

- (NSRect) thumbRectForBounds:(NSRect)boundsRect
{
	if ( !fHasThumb )
		return NSZeroRect;
	
	return NSMakeRect( NSMaxX( boundsRect ) - fThumbWidth,
					   boundsRect.origin.y,
					   fThumbWidth,
					   boundsRect.size.height );
}

#pragma mark Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ( [ self bezelStyle ] == NSRegularSquareBezelStyle )
	{
		//---- fill the background
				
		[ fFillColor set ];
		[ NSBezierPath fillRect:cellFrame ];
		
		NSPoint startPoint	= NSMakePoint( NSMidX( cellFrame ), NSMinY( cellFrame ) );
		NSPoint	endPoint	= NSMakePoint( NSMidX( cellFrame ), NSMidY( cellFrame ) );
		[ fShading drawFromPoint:startPoint toPoint:endPoint ];		
		
		//---- draw the border
		
		[ fBorderColor set ];
		NSFrameRect( cellFrame );
		
		//----- draw the thumb
		
		if ( fHasThumb )
		{
			float offset	= ( fThumbWidth  - 7.0  ) / 2.0;
			float thumbX	= NSMaxX( cellFrame ) - 1.5 - offset; // half pixel for a sharp line, inset by 1 for border 
			float thumbY	= cellFrame.origin.y + ( ( cellFrame.size.height - fThumbHeight ) / 2.0 );

			[ fThumbColor set ];
			
			NSPoint thumbBottom	=	NSMakePoint( thumbX, thumbY );
			NSPoint thumbTop	=	NSMakePoint( thumbX, thumbY + fThumbHeight );
			
			[ NSBezierPath strokeLineFromPoint:thumbTop toPoint:thumbBottom ];
			
			thumbBottom.x -= 3.0;
			thumbTop.x -= 3.0;

			[ NSBezierPath strokeLineFromPoint:thumbTop toPoint:thumbBottom ];

			thumbBottom.x -= 3.0;
			thumbTop.x -= 3.0;
			
			[ NSBezierPath strokeLineFromPoint:thumbTop toPoint:thumbBottom ];
			
		}
		
		//----- draw the interior context ( title, image, etc )
		
		[ self drawInteriorWithFrame:cellFrame inView:controlView ];
	}
	else
	{
		[ super drawWithFrame:cellFrame inView:controlView ];
	}
}

#pragma mark Accessors

- (void) setHasThumb:(BOOL)hasThumb
{
	fHasThumb = hasThumb;
}

- (BOOL) hasThumb
{
	return fHasThumb;
}



@end
