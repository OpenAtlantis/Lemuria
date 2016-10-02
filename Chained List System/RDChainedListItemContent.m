//
//  RDChainedListItemContent.m
//  CLVTest
//
//  Created by Rachel Blackman on 2/17/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDChainedListItemContent.h"
#import "RDChainedListItem.h"

@implementation RDChainedListItemContent

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setAutoresizesSubviews:NO];
        _rdAlternateView = nil;
        _rdMainView = nil;	
        _rdAnimating = NO;
        _rdResynching = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:@"NSViewFrameDidChangeNotification" object:self];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_rdMainView) {
        [_rdMainView removeFromSuperviewWithoutNeedingDisplay];
        [_rdMainView release];
    }
    if (_rdAlternateView) {
        [_rdAlternateView removeFromSuperviewWithoutNeedingDisplay];
        [_rdAlternateView release];
    }
    [super dealloc];
}

- (void) subFrameChanged:(NSNotification *) notification
{
    if (!_rdResynching) {
        [self resynch];
    }
}

- (void) frameChanged:(NSNotification *) notification
{
    NSRect rect = [self bounds];
    
    float newWidth = rect.size.width;
    
    if (_rdMainView) {
        rect = [_rdMainView frame];
        rect.size.width = newWidth;
        [_rdMainView setFrame:rect];
    }

    if (_rdAlternateView) {
        rect = [_rdAlternateView frame];
        rect.size.width = newWidth;
        [_rdAlternateView setFrame:rect];
    }
}

- (void) setMainView:(NSView *)view
{
    BOOL showMe = NO;

    if (_rdMainView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSViewFrameDidChangeNotification" object:_rdMainView];
        [_rdMainView removeFromSuperviewWithoutNeedingDisplay];
        [_rdMainView release];
        _rdMainView = nil;
    }
    else
        showMe = !_rdAlternate;
    
    if (view) {
        _rdMainView = [view retain];
        [self addSubview:_rdMainView];
        NSRect subviewRect = [view frame];
        subviewRect.origin = NSMakePoint(0,0);
        subviewRect.size.width = [self bounds].size.width;
        [view setFrame:subviewRect];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subFrameChanged:) name:@"NSViewFrameDidChangeNotification" object:_rdMainView];
    }
}

- (void) setAlternateView:(NSView *)view
{
    BOOL showMe = NO;

    if (_rdAlternateView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSViewFrameDidChangeNotification" object:_rdAlternateView];
        [_rdAlternateView removeFromSuperviewWithoutNeedingDisplay];
        [_rdAlternateView release];
        _rdAlternateView = nil;
    }
    else
        showMe = _rdAlternate;
    
    if (view) {
        _rdAlternateView = [view retain];
        [self addSubview:_rdAlternateView];
        NSRect subviewRect = [view frame];
        subviewRect.origin = NSMakePoint(0,0);
        subviewRect.size.width = [self bounds].size.width;
        [view setFrame:subviewRect];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subFrameChanged:) name:@"NSViewFrameDidChangeNotification" object:_rdAlternateView];
    }
    
}

- (NSView *) mainView
{
    return _rdMainView;
}

- (NSView *) alternateView
{
    return _rdAlternateView;
}

- (BOOL) isShowingAlternate
{
    return _rdAlternate;
}

- (BOOL) isFlipped
{
    return YES;
}

- (void) animateToView
{
    if (_rdAnimating) {
        [NSEvent stopPeriodicEvents];
        _rdAnimating = NO;
    }

    NSView *targetView = (_rdAlternate ? _rdAlternateView : _rdMainView);
    NSView *oldView = (_rdAlternate ? _rdMainView : _rdAlternateView);
    
    NSRect targetSize;
    NSRect originalSize = [self frame];
    
    if (targetView) {
        targetSize = originalSize;
        targetSize.size.height = [targetView frame].size.height;
    }
    else {
        targetSize = NSMakeRect(0,0,originalSize.size.width,0);
    }
    
    float animationPeriod = 1.0f / 30.0f;
    float animationDuration = 0.2f;
    
    BOOL isCollapsing;
    float heightDifference;
    float coreHeight;
    
    if (targetSize.size.height < originalSize.size.height) {
        isCollapsing = YES;
        heightDifference = originalSize.size.height - targetSize.size.height;
        coreHeight = targetSize.size.height;
    }
    else {
        isCollapsing = NO;
        heightDifference = targetSize.size.height - originalSize.size.height;
        coreHeight = originalSize.size.height;
    }
       
    NSView *superview = [self superview];
    RDChainedListItem *item = nil;
    if ([superview isKindOfClass:[RDChainedListItem class]]) {
        item = (RDChainedListItem *)superview;
    }
    
    NSDate *startDate = [NSDate date];
    [NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:animationPeriod];        
    _rdAnimating = YES;
    BOOL flippedViews = NO;
    while (1) {
        (void)[[self window] nextEventMatchingMask:NSPeriodicMask];
        
        float duration = -[startDate timeIntervalSinceNow];
        float percentDone = duration / animationDuration;
        
        if (percentDone > 1.0) {
            percentDone = 1.0;
        }
        
        if (!flippedViews && (percentDone >= 0.5)) {
            flippedViews = YES;
            [oldView setHidden:YES];
            [targetView setHidden:NO];
        }
        
        static const float _StartAngle = 1.570796;  // 90 degrees in radians
        static const float _AngleRange = 4.712389 - 1.570796;  // 270 degrees in radians - 90 degrees in radians
        
        // Scale the percentDone on a sine curve
        // Take the sin at percentDone of the way through the range from 90 to 270 degrees (sin 1.0 to -1.0)
        // Scale the sin between 0 and 1
        percentDone = 1.0 - ((sin(_StartAngle + (percentDone * _AngleRange)) + 1.0) / 2.0);
        
        if (percentDone > 1.0) {
            percentDone = 1.0;
        }
        
        float _animationAmountRevealed = coreHeight + (heightDifference * (isCollapsing ? 1.0 - percentDone : percentDone)); 
                
        NSRect tempRect = [self frame];
        tempRect.size.height = _animationAmountRevealed;
        [self setFrame:tempRect];        
        [item resynch];
        
        if (percentDone >= 1.0) {
            break;
        }
    }
    [NSEvent stopPeriodicEvents];
    _rdAnimating = NO;
}

- (void) setShowsAlternate:(BOOL) alternate
{
    if (alternate != _rdAlternate) {
        _rdAlternate = alternate;
        [self animateToView];
    }
}

- (void) resynch
{
    if (_rdAnimating)
        return;
    if (_rdResynching)
        return;

    _rdResynching = YES;
        
    NSView *targetView = (_rdAlternate ? _rdAlternateView : _rdMainView);
    NSView *oldView = (_rdAlternate ? _rdMainView : _rdAlternateView);

    NSRect myFrame = [self frame];
    NSRect targetFrame;
    
    if (targetView) {
        targetFrame = [targetView frame];
    }
    else {
        targetFrame = NSZeroRect;
    }
    
    if (targetFrame.size.height != myFrame.size.height) {
        [self animateToView];
    }
    else {
        [oldView setHidden:YES];
        [targetView setHidden:NO];
    }
    
    _rdResynching = NO;
}

- (void) resynchNoDisplay
{
//    if (_rdAnimating)
//        return;
//    if (_rdResynching)
//        return;
   
    BOOL oldSync = _rdResynching;
     
    _rdResynching = YES;
    
    NSView *targetView = (_rdAlternate ? _rdAlternateView : _rdMainView);

    NSRect myFrame = [self frame];
    NSRect targetFrame = [targetView frame];
    if (targetFrame.size.height != myFrame.size.height) {
        myFrame.size.height = targetFrame.size.height;
        [self setFrame:myFrame];

        NSView *superview = [self superview];
        if ([superview isKindOfClass:[RDChainedListItem class]]) {
            [(RDChainedListItem *)superview resynch];
        }
    }
    
    _rdResynching = oldSync;    
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

@end
