/**************************************************************************************
 * Copyright (c) 2006 RogueSheep Incorporated. All rights reserved.
 *
 * $File: //RogueSheep/RSControls/RSStepperButton.mm $
 * $Revision: #4 $
 * $Author: twenty3 $
 * $Date: 2006/10/22 $
 *
 * Created by 23 on 07/20/06.
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

#import "RSStepperButton.h"

@implementation RSStepperButton

- (void) dealloc
{
	[ fObservedObjectForValue release ];
	[ fObservedKeyPathForValue release ];
	
	[super dealloc];
}


- (void) configure
{
	//----- setup the normal NSButton attributes like we want them

	[ self setBezelStyle:NSRoundedBezelStyle ];
	[ self setButtonType:NSMomentaryChangeButton ];
	[ self setBordered:NO ];
	[ self setImagePosition:NSImageAbove ];
}

- (void) updateValue;
{
	float f = fValue + fIncrement;
	
	if ( f > fMaximum )
	{
		f = fWraps ? fMinimum : fMaximum;
	}
	else if ( f < fMinimum )
	{
		f = fWraps ? fMaximum : fMinimum;
	}
		
	NSNumber* newValue = [ NSNumber numberWithFloat:f ];
	[ self setValue:newValue forKey:@"value" ];
	
	//----- if we are bound to something, update it to the new value as well
	
	[ fObservedObjectForValue setValue:newValue forKeyPath:fObservedKeyPathForValue ];	
}


- (void) setObjectObserveredForValue:(id)observableObject withKeyPath:(NSString*)keyPath;
{
	if ( fObservedObjectForValue != observableObject )
	{
		[ fObservedObjectForValue release ];
		
		fObservedObjectForValue = observableObject;
		[ fObservedObjectForValue retain ];
	}
	
	if ( ![ fObservedKeyPathForValue isEqualToString:keyPath ] )
	{
		[ fObservedKeyPathForValue release ];
		
		fObservedKeyPathForValue = keyPath;
		[ fObservedKeyPathForValue retain ];
	}
}

- (id) initWithFrame:(NSRect)frameRect
{
	[ super initWithFrame:frameRect ];
	
	[ self setTitle:@"Stepper" ];
	[ self configure ];

	//------ set some rational defaults for our stepper values
	
	fValue		=	0.0;
	fIncrement	=	1.0;
	fMaximum	=	10.0;
	fMinimum	=	0.0;
	fWraps		=	NO;
	
	fObservedObjectForValue			=	nil;
	fObservedKeyPathForValue		=	nil;
	
	return self;
}

#pragma mark NSButton

- (BOOL) sendAction:(SEL)theAction to:(id)theTarget
{
	//----- when this button is pressed and will send its action
	//      we update our internal value and handling any bindings
	
	[ self updateValue ];	
	
	return [ super sendAction:theAction to:theTarget ];
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder*) coder
{
	[ super encodeWithCoder:coder ];
	[ coder encodeValueOfObjCType:@encode(float) at:&fValue ];
	[ coder encodeValueOfObjCType:@encode(float) at:&fIncrement ];
	[ coder	encodeValueOfObjCType:@encode(float) at:&fMaximum ];
	[ coder encodeValueOfObjCType:@encode(float) at:&fMinimum ];
	[ coder encodeValueOfObjCType:@encode(BOOL) at:&fWraps ];
}

- (id) initWithCoder:(NSCoder*) coder
{
	if ( self = [ super initWithCoder:coder ] )
	{				
		[ coder decodeValueOfObjCType:@encode(float) at:&fValue ] ;
		[ coder decodeValueOfObjCType:@encode(float) at:&fIncrement ] ;
		[ coder decodeValueOfObjCType:@encode(float) at:&fMaximum ] ;
		[ coder decodeValueOfObjCType:@encode(float) at:&fMinimum ] ;
		[ coder decodeValueOfObjCType:@encode(BOOL) at:&fWraps ] ;
		
		[ self configure ];
	}
	
	return self;
}


#pragma mark Accessors

- (float)value
{
    return fValue;
}

- (void)setValue:(float)value
{
    if (fValue != value)
	{
        fValue = value;
    }
}

- (float)increment
{
    return fIncrement;
}

- (void)setIncrement:(float)value
{
    if (fIncrement != value)
	{
        fIncrement = value;
    }
}

- (float)maximum
{
    return fMaximum;
}

- (void)setMaximum:(float)value
{
    if (fMaximum != value)
	{
        fMaximum = value;
    }
}

- (float)minimum
{
    return fMinimum;
}

- (void)setMinimum:(float)value
{
    if (fMinimum != value)
	{
        fMinimum = value;
    }
}

- (BOOL)wraps
{
    return fWraps;
}

- (void)setWraps:(BOOL)value
{
    if (fWraps != value)
	{
        fWraps = value;
    }
}


#pragma mark IBPalette
// It would be better to have IBPalette support methods added
// via category, but it appears that does not work in this case.
// I suspect it is because we are a sublcass of NSButton, which
// already implements this method directly or has it added by a category as well

- (NSString *)inspectorClassName
{
    return @"RSStepperButtonInspector";
}

#pragma mark Bindings

- (NSArray*) exposedBindings
{
	NSArray* newBindings = [ NSArray arrayWithObjects:@"value", @"increment", @"maximum", @"minimum", @"wraps", nil ];
	NSArray* bindings = [ [ super exposedBindings ] arrayByAddingObjectsFromArray:newBindings ];
	
	return bindings;	
}

- (Class) valueClassForBinding:(NSString*) binding
{
	//----- currently all bindings are floats or BOOLs
	
	return [ NSNumber class ];
}

- (void) bind:(NSString *)bindingName
     toObject:(id)observableController
  withKeyPath:(NSString *)keyPath
      options:(NSDictionary *)options
{	
	
	// ----- By calling super's bind, we don't have to do any of the work
	//       our keypath "value" is updated when the model updates
	//		 the problem is later when the view is clicked on and we need to 
	//       update the value of the object we are bound to, we don't know how to get 
	//       to it. 10.4 added a method infoForBinding which overcomes this, but we
	//       can't use that for a control that works in 10.3

	
	[ super bind:bindingName
		toObject:observableController
	 withKeyPath:keyPath
		 options:options ];

	if ( [ bindingName isEqualToString:@"value" ] )
	{
		[ self setObjectObserveredForValue:observableController withKeyPath:keyPath ];
		fValue = 0.0;
	}
	
}

- (void)unbind:bindingName
{
    if ( [ bindingName isEqualToString:@"value"] )
	{
		[ self setObjectObserveredForValue:nil withKeyPath:nil ];
    }
	
	[ super unbind:bindingName ];
}

@end
