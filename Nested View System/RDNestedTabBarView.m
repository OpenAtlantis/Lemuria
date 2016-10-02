//
//  RDNestedTabBarView.m
//  Lemuria
//
//  Created by Rachel Blackman on 9/8/07.
//  Copyright 2007 Riverdark Studios. All rights reserved.
//

#import "RDNestedTabBarView.h"
#import "RDNestedViewDescriptor.h"
#import "RDNestedViewManager.h"
#import "RDTabViewItem.h"

#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"

@interface RDNestedTabBarView (Private)
- (NSTabViewItem *) newItemForView:(id <RDNestedViewDescriptor>) view;
- (NSTabViewItem *) itemForView:(id <RDNestedViewDescriptor>) view;
- (PSMTabBarCell *) cellForItem:(NSTabViewItem *)item;
@end

@implementation RDNestedTabBarView

#pragma mark Core View Functions

- (id)initWithFrame:(NSRect)frame forWindowID:(NSString *)name {

    NSRect realRect = NSZeroRect;
    realRect.size = frame.size;

    NSRect barRect = realRect;
    barRect.size.height = 22;
    barRect.origin.y = realRect.size.height - 22;

    NSRect contentRect = realRect;
    contentRect.size.height = realRect.size.height - 23; 
    contentRect.size.width -= 2;
    contentRect.origin.x += 1;
    contentRect.origin.y += 1;

    self = [super initWithFrame:frame];
    if (self) {
        _rdViewCollection = [[RDNestedViewCache alloc] init];
        [_rdViewCollection setDelegate:self];
        
        _rdTabBar = [[PSMTabBarControl alloc] initWithFrame:barRect];        
        [_rdTabBar setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        
        [_rdTabBar setDelegate:self];
        [_rdTabBar setStyleNamed:@"Aqua"];
        [_rdTabBar setShowAddTabButton:NO];
        [_rdTabBar setCanCloseOnlyTab:YES];
        [_rdTabBar setSizeCellsToFit:YES];
        
        _rdTabView = [[NSTabView alloc] initWithFrame:contentRect];
        [_rdTabView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [_rdTabBar setTabView:_rdTabView];
        [_rdTabBar setPartnerView:_rdTabView];
        [_rdTabBar setUseOverflowMenu:NO];
        
        [_rdTabView setTabViewType:NSNoTabsNoBorder];
        
        [_rdTabView setDelegate:_rdTabBar];
        
        [self addSubview:_rdTabBar];
        [self addSubview:_rdTabView];
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
    return [_rdTabView frame];
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
        
    [_rdTabView selectTabViewItem:item];
    
    return YES;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    id <RDNestedViewDescriptor> view = [tabViewItem identifier];
    
    [[RDNestedViewManager manager] view:view hasActivity:NO];
    [[RDNestedViewManager manager] viewReceivedFocus:view];
}

- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    id <RDNestedViewDescriptor> view = [tabViewItem identifier];
    [[RDNestedViewManager manager] viewRequestedClose:view];
    return NO;
}

- (void)tabView:(NSTabView *)aTabView willDragTabViewItem:(NSTabViewItem *)tabViewItem withEvent:(NSEvent *)theEvent
{
    id view = [tabViewItem identifier];
    
    if ([view conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
        if (![[RDNestedViewManager manager] isDragging])
            [[RDNestedViewManager manager] beginDraggingView:view onEvent:theEvent];
    }    
}


- (id <RDNestedViewDescriptor>) selectedView
{
    NSTabViewItem *item = [_rdTabView selectedTabViewItem];
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
        [_rdTabView insertTabViewItem:item atIndex:pos];

        PSMTabBarCell *cell = [self cellForItem:item];
        if (cell) {
            [cell setHasCloseButton:YES];
        }
    }

    [_rdTabBar setNeedsDisplay:YES];
}

- (void) collection:(RDNestedViewCache *)collection hasUpdatedRemovingView:(id <RDNestedViewDescriptor>)aView
{
    if (!aView)
        return;

    NSTabViewItem *tvi = [self itemForView:aView];
    if (tvi) {
        if (aView == [self selectedView]) {
            int pos = [_rdTabView indexOfTabViewItem:tvi];
            if (pos == 0) {
                if ([[_rdTabView tabViewItems] count] > 1)
                    [_rdTabView selectTabViewItemAtIndex:1];
            }
            else
                [_rdTabView selectTabViewItemAtIndex:(pos - 1)];
        }
        [_rdTabView removeTabViewItem:tvi];
    }
    [self setNeedsDisplay:YES];
}

- (void) view:(id <RDNestedViewDescriptor>) aView hasActivity:(BOOL) activity
{
    NSTabViewItem *item = [self itemForView:aView];
    PSMTabBarCell *cell = [self cellForItem:item];
    if (!cell)
        return;

    if (activity) {
        int actCount = [[RDNestedViewManager manager] activityCountSelf:aView];
        [cell setCount:actCount];
    }
    else {
        [cell setCount:0];
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
        int pos = [_rdTabView indexOfTabViewItem:tvi];
        int count = [[_rdTabView tabViewItems] count];
        
        pos++;
        if (pos == count)
            pos = 0;
        
        NSTabViewItem *tvi2 = [_rdTabView tabViewItemAtIndex:pos];
        return [tvi2 identifier];
    }
    
    return nil;
}

- (id <RDNestedViewDescriptor>) previousView
{
    NSTabViewItem *tvi = [self itemForView:[self selectedView]];
    if (tvi) {
        int pos = [_rdTabView indexOfTabViewItem:tvi];
        int count = [[_rdTabView tabViewItems] count];
        
        pos--;
        if (pos < 0)
            pos = (count - 1);
        
        NSTabViewItem *tvi2 = [_rdTabView tabViewItemAtIndex:pos];
        return [tvi2 identifier];
    }
    
    return nil;
}

- (BOOL) isViewListCollapsed
{
    return [_rdTabBar isHidden];
}

- (void) expandViewList
{
    NSRect tabViewRect = [_rdTabView frame];
    
    tabViewRect.size.height -= 22;

    [_rdTabView setFrame:tabViewRect];
    [_rdTabView setNeedsDisplay:YES];
    [_rdTabBar setHidden:NO];
}

- (void) collapseViewList
{
    NSRect tabViewRect = [_rdTabView frame];
    
    tabViewRect.size.height += 22;

    [_rdTabView setFrame:tabViewRect];
    [_rdTabView setNeedsDisplay:YES];
    [_rdTabBar setHidden:YES];
}

- (void) resynchViews
{
    // TODO: Handle resorting of views
}

#pragma mark Internal Functions

- (PSMTabBarCell *) cellForItem:(NSTabViewItem *)item
{
    NSEnumerator *e = [[_rdTabBar tabBarCells] objectEnumerator];
    PSMTabBarCell *cell;
    while(cell = [e nextObject]){
        if ([cell representedObject] == item) {
            return cell;
        }
    }
    
    return nil;
}

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
    NSEnumerator *viewEnum = [[_rdTabView tabViewItems] objectEnumerator];
    
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

- (void) mouseMoved:(NSEvent *)event
{
    //
}

- (void) drawRect:(NSRect)rect
{
    NSRect bounds = [self frame];
    [[NSColor grayColor] set];
    NSRectFill(bounds);
    [super drawRect:rect];
}

@end
