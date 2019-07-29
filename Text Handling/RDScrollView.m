//
//  RDScrollView.m
//  RDControlsTest
//
//  Created by Rachel Blackman on 9/17/05.
//  Copyright 2005 Riverdark Studios. All rights reserved.
//

#import "RDScrollView.h"

@implementation RDScroller

- (id) init
{
    _rdAutoScroll = YES;
    return [super init];
}

#pragma mark Overrides

- (void) mouseDown: (NSEvent *)theEvent
{
    [super mouseDown: theEvent];
	[self calculateAutoScroll];
}

- (void)trackScrollButtons:(NSEvent *)theEvent
{
    [super trackScrollButtons:theEvent];
	[self calculateAutoScroll];
}

- (void)trackKnob:(NSEvent *)theEvent
{
    [super trackKnob:theEvent];
	[self calculateAutoScroll];
}

- (void)setFloatValue:(float)aFloat knobProportion:(CGFloat)knobProp
{
    [super setFloatValue:aFloat knobProportion:knobProp];
}

#pragma mark Accessors

- (BOOL)autoScroll
{
    return _rdAutoScroll;
}

- (void) calculateAutoScroll
{
    BOOL autoscroll = NO;
    
    if (([self knobProportion] == 1) || ([self knobProportion] == 0) || ([self floatValue] >= 0.9999999999) || ([self usableParts] == NSNoScrollerParts) || ([self usableParts] == NSOnlyScrollerArrows))
        autoscroll = YES;
    
	[self setAutoScroll:autoscroll];
}

- (void)setAutoScroll: (BOOL) scroll
{
    _rdAutoScroll = scroll;
}

@end

#pragma mark -----

@implementation RDScrollView

- (void) awakeFromNib
{
    RDScroller *rdScroller;

    rdScroller=[[RDScroller alloc] init];
    [self setVerticalScroller: rdScroller];
    [rdScroller release];
}

- (id) initWithFrame:(NSRect) frame
{
	self = [super initWithFrame:frame];	
	
    if (self == nil)
		return nil;

    NSParameterAssert([self contentView] != nil);
	
    RDScroller *rdScroller;

    rdScroller=[[RDScroller alloc] init];
    [self setVerticalScroller: rdScroller];
    [rdScroller release];
    
    return self;
}

- (void) scrollWheel:(NSEvent *) theEvent
{
    RDScroller *scroller = (RDScroller *)[self verticalScroller];

    [super scrollWheel: theEvent];
    [scroller calculateAutoScroll];
}

- (BOOL) autoScroll 
{
    BOOL result = NO;

    if (![self hasVerticalScroller])
        result = YES;

    if (!result)
        result = [(RDScroller *)[self verticalScroller] autoScroll];

    return result;
}

- (void) recalculateAutoScroll
{
    RDScroller *scroll = (RDScroller *)[self verticalScroller];

    [scroll calculateAutoScroll];
}

- (void) scrollPageUp:(id) sender
{
    [super scrollPageUp:sender];
    [self recalculateAutoScroll];
}

- (void) scrollPageDown:(id) sender
{
    [super scrollPageDown:sender];
    [self recalculateAutoScroll];
}

@end
