//
//  RDChainedListView.m
//  CLVTest
//
//  Created by Rachel Blackman on 2/17/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDChainedListView.h"
#import "RDChainedListItem.h"
#import "RDChainedListItemContent.h"

@interface RDChainedListViewDelegate
- (void) chainedListViewSelectionDidChange:(RDChainedListView *) chainView;
@end

@interface RDChainedListView (Private)
- (void) relayoutFromPosition:(int) pos;
- (void) relayoutFromItem:(RDChainedListItem *)item;
@end

@implementation RDChainedListView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _rdBackground = nil;
        _rdItems = [[[NSMutableArray alloc] init] retain];
        _rdSpacing = 4.0f;
        _rdMargin = 4.0f;
        _rdCurLastY = [self bounds].origin.y + _rdSpacing;
        _rdCurrentActive = nil;
        _rdAutocollapse = NO;
        _rdInLayout = NO;
        _rdDelegate = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:@"NSViewFrameDidChangeNotification" object:self];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_rdDelegate release];
    [_rdBackground release];
    [_rdItems release];
    [super dealloc];
}

- (void) frameChanged:(NSNotification *)notification
{
    if (_rdInLayout)
        return;
        
    [self relayoutFromPosition:0];
}

- (BOOL) isFlipped
{
    // I know this is bad.  But it'll make my life sooooo much easier...
    return YES;
}

- (void) addItem:(RDChainedListItem *) item
{
    if ([_rdItems containsObject:item])
        return;
        
    [_rdItems addObject:item];

    NSRect bounds = [self bounds];
    NSRect itemFrame = [item frame];
    NSRect newFrame = NSMakeRect(NSMinX(bounds) + _rdMargin,_rdCurLastY,NSWidth(bounds) - (_rdMargin * 2.0f),itemFrame.size.height);
    [item setFrame:newFrame];
    
    [self addSubview:item];
    [self relayoutFromPosition:[_rdItems count] - 1];
}

- (void) removeItem:(RDChainedListItem *) item
{
    if (![_rdItems containsObject:item])
        return;
    
    unsigned itemIndex = [_rdItems indexOfObject:item];
    
    if (_rdCurrentActive == item)
        _rdCurrentActive = nil;
    
    [item removeFromSuperviewWithoutNeedingDisplay];
    [_rdItems removeObject:item];
    
    if (itemIndex >= [_rdItems count]) 
        itemIndex = [_rdItems count] - 1;
                
    if (![_rdItems count]) {
        [self setNeedsDisplayInRect:[self visibleRect]];
        [[self window] displayIfNeeded];
    }
    else        
        [self relayoutFromPosition:itemIndex];
}

- (void) moveItem:(RDChainedListItem *)item toPosition:(int) position
{
    if ([_rdItems containsObject:item]) {
        int oldPosition = [_rdItems indexOfObject:item];
        
        if ((position >= 0) && (position < [_rdItems count]) && (position != oldPosition)) {
            [_rdItems exchangeObjectAtIndex:position withObjectAtIndex:oldPosition];
            
            if (position < oldPosition) {
                [self relayoutFromPosition:position];
            }
            else {
                [self relayoutFromPosition:oldPosition];
            }
        }
    }
}

- (void) removeAllItems
{
    NSEnumerator *itemEnum = [_rdItems reverseObjectEnumerator];
    
    RDChainedListItem *itemWalk;
    
    _rdCurrentActive = nil;
    
    while (itemWalk = [itemEnum nextObject]) {
        [itemWalk removeFromSuperviewWithoutNeedingDisplay];
        [_rdItems removeObject:itemWalk];
    }
}

- (void) relayoutFromPosition:(int) pos
{
//    if (_rdInLayout)
//        return;
        
    _rdInLayout = YES;

    int total = [_rdItems count];

    if (pos >= total)
        return;
        
    if (pos < 0)
        return;
    
    float startY, curY;
    NSRect bounds = [self bounds];
   
    RDChainedListItem *tempItem;
    if (pos > 0) {
        tempItem = [_rdItems objectAtIndex:(pos - 1)];
        NSRect tempRect = [tempItem frame];
        startY = NSMaxY(tempRect);
    }
    else {
        startY = NSMinY(bounds);
    }
    
    curY = startY + _rdSpacing;
    
    int i;
    for (i = pos; i < total; i++) {
        tempItem = [_rdItems objectAtIndex:i];
        NSRect itemFrame = [tempItem frame];
        itemFrame.origin.x = NSMinX(bounds) + _rdMargin;
        itemFrame.origin.y = curY;
        itemFrame.size.width = NSWidth(bounds) - (_rdMargin * 2.0f);
        curY += itemFrame.size.height;
        curY += _rdSpacing;
        [tempItem setFrame:itemFrame];
    }

    NSRect frame = [self frame];
    NSView *superview = [self superview];
    if (_rdAutocollapse) {
        if (![superview isFlipped]) {
            frame.origin.x -= (frame.size.height - curY);
        }
        frame.size.height = curY;
        [self setFrame:frame];
    }
    else if (curY > frame.size.height) {
        frame.size.height = curY;
        [self setFrame:frame];
    }
    _rdCurLastY = curY;

    if (_rdAutocollapse) {
        if (frame.origin.x != _rdMargin) {
            float diff = _rdMargin - frame.origin.x;
            
            NSRect superFrame = [superview frame];
            superFrame.size.height -= diff;
            [superview setFrame:superFrame];
            frame.origin.x = _rdMargin;
            [self setFrame:frame];

            superview = [superview superview];
            if ([superview isKindOfClass:[RDChainedListItemContent class]]) {
                [(RDChainedListItemContent *)superview resynchNoDisplay];
            }
        }
    }

    if ([superview isKindOfClass:[NSClipView class]]) {
        NSClipView *clipView = (NSClipView *)superview;
        NSRect visible = [clipView documentRect];
        if (visible.size.height > frame.size.height) {
            frame.size.height = visible.size.height;
            [self setFrame:frame];
        }
    }
    
    NSRect myRect = [self bounds];
    myRect.size.height -= startY;
    myRect.origin.y = startY;    
    [self setNeedsDisplayInRect:myRect];
    [[self window] displayIfNeeded];
    
    _rdInLayout = NO;
}

- (void) relayoutFromItem:(RDChainedListItem *) item
{
    int itemIndex = [_rdItems indexOfObject:item];
    
    if (itemIndex == NSNotFound)
        return;
    
    [self relayoutFromPosition:itemIndex];
}

- (RDChainedListItem *) itemAtPosition:(unsigned) pos
{
    if (pos >= [_rdItems count])
        return nil;
        
    return [_rdItems objectAtIndex:pos];
}

- (unsigned) positionOfItem:(RDChainedListItem *) item
{
    return [_rdItems indexOfObject:item];
}

- (NSColor *) background
{
    return _rdBackground;
}

- (void) setBackground:(NSColor *) background
{
    [_rdBackground release];
    _rdBackground = [background retain];
    [[self enclosingScrollView] setBackgroundColor:background];
    [[self enclosingScrollView] setDrawsBackground:YES];
}

- (BOOL) autocollapse
{
    return _rdAutocollapse;
}

- (void) setAutocollapse:(BOOL)autocollapse
{
    _rdAutocollapse = autocollapse;
}

- (id) delegate
{
    return _rdDelegate;
}

- (void) setDelegate:(id) delegate
{
    [_rdDelegate release];
    _rdDelegate = [delegate retain];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    if (_rdBackground) {
        [_rdBackground set];
        NSRectFillUsingOperation(rect,NSCompositeSourceOver);
    }
}

- (RDChainedListItem *) currentActiveItem
{
    return _rdCurrentActive;
}

- (RDChainedListItem *) itemForLocation:(NSPoint) loc
{
    float current = [self bounds].origin.y + _rdSpacing;
    
    RDChainedListItem *result = nil;
    RDChainedListItem *walk;
    NSEnumerator *itemEnum = [_rdItems objectEnumerator];
    
    while (!result && (walk = [itemEnum nextObject])) {
        float other = current + ([walk frame].size.height);
        if ((loc.y >= current) && (loc.y <= other)) 
            result = walk;
            
        current = other + _rdSpacing;
    }
    
    return result;
}

- (void) mouseDown:(NSEvent *)event
{
    NSPoint orig = [event locationInWindow];
    NSPoint mouse = [self convertPoint:orig fromView:nil];
    RDChainedListItem *newItem = nil;
    RDChainedListItem *oldItem = nil;
    
    newItem = [self itemForLocation:mouse];
    oldItem = _rdCurrentActive;
    
    if (newItem != oldItem) {
        _rdCurrentActive = newItem;
        if (oldItem) {
            [oldItem setActive:NO];
            [oldItem setShowsAlternate:YES];
        }

        [newItem setActive:YES];
        [newItem setShowsAlternate:NO];
        [newItem setNeedsDisplay:YES];
        [self setNeedsDisplay:YES];
        
        if (_rdDelegate && [_rdDelegate respondsToSelector:@selector(chainedListViewSelectionDidChange:)])
            [_rdDelegate chainedListViewSelectionDidChange:self];
    }
    else {
        // See if it's a button
        NSPoint clickPos = [newItem convertPoint:mouse fromView:self];
        [newItem checkForButton:clickPos];
    }
}

@end
