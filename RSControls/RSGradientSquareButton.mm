/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSGradientSquareButton.mm $
 * $Revision: #3 $
 * $Author: twenty3 $
 * $Date: 2006/10/22 $
 *
 * Created by 23 on 10/16/06.
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

#import "RSGradientSquareButton.h"

#import "RSGradientSquareButtonCell.h"

@implementation RSGradientSquareButton

+ (Class) cellClass
{
	return [ RSGradientSquareButtonCell class ];
}

- (BOOL) mouseInThumb:(NSPoint) aPoint
{
	RSGradientSquareButtonCell* cell = [ self cell ];
	
	if ( ![ cell hasThumb ] )
		return NO;
	
	NSRect thumbRect = [ cell thumbRectForBounds:[self bounds] ];
	
	return NSMouseInRect( aPoint, thumbRect, [ self isFlipped ] );
}

#pragma mark Accessors

- (BOOL) hasThumb
{
	return [ [ self cell ] hasThumb ];
}

- (void) setHasThumb:(BOOL)hasThumb
{
	[ [ self cell ] setHasThumb:hasThumb ];	
}

#pragma mark IBPalette
// It would be better to have IBPalette support methods added
// via category, but it appears that does not work in this case.
// I suspect it is because we are a sublcass of NSButton, which
// already implements this method directly or has it added by a category as well

- (NSString *)inspectorClassName
{
    return @"RSGradientSquareButtonInspector";
}


@end
