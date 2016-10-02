//
//  RDNestedSourceView.m
//  Lemuria
//
//  Created by Rachel Blackman on 6/21/07.
//  Copyright 2007 Riverdark Studios. All rights reserved.
//

#import "RDNestedViewDescriptor.h"
#import "RDNestedViewDisplay.h"
#import "RDNestedSourceView.h"
#import "RDSourceListCell.h"
#import "RDOutlineView.h"
#import "RDNestedViewManager.h"
#import "RDNestedViewCollection.h"
#import "RBSplitView.h"
#import "RBSplitSubview.h"
#import <Cocoa/Cocoa.h>
#import "RSGradientSquareButton.h"

@interface NSTableColumn (Private)
-(void)setResizingMask:(unsigned)resizingMask;
@end

@implementation RDNestedSourceView

#pragma mark Core View Functions

- (id)initWithFrame:(NSRect)frame forWindowID:(NSString *)name {
    self = [super initWithFrame:frame];
    if (self) {
        float outlineWidth;

        _rdSaveID = [[NSString stringWithFormat:@"lemuria.outlineView.width.%@", name] retain];
        
        NSString *outlineString = [[NSUserDefaults standardUserDefaults] stringForKey:_rdSaveID];
        if (!outlineString || ![outlineString length])
            outlineWidth = 200.0f;
        else 
            outlineWidth = [outlineString floatValue];
            
        if (!outlineWidth)
            _rdViewCollapsed = YES;
        else
            _rdViewCollapsed = NO;
            
        _rdExpandedSize = 0.0f;

        [self setAutosaveName:name recursively:YES];

        _rdViewCollection = [[RDNestedViewCache alloc] init];
        [_rdViewCollection setDelegate:self];

        NSRect outlineFrame = NSMakeRect(0,0,outlineWidth,frame.size.height);
        NSRect tabviewFrame = NSMakeRect(outlineWidth + 1,1,frame.size.width - (outlineWidth + 2),frame.size.height - 1);
        
        [self setVertical:YES];
        [self setAutoresizesSubviews:YES];
        [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        
        NSRect scrollRect = outlineFrame;
        scrollRect.size.height -= 23;

        NSRect outlineCoreRect = scrollRect;
        outlineCoreRect.size.height -= 20;
        
        _rdOutlineView = [[RDOutlineView alloc] initWithFrame:outlineCoreRect];
        [_rdOutlineView setBackgroundColor:[NSColor colorWithDeviceRed:0.906 green:0.930 blue:0.965 alpha:1.0]];
        [_rdOutlineView setUsesGradientSelection:YES];
        [_rdOutlineView setDataSource:self];
        [_rdOutlineView setDelegate:self];
        [_rdOutlineView setFocusRingType:NSFocusRingTypeNone];
        [_rdOutlineView setFont:[NSFont systemFontOfSize:11.0f]];
        [_rdOutlineView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [_rdOutlineView setAutoresizesOutlineColumn:YES];
        
        NSTableColumn *tvc = [[NSTableColumn alloc] initWithIdentifier:@"source"];
        RDSourceListCell *proto = [[RDSourceListCell alloc] init];
        [proto setFont:[NSFont systemFontOfSize:11.0f]];
        [tvc setDataCell:proto];
        [proto release];
        if ([[RDNestedViewManager manager] isTiger])
            [(id)tvc setResizingMask:(1 << 0)];
        else
            [tvc setResizable:YES];
        [_rdOutlineView addTableColumn:tvc];
        [_rdOutlineView setOutlineTableColumn:tvc];
        [_rdOutlineView sizeLastColumnToFit];

        NSClipView *clipView = [[NSClipView alloc] initWithFrame:scrollRect];
        [clipView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [clipView setAutoresizesSubviews:YES];
        [clipView setDocumentView:_rdOutlineView];
        [clipView setFrame:scrollRect];

        scrollRect.origin.y += 23;
        _rdScrollView = [[NSScrollView alloc] initWithFrame:scrollRect];
        [_rdScrollView setContentView:clipView];
        [_rdScrollView setAutoresizesSubviews:YES];
        [_rdScrollView setAutohidesScrollers:YES];
        [_rdScrollView setHasVerticalScroller:YES];
        [_rdScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        
        _rdOutlineContainer = [[RBSplitSubview alloc] initWithFrame:outlineFrame];        
        [_rdOutlineContainer setAutoresizesSubviews:YES];
        [_rdOutlineContainer addSubview:_rdScrollView];        
        [_rdOutlineContainer setCanCollapse:YES];
        [_rdOutlineContainer setAutoresizingMask:(NSViewHeightSizable | NSViewMaxXMargin)];
        [self addSubview:_rdOutlineContainer atPosition:0];
        [_rdOutlineView setHeaderView:nil];
        [_rdOutlineView sizeToFit];
        
        NSRect buttonRect = outlineFrame;
        buttonRect.size.height = 23;
        
        _rdBottomBar = [[RSGradientSquareButton alloc] initWithFrame:buttonRect];
        [_rdBottomBar setTitle:@""];
        [_rdBottomBar setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)]; 
        [_rdBottomBar setHasThumb:YES];
        [_rdOutlineContainer addSubview:_rdBottomBar];
        
        _rdContentContainer = [[RBSplitSubview alloc] initWithFrame:tabviewFrame];

        tabviewFrame.origin.x = 0;

        _rdTabView = [[NSTabView alloc] initWithFrame:tabviewFrame];
        [_rdTabView setTabViewType:NSNoTabsNoBorder];
        [_rdTabView setAutoresizesSubviews:YES];
        [_rdTabView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

        [_rdContentContainer setAutoresizesSubviews:YES];
        [_rdContentContainer addSubview:_rdTabView];
        [_rdContentContainer setCanCollapse:NO];        
        [_rdContentContainer setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [self addSubview:_rdContentContainer atPosition:1];
        
        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(1.0,1.0)] autorelease]; 
        [image lockFocus]; 
        [[NSColor clearColor] set]; 
        NSRectFill(NSMakeRect(0.0,0.0,1.0,1.0)); 
        [image unlockFocus]; 
        [image setFlipped:YES]; 
        [self setDivider:image]; 
        [self setDividerThickness:0.5]; 
        [self setBackground:[NSColor lightGrayColor]];
        [self restoreState:YES];
        
        _rdBottomBarLastClick = 0;
                        
        [self setDelegate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewChanged:) name:@"NSViewFrameDidChangeNotification" object:_rdScrollView];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_rdSaveID release];

    if (_rdViewCollection) 
        [_rdViewCollection release];
    
    if (_rdTabView)
        [_rdTabView release];
        
    if (_rdOutlineView)
        [_rdOutlineView release];   

    if (_rdScrollView)
        [_rdScrollView release];

    if (_rdOutlineContainer)
        [_rdOutlineContainer release];
        
    if (_rdContentContainer)
        [_rdContentContainer release];
        
    if (_rdBottomBar)
        [_rdBottomBar release];

    [super dealloc];
}

- (void)drawRect:(NSRect)rect 
{
    [super drawRect:rect];
}

#pragma mark Slider Interface

- (unsigned int)splitView:(RBSplitView*)sender dividerForPoint:(NSPoint)point inSubview:(RBSplitSubview*)subview {
    if (subview==_rdOutlineContainer) {
        if ([_rdBottomBar mouseInThumb:[_rdBottomBar convertPoint:point fromView:sender]]) {
            return 0;   
        }
    }
    return NSNotFound;
}

#pragma mark Nested View Display Functions

- (NSRect) contentFrame
{
    return [_rdTabView frame];
}

- (NSView *) contentView
{
    return _rdTabView;
}

- (NSOutlineView *) outlineView
{
    return _rdOutlineView;
}

- (BOOL) selectView:(id <RDNestedViewDescriptor>)view
{
    if (!view)
        return NO;
        
    NSTabViewItem *tvi = [self itemForView:view];
    if (!tvi)
        return NO;
        
    int row = [_rdOutlineView rowForItem:view];

    if (row == -1) {
        [self expandToDisplayView:view];
        row = [_rdOutlineView rowForItem:view];
    }

    if (row >= 0) {        
        [_rdTabView selectTabViewItem:tvi];
        [_rdTabView setNeedsDisplay:YES];
        [_rdOutlineView selectRow:row byExtendingSelection:NO];
        [[RDNestedViewManager manager] viewReceivedFocus:view];
        return YES;
    }
    
    return NO;
}

- (void) view:(id <RDNestedViewDescriptor>)aView hasActivity:(BOOL) activity
{
    if (!aView)
        return;
        
    if ([_rdOutlineView rowForItem:aView] != -1)
        [_rdOutlineView reloadItem:aView];
    else
        [_rdOutlineView reloadData];
}

- (id <RDNestedViewDescriptor>) selectedView
{
    int selected = [_rdOutlineView selectedRow];
    if (selected == -1) {
        [self resynchSelection];
        return nil;
    }
    
    id <RDNestedViewDescriptor> curView = [_rdOutlineView itemAtRow:selected];
    return curView;
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

- (void) buildTabViewsFor:(id <RDNestedViewDescriptor>) aView
{
    if ([aView view]) {    
        NSTabViewItem *tvi = [[NSTabViewItem alloc] initWithIdentifier:aView];
        [tvi setView:[aView view]];
        [_rdTabView addTabViewItem:tvi];
    }
}

- (void) removeTabViewsFor:(id <RDNestedViewDescriptor>) aView
{
    NSTabViewItem *tvi = [self itemForView:aView];
    if (tvi) {
        [_rdTabView removeTabViewItem:tvi];
    }
}


- (void) collection:(RDNestedViewCache *)collection hasUpdatedAddingView:(id <RDNestedViewDescriptor>)aView
{
    if (!aView)
        return;
    
    [self buildTabViewsFor:aView];
    
    [_rdOutlineView reloadData];
    [_rdOutlineView sizeLastColumnToFit];
    
    NSMutableString *tempString = [[aView viewPath] mutableCopy];
    NSRange lastPath = [tempString rangeOfString:@":" options:NSBackwardsSearch];
    
    if (lastPath.length) {
        [tempString replaceCharactersInRange:NSMakeRange(lastPath.location,[tempString length] - lastPath.location) withString:@""];
        
        id <RDNestedViewDescriptor> parent = [[self collection] getViewByPath:tempString];
        if (parent) {
            BOOL shouldBeExpanded = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"lemuria.itemExpanded.%@.%@", [(RDNestedViewWindow *)[self window] windowUID], [parent viewPath]]];
            if (shouldBeExpanded) {
                [_rdOutlineView expandItem:parent];
            }            
        }
    }
    BOOL shouldBeExpanded = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"lemuria.itemExpanded.%@.%@", [(RDNestedViewWindow *)[self window] windowUID], [aView viewPath]]];
    if (shouldBeExpanded)
        [_rdOutlineView expandItem:aView];
    [tempString release];

    [self performSelector:@selector(resynchSelection) withObject:nil afterDelay:0.3f];
    [_rdTabView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}

- (void) collection:(RDNestedViewCache *)collection hasUpdatedRemovingView:(id <RDNestedViewDescriptor>)aView
{
    if (!aView)
        return;
    
    if (_rdLastSelected == aView) {
        _rdLastSelected = nil;
    }

    [self removeTabViewsFor:aView];
    [_rdOutlineView reloadData];
    [_rdOutlineView sizeLastColumnToFit];
    [self resynchSelection];
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
    int row = [_rdOutlineView selectedRow];
    
    row++;
    while ((row < [_rdOutlineView numberOfRows]) && [[_rdOutlineView itemAtRow:row] isKindOfClass:[RDNestedViewPlaceholder class]])
        row++;
    
    if (row >= [_rdOutlineView numberOfRows]) {
        row = 0;
    }
    
    return [_rdOutlineView itemAtRow:row];
}

- (id <RDNestedViewDescriptor>) previousView
{
    int row = [_rdOutlineView selectedRow];
    
    row--;
    while ((row >= 0) && [[_rdOutlineView itemAtRow:row] isKindOfClass:[RDNestedViewPlaceholder class]])
        row--;
    
    if (row < 0) {
        row = [_rdOutlineView numberOfRows] - 1;
    }
    
    return [_rdOutlineView itemAtRow:row];
}

- (BOOL) isViewListCollapsed
{
    return [_rdOutlineContainer isCollapsed];
}

- (void) expandViewList
{
    if (![_rdOutlineContainer isCollapsed])
        return;

    float dimension = [_rdOutlineContainer dimension];
    NSRect windowRect = [[self window] frame];
    float divWidth = [self dividerThickness];
    windowRect.size.width += dimension + divWidth + 5;

    [[self window] setFrame:windowRect display:YES animate:NO];
    [_rdOutlineContainer expandWithAnimation:NO withResize:NO];
    [_rdOutlineView sizeLastColumnToFit];
}

- (void) collapseViewList
{
    if ([_rdOutlineContainer isCollapsed])
        return;
    
    NSRect windowRect = [[self window] frame];
    NSRect oldRect = [_rdOutlineContainer frame];

    windowRect.size.width -= oldRect.size.width;
    [_rdOutlineContainer collapseWithAnimation:NO withResize:NO];
    [[self window] setFrame:windowRect display:YES animate:NO];
}



#pragma mark Internal Functions

- (NSTabViewItem *) itemForView: (id <RDNestedViewDescriptor>) view
{
    NSEnumerator *viewEnum = [[_rdTabView tabViewItems] objectEnumerator];
    
    id walk;
    NSTabViewItem *result = nil;
    
    while (!result && (walk = [viewEnum nextObject])) {
        NSTabViewItem *tvi = (NSTabViewItem *)walk;
        
        id <RDNestedViewDescriptor> nestview = [tvi identifier];
        if ([[nestview viewPath] isEqualToString:[view viewPath]]) {
            result = tvi;
        }
    }

    return result;
}

- (void) expandToDisplayView:(id <RDNestedViewDescriptor>) view
{
    NSArray *pathElements = [[view viewPath] componentsSeparatedByString:@":"];
    NSMutableString *tempString = [[NSString string] mutableCopy];
    
    id walk;
    NSEnumerator *pathEnum = [pathElements objectEnumerator];
    
    while (walk = [pathEnum nextObject]) {
        if (![tempString isEqualToString:@""])
            [tempString appendString:@":"];
        [tempString appendString:walk];
        
        id <RDNestedViewDescriptor> tempView = [_rdViewCollection getViewByPath:tempString];
        if (tempView && ([_rdOutlineView rowForItem:tempView] != -1) && [_rdOutlineView isExpandable:tempView] && ![_rdOutlineView isItemExpanded:tempView]) {
            @try {
                [_rdOutlineView expandItem:tempView];
            }
            @catch (NSException *e) {
            
            }
            @finally {
            
            }
        }
    }
}

- (void) resynchSelection
{
    BOOL fallback = YES;

    [_rdOutlineView sizeLastColumnToFit];
    if (_rdLastSelected) {
        if ([_rdOutlineView rowForItem:_rdLastSelected] != -1) {
            if ([_rdLastSelected view]) {
                fallback = NO;
                [self selectView:_rdLastSelected];
            }
        }
    }

    if (fallback) {
        id <RDNestedViewDescriptor> firstReal = [_rdViewCollection firstRealView];
        
        if (firstReal) {
            [self selectView:firstReal];
        }
    }
}

- (void) resynchViews
{
    [_rdOutlineView reloadData];
    [self resynchSelection];
}

#pragma mark Outline View Datasource Protocol

- (id) outlineView:(NSOutlineView *)view child:(int) child ofItem:(id) item
{
    NSArray *array = nil;
    
    if (!item)
        array = [[self collection] topLevel];
    
    if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)])
        array = [item subviewDescriptors];
    
    if (array) {
        if (child >= [array count])
            return nil;
        if (child < 0)
            return nil;
        else
            return [array objectAtIndex:child];
    }
    else
        return nil;
    
}

- (BOOL) outlineView:(NSOutlineView *)view isItemExpandable:(id) item
{
    NSArray *array = nil;
    
    if (!item)
        array = [[self collection] topLevel];
    
    if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)])
        array = [item subviewDescriptors];
    
    if (array) {
        if ([array count] != 0)
            return YES;
        else
            return NO;
    }
        
    return NO;
}

- (int) outlineView:(NSOutlineView *)view numberOfChildrenOfItem:(id) item
{
    NSArray *array = nil;
    
    if (!item)
        array = [[self collection] topLevel];
    
    if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)])
        array = [item subviewDescriptors];
        
    if (array)
        return [array count];
    else
        return 0;
}

#pragma mark Outline View Delegate Methods

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    int selected = [_rdOutlineView selectedRow];

    if (selected != -1) {
        id item = [_rdOutlineView itemAtRow:selected];
        
        _rdLastSelected = item;
    }
    
    [self resynchSelection];
}

- (BOOL)outlineView:(NSOutlineView *)view shouldSelectItem:(id) item
{
    if (!item) {
        return NO;
    }
    
    if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
        id <RDNestedViewDescriptor> nvd = item;
        
        if ([nvd view])
            return YES;
        else
            return NO;
    }
    
    return NO;
}

- (void) outlineViewItemDidExpand:(NSNotification *) event
{
    id <RDNestedViewDescriptor> view = [[event userInfo] objectForKey:@"NSObject"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[NSString stringWithFormat:@"lemuria.itemExpanded.%@.%@", [(RDNestedViewWindow *)[self window] windowUID], [view viewPath]]];
    [self resynchSelection];
    [_rdTabView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
    [_rdOutlineView sizeLastColumnToFit];
}

- (void) outlineViewItemDidCollapse:(NSNotification *) event
{
    id <RDNestedViewDescriptor> view = [[event userInfo] objectForKey:@"NSObject"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[NSString stringWithFormat:@"lemuria.itemExpanded.%@.%@", [(RDNestedViewWindow *)[self window] windowUID], [view viewPath]]];
    [self resynchSelection];
    [_rdTabView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
    [_rdOutlineView sizeLastColumnToFit];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}


- (void) outlineView:(NSOutlineView *) outlineView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn item:(id) item 
{
    if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)] && [(NSObject *)cell isKindOfClass:[RDSourceListCell class]]) {
        id <RDNestedViewDescriptor> nvd = (id <RDNestedViewDescriptor>)item;

        RDSourceListCell *slc = (RDSourceListCell *)cell;
        
        [slc setTitle:[nvd viewName]];
        if ([outlineView isItemExpanded:item])
            [slc setStatusNumber:[[RDNestedViewManager manager] activityCountSelf:nvd]];
        else
            [slc setStatusNumber:[[RDNestedViewManager manager] activityCount:nvd]];

        if ([nvd view])
            [slc setEnabled:YES];
        else
            [slc setEnabled:NO];
    }
}

- (float) outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id) item
{
    int row = [outlineView rowForItem:item];
    int level = [outlineView levelForRow:row];
    BOOL allSmall = [[NSUserDefaults standardUserDefaults] boolForKey:@"lemuria.display.smallicons"];
    
    if (level || allSmall)
        return 16.0;
    else
        return 32.0;
}

- (id) outlineView:(NSOutlineView *) outlineView objectValueForTableColumn:(NSTableColumn *) tableColumn byItem:(id) item 
{
    int row = [outlineView rowForItem:item];
    int level = [outlineView levelForRow:row];
    BOOL allSmall = [[NSUserDefaults standardUserDefaults] boolForKey:@"lemuria.display.smallicons"];

	float maxSideSize = (level || allSmall) ? 16.0 : 32.0;
	NSImage *org = [item viewIcon];

	if( [org size].width > maxSideSize || [org size].height > maxSideSize ) {
		NSImage *ret = [[[item viewIcon] copyWithZone:nil] autorelease];
		[ret setScalesWhenResized:YES];
		[ret setSize:NSMakeSize( maxSideSize, maxSideSize )];
		org = ret;
	}

	return org;
}

- (void) outlineView:(NSOutlineView *)outlineView cannotHandleEvent:(NSEvent *)theEvent
{
    NSTabViewItem *tvi = [_rdTabView selectedTabViewItem];
    if (tvi && [tvi view]) {
        [[_rdTabView window] makeFirstResponder:[tvi view]];
        [[tvi identifier] viewWasFocused];
        NSResponder *responder = [[_rdTabView window] firstResponder];
        if (responder) {
            [responder keyDown:theEvent];
        }
    }
}

- (void) mouseMoved:(NSEvent *)theEvent
{
    [_rdOutlineView mouseMoved:theEvent];
}

- (BOOL) resignFirstResponder
{
    return NO;
}

#pragma mark Split View Delegate Functions

- (void) scrollViewChanged:(NSNotification *) notification
{
    float width = [[notification object] frame].size.width;

    NSString *myString = [NSString stringWithFormat:@"%f", width];
    [[NSUserDefaults standardUserDefaults] setObject:myString forKey:_rdSaveID];
}

- (BOOL)splitView:(RBSplitView*)sender shouldResizeWindowForDivider:(unsigned int)divider betweenView:(RBSplitSubview*)leading andView:(RBSplitSubview*)trailing willGrow:(BOOL)grow {
	return YES;
}


@end
