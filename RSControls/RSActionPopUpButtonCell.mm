/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSActionPopUpButtonCell.mm $
 * $Revision: #6 $
 * $Author: twenty3 $
 * $Date: 2006/10/22 $
 *
 * Created by 23 on 10/17/06.
 *
 * Description: NSPopUpButtonCell subclass that draws a pulldown with a gradient
 *				background that matches style of buttons used in Mail
 *              Uses gear icon that common to action menus by default
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

#import "RSActionPopUpButtonCell.h"

#import "RSLinearAxialShading.h"

@implementation RSActionPopUpButtonCell

- (void) initializeShading
{
	fShading =
		[ [ RSLinearAxialShading alloc ]
				initWithColor1:[ NSColor whiteColor ]
						color2:[ NSColor colorWithDeviceWhite:0.95 alpha:1.0 ] ];	
}

- (id) initTextCell:(NSString*)string pullsDown:(BOOL)pullDown
{
	//----- we always init to a pullDown
	
	self = [ super initTextCell:string pullsDown:YES ];
	[ self setBezelStyle:NSShadowlessSquareBezelStyle ];

	fFillColor				= [ [ NSColor colorWithCalibratedWhite:0.9 alpha:1.0 ] retain ];
	fBorderColor			= [ [ NSColor colorWithCalibratedWhite:0.8 alpha:1.0 ] retain ];
	fHighlightBorderColor	= [ [ NSColor colorWithCalibratedWhite:0.5 alpha:1.0 ] retain ];

	[ self initializeShading ];
	
	return self;
}

- (void) dealloc
{
	[ fShading release ];
	[ fFillColor release ];
	[ fBorderColor release ];
	[ fHighlightBorderColor release ];
	[ fPressedImage release ];
	
	[super dealloc];
}

- (NSImage*) pressedImage
{
	return fPressedImage;
}

- (void) setPressedImage:(NSImage*)image
{
	if ( image == fPressedImage )
		return;
		
	[ fPressedImage release ];
	fPressedImage = [ image retain ];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [ super initWithCoder:decoder ];
	
	fFillColor				= [ [ decoder decodeObjectForKey:@"fFillColor" ] retain ];
	fBorderColor			= [ [ decoder decodeObjectForKey:@"fBorderColor" ] retain ];
	fHighlightBorderColor	= [ [ decoder decodeObjectForKey:@"fHighlightBorderColor" ] retain ];
	
	NSData*	pressedImageData	= [ decoder decodeObjectForKey:@"PressedImageData" ];
	
	if ( pressedImageData )
	{
		NSBitmapImageRep* tiffRep = [ [ [ NSBitmapImageRep alloc ] initWithData:pressedImageData ] autorelease ];
		fPressedImage = [ [ NSImage alloc ] initWithSize:[ tiffRep size ] ];
		[ fPressedImage addRepresentation:tiffRep ];
	}
	else
	{
		fPressedImage = nil;
	}
	
	NSData* buttonImageData	= [ decoder decodeObjectForKey:@"ButtonImageData" ];
	if ( buttonImageData )
	{
		NSBitmapImageRep* tiffRep = [ [ [ NSBitmapImageRep alloc ] initWithData:buttonImageData ] autorelease ];
		NSImage* buttonImage = [ [ [ NSImage alloc ] initWithSize:[ tiffRep size ] ] autorelease ];
		[ buttonImage addRepresentation:tiffRep ];
		
		[ [ self itemAtIndex:0 ] setImage:buttonImage ];
	}
	
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
	[ encoder encodeObject:fHighlightBorderColor forKey:@"fHighlightBorderColor" ];
	
	//----- encode the pressed image bitmap so the image file does not have
	//      to be copied to the host applications resources
	//      this allows using the default images without having to copy them
	//      over to the host applications project when using this control
	//      from the IBPalette and framework
	
	[ encoder encodeObject:[fPressedImage TIFFRepresentation] forKey:@"PressedImageData" ];
	
	//----- Do the same for any image on the first menu item so we can capture
	//      the default gear icon provided by the palette or even another image
	//      set in Interface Builder
	NSImage* buttonImage = [ [ self itemAtIndex:0 ] image ]; 
	if ( buttonImage )
	{
		[ encoder encodeObject:[ buttonImage TIFFRepresentation ] forKey:@"ButtonImageData" ];
	}
}

#pragma mark Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ( [ self bezelStyle ] == NSShadowlessSquareBezelStyle )
	{
		//---- fill the background
		
		[ fFillColor set ];
		[ NSBezierPath fillRect:cellFrame ];
		
		NSPoint startPoint	= NSMakePoint( NSMidX( cellFrame ), NSMinY( cellFrame ) );
		NSPoint	endPoint	= NSMakePoint( NSMidX( cellFrame ), NSMidY( cellFrame ) );
		[ fShading drawFromPoint:startPoint toPoint:endPoint ];		

		if ( [ self isHighlighted ] )
		{
			[ [ NSColor colorWithDeviceWhite:0.0 alpha:0.35 ] set ];
			[ NSBezierPath fillRect:cellFrame ];
		}			
		
		//---- draw the border
		
		if ( ![ self isHighlighted ] )
			[ fBorderColor set ];
		else
			[ fHighlightBorderColor set ];
		
		NSFrameRect( cellFrame );
		
		//----- draw the interior context ( title, image, etc )
		
		[ self drawInteriorWithFrame:cellFrame inView:controlView ];
	}
	else
	{
		[ super drawWithFrame:cellFrame inView:controlView ];
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	//----- draw our image centered
	
	NSImage* image;
	
	if ( [ self isHighlighted ] && fPressedImage )
	{
		image = fPressedImage;
	}
	else
	{
		image = [ self image ];
	}
	
	NSRect		sourceRect		= NSMakeRect( 0.0, 0.0, [ image size ].width ,[ image size ].height);
	NSRect		destRect		= sourceRect;
	NSRect		controlBounds	= [ controlView bounds ];
	
	NSGraphicsContext* context = [ NSGraphicsContext currentContext ];
	[ context saveGraphicsState ];
	
	if ( [ controlView isFlipped ] )
	{
		NSAffineTransform* flipTransform = [ NSAffineTransform transform ];
		[ flipTransform translateXBy:0.0 yBy:NSMaxY(controlBounds) ];
		[ flipTransform scaleXBy:1.0 yBy:-1.0 ];
		[ flipTransform concat ];
	}
	
	destRect.origin.x = floor( ( controlBounds.size.width - sourceRect.size.width ) / 2.0 );
	destRect.origin.y = floor( ( controlBounds.size.height - sourceRect.size.height ) / 2.0 );
		
	[ image drawInRect:destRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0 ];

	[ context restoreGraphicsState ];
}

@end
