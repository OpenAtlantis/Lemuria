/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSActionPopUpButtonCell.h $
 * $Revision: #4 $
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

#import <Cocoa/Cocoa.h>

@class RSLinearAxialShading;

@interface RSActionPopUpButtonCell : NSPopUpButtonCell 
{
	RSLinearAxialShading*			fShading;
	
	NSColor*						fFillColor;
	NSColor*						fBorderColor;
	NSColor*						fHighlightBorderColor;
	
	NSImage*						fPressedImage;
}

- (NSImage*) pressedImage;
- (void) setPressedImage:(NSImage*)image;
	// pressedImage is an optional image to use when drawing the highlighted
	// or pressed-in pop-up cell state
	
@end
