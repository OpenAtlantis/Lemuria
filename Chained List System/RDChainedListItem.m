//
//  RDChainedListItem.m
//  CLVTest
//
//  Created by Rachel Blackman on 2/16/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDChainedListItem.h"
#import "RDChainedListItemContent.h"
#import "RDChainedListView.h"
#import "RDChainedListButton.h"

@interface RDChainedListItem (Private)
- (void)drawTitleBarInRect:(NSRect) rect;
- (NSRect) titleBarRectForRect:(NSRect) boxRect;
@end

@implementation RDChainedListItem

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _rdBackground = [[NSColor colorWithCalibratedRed:0.8f green:0.8f blue:0.8f alpha:1.0f] retain];
        _rdOutlineActive = [[NSColor blueColor] retain];
        _rdOutlineInactive = [[NSColor darkGrayColor] retain];
        _rdActive = NO;
        _rdAlternate = NO;
        _rdBorderWidth = 2.0f;

        NSRect boxRect = [self bounds];
        NSRect titleRect = [self titleBarRectForRect:boxRect];
        NSRect bgRect = boxRect;
        float titleSize = titleRect.size.height + (_rdBorderWidth * 4.0);
        bgRect.size.height -= titleSize;
        bgRect.origin.y += titleSize;
        bgRect = NSInsetRect(bgRect, _rdBorderWidth + 6.0, _rdBorderWidth + 6.0);

        _rdContentView = [[[RDChainedListItemContent alloc] initWithFrame:bgRect] retain];
        [self addSubview:_rdContentView];
        [self setAutoresizesSubviews:NO];        
        
        _rdOptionButtons = [[[NSMutableArray alloc] init] retain];
        _rdAvoidRecursion = NO;
        _rdTitle = [[NSString stringWithString:@"Test ChainedList Item"] retain];
        _rdTitleAttributes = [[[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]],NSFontAttributeName,
                            [NSColor whiteColor],NSForegroundColorAttributeName,nil] retain];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:@"NSViewFrameDidChangeNotification" object:self];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_rdContentView release];
    [_rdBackground release];
    [_rdOutlineActive release];
    [_rdOutlineInactive release];
    [_rdOptionButtons release];
    [_rdTitle release];
    [_rdTitleAttributes release];
    [super dealloc];
}

- (BOOL) isFlipped
{
    return YES;
}

#pragma mark Actual Drawing Goo

- (void) frameChanged:(NSNotification *) notification
{
    if (_rdAvoidRecursion)
        return;
    
    _rdAvoidRecursion = YES;

    NSRect rect = [self bounds];
    float newWidth = rect.size.width - ((_rdBorderWidth * 2.0f) + 10.0f);
    rect = [_rdContentView frame];
    rect.size.width = newWidth;        
    [_rdContentView setFrame:rect];
    _rdAvoidRecursion = NO;
}

- (void)drawTitleBarInRect:(NSRect) rect {
    NSRect bgRect = rect;
    bgRect = NSInsetRect(rect, _rdBorderWidth - 1.0, _rdBorderWidth - 1.0);
    int minX = NSMinX(bgRect);
    int midX = NSMidX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int midY = NSMidY(bgRect);
    int maxY = NSMaxY(bgRect);
    float radius = 4.0;
    NSBezierPath *bgPath = [NSBezierPath bezierPath];

    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];

    if (_rdActive) {
        [_rdOutlineActive set];
    }
    else {
        [_rdOutlineInactive set];
    }

    [bgPath fill];
    
    // Draw button-y things.
    float curLeft = maxX - _rdBorderWidth;
    
    NSEnumerator *buttonEnum = [_rdOptionButtons objectEnumerator];
    
    RDChainedListButton *buttonWalk;
    
    while (buttonWalk = [buttonEnum nextObject]) {
        
        NSImage *tempImage = [buttonWalk image];
        
        curLeft -= [tempImage size].width;
        float curTop = _rdBorderWidth + [tempImage size].height;
        
        NSPoint drawPoint = NSMakePoint(curLeft,curTop);
        
        [tempImage compositeToPoint:drawPoint operation:NSCompositeSourceAtop fraction:1.0f];
        
        curLeft -= _rdBorderWidth;        
    }
    
}

- (NSRect) titleBarRectForRect:(NSRect) boxRect
{
    float titleHInset = 6.0f;
    float titleVInset = 2.0f;
    NSSize titleSize = [_rdTitle sizeWithAttributes:_rdTitleAttributes];
    NSRect titleRect = NSMakeRect(titleHInset, titleVInset, titleSize.width, titleSize.height);
    titleRect.size.width = MIN(titleRect.size.width, boxRect.size.width - (2.0 * titleHInset));
    
    NSRect titlebarRect = NSMakeRect(boxRect.origin.x,
                                     boxRect.origin.y,
                                     boxRect.size.width,
                                     titleSize.height + (2.0 * titleVInset));
    
    return titlebarRect;
}

- (void)drawRect:(NSRect)rect {

    NSRect boxRect = [self bounds];
    NSRect bgRect = boxRect;
    bgRect = NSInsetRect(boxRect, _rdBorderWidth - 1.0, _rdBorderWidth - 1.0);
    int minX = NSMinX(bgRect);
    int midX = NSMidX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int midY = NSMidY(bgRect);
    int maxY = NSMaxY(bgRect);
    float radius = 4.0;
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];

    if (_rdBackground) {
        [_rdBackground set];
        [bgPath fill];
    }

    float titleHInset = 6.0f;
    float titleVInset = 2.0f;
    NSSize titleSize = [_rdTitle sizeWithAttributes:_rdTitleAttributes];
    NSRect titleRect = NSMakeRect(titleHInset, 
                                  titleVInset, 
                                  titleSize.width, 
                                  titleSize.height);
    titleRect.size.width = MIN(titleRect.size.width, boxRect.size.width - (2.0 * titleHInset));
    
    NSRect titlebarRect = [self titleBarRectForRect:boxRect];
    
    [self drawTitleBarInRect:titlebarRect];
    
    [_rdTitle drawInRect:titleRect withAttributes:_rdTitleAttributes];
    
    // Draw our actual final outline
    if (_rdActive) {
        [_rdOutlineActive set];
    }
    else {
        [_rdOutlineInactive set];
    }
    
    [bgPath setLineWidth:_rdBorderWidth];
    [bgPath stroke];
}

#pragma mark Accessors

- (NSView *) mainContentView
{
    return [_rdContentView mainView];
}

- (void) setMainContentView:(NSView *)view
{
    [_rdContentView setMainView:view];
}

- (NSView *) alternateContentView
{
    return [_rdContentView alternateView];
}

- (void) setAlternateContentView:(NSView *)view
{
    [_rdContentView setAlternateView:view];
}

- (NSColor *) background
{
    return _rdBackground;
}

- (void) setBackground:(NSColor *)bgColor
{
    [_rdBackground release];
    _rdBackground = [bgColor retain];
}

- (NSColor *) outlineActive
{
    return _rdOutlineActive;
}

- (void) setOutlineActive:(NSColor *) activeColor
{
    [_rdOutlineActive release];
    _rdOutlineActive = [activeColor retain];
}

- (NSColor *) outlineInactive
{
    return _rdOutlineInactive;
}

- (void) setOutlineInactive:(NSColor *) inactiveColor
{
    [_rdOutlineInactive release];
    _rdOutlineInactive = [inactiveColor retain];
}

- (BOOL) isActive
{
    return _rdActive;
}

- (void) setActive:(BOOL) active
{
    if (_rdActive != active) {
        [self display];
    }
    _rdActive = active;
}

- (BOOL) showsAlternate
{
    return [_rdContentView isShowingAlternate];
}

- (void) setShowsAlternate:(BOOL) alternate
{
    [_rdContentView setShowsAlternate:alternate];
}

- (NSString *) title
{
    return _rdTitle;
}

- (void) setTitle:(NSString *)title
{
    [_rdTitle release];
    _rdTitle = [title retain];
}

- (NSDictionary *) titleAttributes
{
    return _rdTitleAttributes;
}

- (void) setTitleAttributes:(NSDictionary *) attributes
{
    [_rdTitleAttributes release];
    _rdTitleAttributes = [attributes retain];
}

- (void) addOptionButton:(RDChainedListButton *) button
{
    [_rdOptionButtons addObject:button];
}

- (BOOL) checkForButton:(NSPoint) mouseLoc
{
    NSRect rect = [self titleBarRectForRect:[self bounds]];
    NSRect bgRect;
    
    bgRect = NSInsetRect(rect, _rdBorderWidth - 1.0, _rdBorderWidth - 1.0);
    int maxX = NSMaxX(bgRect);
    int maxY = NSMaxY(bgRect);

    float curLeft = maxX - _rdBorderWidth;
    
    NSEnumerator *buttonEnum = [_rdOptionButtons objectEnumerator];
    
    RDChainedListButton *buttonWalk;
    NSRect testRect;
    
    while (buttonWalk = [buttonEnum nextObject]) {        
        NSImage *tempImage = [buttonWalk image];
        
        curLeft -= [tempImage size].width;
        float curTop = maxY - _rdBorderWidth - [tempImage size].height;
        
        testRect = NSMakeRect(curLeft,curTop,[tempImage size].width,[tempImage size].height);

        if (NSPointInRect(mouseLoc,testRect)) {
            [(NSObject *)[buttonWalk target] performSelector:[buttonWalk action] withObject:self];
            return YES;
        }
        
        curLeft -= _rdBorderWidth;        
    }
    
    return NO;
}

- (void) resynch
{
    [_rdContentView resynch];
    NSRect contentFrame = [_rdContentView frame];

    NSRect myFrame = [self frame];
    NSRect titleRect = [self titleBarRectForRect:myFrame];

    float height;
    if (contentFrame.size.height)
        height = titleRect.size.height + 10.0f + contentFrame.size.height + (_rdBorderWidth * 2.0);
    else
        height = titleRect.size.height;
        
    myFrame.size.height = height;
    
    [self setFrame:myFrame];
    [self setNeedsDisplay:YES];
    
    NSView *superview = [self superview];
    if ([superview isKindOfClass:[RDChainedListView class]]) {
        [(RDChainedListView *)superview relayoutFromItem:self];
    }
}

@end
