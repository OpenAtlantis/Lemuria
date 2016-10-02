//
//  RDNestedTabView.m
//  Lemuria
//
//  Created by Rachel Blackman on 7/2/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDNestedTabView.h"
#import "RDNestedViewDescriptor.h"
#import "RDNestedViewManager.h"
#import "RDTabViewItem.h"

@interface RDNestedTabView (Private)
- (NSTabViewItem *) newItemForView:(id <RDNestedViewDescriptor>) view;
- (NSTabViewItem *) itemForView:(id <RDNestedViewDescriptor>) view;
@end

@implementation RDNestedTabView

#pragma mark Core View Functions

- (id)initWithFrame:(NSRect)frame forWindowID:(NSString *)name {
    self = [super initWithFrame:frame];
    if (self) {
        _rdViewCollection = [[RDNestedViewCache alloc] init];
        [_rdViewCollection setDelegate:self];
        [self setDelegate:self];
        [self setControlSize:NSSmallControlSize];
        [self setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
    }
    
    return self;
}

- (void) dealloc
{
    [_rdViewCollection release];
    [super dealloc];
}

#pragma mark Nested View Display Functions

- (NSRect) contentFrame
{
    return [self contentRect];
}

- (NSView *) contentView
{
    return self;
}

- (BOOL) selectView:(id <RDNestedViewDescriptor>) view
{
    if (!view)
        return NO;
        
    NSTabViewItem *item = [self itemForView:view];
    if (!item)
        return NO;
        
    [self selectTabViewItem:item];
    
    return YES;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    id <RDNestedViewDescriptor> view = [tabViewItem identifier];
    
    [[RDNestedViewManager manager] view:view hasActivity:NO];
    [[RDNestedViewManager manager] viewReceivedFocus:view];
}

- (id <RDNestedViewDescriptor>) selectedView
{
    NSTabViewItem *item = [self selectedTabViewItem];
    if (!item)
        return nil;
        
    return [item identifier];
}

- (RDNestedViewCache *) collection
{
    return _rdViewCollection;
}

- (void) setCollection:(RDNestedViewCache *) collection
{
    if (collection) {
        RDNestedViewCache *old = _rdViewCollection;
        _rdViewCollection = [collection retain];
        [old release];
    }
}

- (void) collection:(RDNestedViewCache *)collection hasUpdatedAddingView:(id <RDNestedViewDescriptor>)aView
{
    if (!aView)
        return;
        
    NSTabViewItem *tvi = [self itemForView:aView];
    if (tvi)
        return;
        
    NSArray *flattened = [_rdViewCollection realViewsFlattened];
    int pos = [flattened indexOfObject:aView];
    if (pos != NSNotFound) {
        NSTabViewItem *item = [self newItemForView:aView];
        [self insertTabViewItem:item atIndex:pos];
    }

    [self setNeedsDisplay:YES];
}

- (void) collection:(RDNestedViewCache *)collection hasUpdatedRemovingView:(id <RDNestedViewDescriptor>)aView
{
    if (!aView)
        return;

    NSTabViewItem *tvi = [self itemForView:aView];
    if (tvi) {
        if (aView == [self selectedView]) {
            int pos = [self indexOfTabViewItem:tvi];
            if (pos == 0) {
                if ([[self tabViewItems] count] > 1)
                    [self selectTabViewItemAtIndex:1];
            }
            else
                [self selectTabViewItemAtIndex:(pos - 1)];
        }
        [self removeTabViewItem:tvi];
    }
    [self setNeedsDisplay:YES];
}

- (void) view:(id <RDNestedViewDescriptor>) aView hasActivity:(BOOL) activity
{
    // TODO: Update tab view item activity counter notice
    if (activity) {
        int actCount = [[RDNestedViewManager manager] activityCountSelf:aView];
        
        NSTabViewItem *item = [self itemForView:aView];
        if ([item isKindOfClass:[RDTabViewItem class]]) {
            [(RDTabViewItem *)item setActivityCount:actCount];
        }
    }
    else {
        NSTabViewItem *item = [self itemForView:aView];
        if ([item isKindOfClass:[RDTabViewItem class]]) {
            [(RDTabViewItem *)item setActivityCount:0];
        }
    }
    [self setNeedsDisplay:YES];
}

- (void) collectionIsEmpty:(RDNestedViewCache *)collection
{
    NSWindow *window = [self window];
    
    if ([window isKindOfClass:[RDNestedViewWindow class]]) {
        if (![(RDNestedViewWindow *)window isDragSource] && ![(RDNestedViewWindow *)window isClosing]) {
            [[RDNestedViewManager manager] removeWindow:(RDNestedViewWindow *)window];
        }
    }
}

- (id <RDNestedViewDescriptor>) nextView
{
    NSTabViewItem *tvi = [self itemForView:[self selectedView]];
    if (tvi) {
        int pos = [self indexOfTabViewItem:tvi];
        int count = [[self tabViewItems] count];
        
        pos++;
        if (pos == count)
            pos = 0;
        
        NSTabViewItem *tvi2 = [self tabViewItemAtIndex:pos];
        return [tvi2 identifier];
    }
    
    return nil;
}

- (id <RDNestedViewDescriptor>) previousView
{
    NSTabViewItem *tvi = [self itemForView:[self selectedView]];
    if (tvi) {
        int pos = [self indexOfTabViewItem:tvi];
        int count = [[self tabViewItems] count];
        
        pos--;
        if (pos < 0)
            pos = (count - 1);
        
        NSTabViewItem *tvi2 = [self tabViewItemAtIndex:pos];
        return [tvi2 identifier];
    }
    
    return nil;
}

- (BOOL) isViewListCollapsed
{
    NSTabViewType tabtype = [self tabViewType];
    if (tabtype == NSTopTabsBezelBorder)
        return YES;
    else
        return NO;
}

- (void) expandViewList
{
    [self setTabViewType:NSTopTabsBezelBorder];
    [self setNeedsDisplay:YES];
}

- (void) collapseViewList
{
    [self setTabViewType:NSNoTabsBezelBorder];
    [self setNeedsDisplay:YES];
}

- (void) resynchViews
{
    // TODO: Handle resorting of views

}

- (void) mouseMoved:(NSEvent *)theEvent
{

}

#pragma mark Internal Functions

- (NSTabViewItem *) newItemForView: (id <RDNestedViewDescriptor>) view
{
    RDTabViewItem *item = [[RDTabViewItem alloc] initWithIdentifier:view];
    [item setView:[view view]];
    [item setLabel:[view viewName]];
    int actCount = [[RDNestedViewManager manager] activityCountSelf:view];
    [item setActivityCount:actCount];
    
    return item;
}

- (NSTabViewItem *) itemForView: (id <RDNestedViewDescriptor>) view
{
    NSEnumerator *viewEnum = [[self tabViewItems] objectEnumerator];
    
    id walk;
    NSTabViewItem *result = nil;
    
    while (!result && (walk = [viewEnum nextObject])) {
        NSTabViewItem *tvi = (NSTabViewItem *)walk;
        
        if ([[(id <RDNestedViewDescriptor>)[tvi identifier] viewUID] isEqualToString:[view viewUID]]) {
            result = tvi;
        }
    }

    return result;
}

#pragma mark Drag and Drop Goo

- (void) mouseDown:(NSEvent *) theEvent
{
	NSEvent *nextEvent = [NSApp
		nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask
					untilDate:[NSDate distantFuture] // or perhaps some reasonable time-out
					   inMode:NSEventTrackingRunLoopMode
					  dequeue:NO];	// don't dequeue in case it's not a drag
	
	if (([nextEvent type] == NSLeftMouseDragged) && (![[NSUserDefaults standardUserDefaults] boolForKey:@"lemuria.dragging.disabled"])) {
        NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        NSTabViewItem *item = [self tabViewItemAtPoint:clickPoint];
        if (item) {
            id view = [item identifier];
            
            if ([view conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
                [[RDNestedViewManager manager] beginDraggingView:(id <RDNestedViewDescriptor>)view onEvent:theEvent];
            }
        }
        else
            [super mouseDown:theEvent];
    }
    else {
        [super mouseDown:theEvent];
    }
}

@end
