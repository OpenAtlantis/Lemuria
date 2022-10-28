//
//  RDNestedViewManager.m
//  RDNestingViewsTest
//
//  Created by Rachel Blackman on 2/4/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDNestedViewManager.h"
#import "RDNestedOutlineView.h"
#import "RDNestedTabView.h"
#import "RDNestedTabBarView.h"
#import "RDNestedSourceView.h"
#import "NSApplicationWindowAtPoint.h"
#import "RDNestedViewCollection.h"

@implementation RDNestedViewManager

#pragma mark Initialization

static RDNestedViewManager *sManager = nil;

+ (RDNestedViewManager *) manager
{
    if (!sManager) {
        sManager = [[RDNestedViewManager alloc] init];
    }
    
    return sManager;
}

- (id) init
{
    _rdAllViews = [[NSMutableArray alloc] init];
    _rdActiveViews = [[NSMutableArray alloc] init];
    _rdActiveViewCounts = [[NSMutableDictionary alloc] init];
    _rdWindows = [[NSMutableDictionary alloc] init];
    _rdWindowMappings = [[NSMutableDictionary alloc] init];

    NSString *displayStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"lemuria.display.style"];
    if ([displayStyle isEqualToString:@"tabbed"]) {
        _rdDisplayStyle = [RDNestedTabBarView class];
    }
    else if ([displayStyle isEqualToString:@"outline"]) {
        _rdDisplayStyle = [RDNestedOutlineView class];
    }
    else {
        _rdDisplayStyle = [RDNestedSourceView class];
    }
    
    _rdWindowIconBase = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[RDNestedViewManager class]] pathForImageResource:@"window"]];
    
    _rdUIDCounter = 0;
    
    _rdIsTerminating = NO;
    
    _rdCurView = nil;
    _rdDelegate = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidMove:) name:@"NSWindowDidMoveNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:@"NSWindowDidResizeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameKey:) name:@"NSWindowDidBecomeKeyNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appIsTerminating:) name:@"NSApplicationWillTerminate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameActive:) name:@"NSApplicationDidBecomeActiveNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameInactive:) name:@"NSApplicationDidResignActiveNotification" object:nil];

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_rdAllViews)
        [_rdAllViews release];

    if (_rdActiveViewCounts)
        [_rdActiveViewCounts release];
    
    if (_rdActiveViews)
        [_rdActiveViews release];
        
    if (_rdWindows)
        [_rdWindows release];
        
    if (_rdWindowMappings)
        [_rdWindowMappings release];
        
    [super dealloc];
}

#pragma mark Misc Stuff

- (unsigned long) uidCounter
{
    return _rdUIDCounter++;
}

#pragma mark State Management

- (void) syncDisplayClass
{
    NSString *displayStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"lemuria.display.style"];
    if ([displayStyle isEqualToString:@"tabbed"]) {
        [self setDisplayClass:[RDNestedTabView class]];
    }
    else if ([displayStyle isEqualToString:@"outline"]) {
        [self setDisplayClass:[RDNestedOutlineView class]];
    }
    else {
        [self setDisplayClass:[RDNestedSourceView class]];
    }

}

- (void) setDisplayClass:(Class) class
{
    _rdDisplayStyle = class;
    
    NSEnumerator *windowEnum = [_rdWindows objectEnumerator];
    RDNestedViewWindow *windowWalk;
    
    while (windowWalk = [windowEnum nextObject]) {
        NSView<RDNestedViewDisplay> * displayView = [[_rdDisplayStyle alloc] initWithFrame:[[windowWalk displayView] frame] forWindowID:[windowWalk windowUID]];
        
        RDNestedViewCache *oldCollection = [[windowWalk displayView] collection];
        [oldCollection retain];
        RDNestedViewCache *newCollection = [[oldCollection copy] autorelease];
        [displayView setCollection:newCollection];
        [newCollection setDelegate:displayView];
        
        [windowWalk setDisplayView:displayView];
        [displayView setNeedsDisplay:YES];
        
        NSEnumerator *viewEnum = [[newCollection realViewsFlattened] objectEnumerator];
        id<RDNestedViewDescriptor> walk;
        
        while (walk = [viewEnum nextObject]) {
            [displayView collection:newCollection hasUpdatedAddingView:walk];
        }
        [oldCollection release];
    }
}

- (void) view:(id <RDNestedViewDescriptor>)aView hasActivity:(BOOL)activity
{
    if (activity && ((aView != _rdCurView) || ![NSApp isActive])) {
        if ([aView viewUID]) {
            NSNumber *currentCount = [_rdActiveViewCounts objectForKey:[aView viewUID]];
            if (currentCount) {
                int count = [currentCount intValue] + 1;
                [_rdActiveViewCounts setObject:[NSNumber numberWithInt:count] forKey:[aView viewUID]];
            }
            else {
                [_rdActiveViewCounts setObject:[NSNumber numberWithInt:1] forKey:[aView viewUID]];
            }
            if ([_rdActiveViews containsObject:aView]) {
                RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[aView viewUID]];
                if (window) {
                    [[window displayView] view:aView hasActivity:activity];
                }                            
            }
        }

        if (![_rdActiveViews containsObject:aView]) {
            [_rdActiveViews addObject:aView];
            
            RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[aView viewUID]];
            if (window) {
                [[window displayView] view:aView hasActivity:activity];
            }            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RDLemuriaHasNewActivityNotification" object:aView];
        }
    }
    else {
        if ([aView viewUID]) 
            [_rdActiveViewCounts removeObjectForKey:[aView viewUID]];
        if ([_rdActiveViews containsObject:aView]) {
            [_rdActiveViews removeObject:aView];
            
            RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[aView viewUID]];
            if (window) {
                [[window displayView] view:aView hasActivity:activity];
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:@"RDLemuriaHasNoActivityNotification" object:aView];
        }
    }
}

- (int) activityCount:(id <RDNestedViewDescriptor>) aView
{
    int result = 0;

    if ([aView subviewDescriptors]) {
        if ([[aView subviewDescriptors] count]) {
            NSEnumerator * subviewEnum = [[aView subviewDescriptors] objectEnumerator];
            
            id walk;
            
            while (walk = [subviewEnum nextObject]) {
                result += [self activityCount:walk];
            }
        }
    }

    NSNumber *count = [_rdActiveViewCounts objectForKey:[aView viewUID]];
    if (count)
        result += [count intValue];
        
    return result;
}


- (int) activityCountSelf:(id <RDNestedViewDescriptor>) aView
{
    NSNumber *count = [_rdActiveViewCounts objectForKey:[aView viewUID]];
    if (count)
        return [count intValue];
    else
        return 0;
}

- (void) resynchWindowTitle:(RDNestedViewWindow *) window
{
    NSString *windowTitle = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"lemuria.windowName.%@", [window windowUID]]];
    
    if (!windowTitle)
        windowTitle = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    
    id <RDNestedViewDescriptor> aView = [[window displayView] selectedView];
    
    NSArray *pathComponents = [[aView viewPath] componentsSeparatedByString:@":"];
    NSString *fullTitle;
    
    if ([pathComponents count] == 1)            
        fullTitle = [NSString stringWithFormat:@"%@ - %@", windowTitle, [aView viewName]];
    else
        fullTitle = [NSString stringWithFormat:@"%@ - %@ (%@)", windowTitle, [pathComponents objectAtIndex:0], [aView viewName]];
    
    [window setTitle:fullTitle];
}

- (void) viewReceivedFocus:(id <RDNestedViewDescriptor>)aView
{
    [_rdCurView viewWasUnfocused];
    _rdCurView = aView;
    [aView viewWasFocused];
    [self view:aView hasActivity:NO];    
    
    RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[aView viewUID]];
    if (window) {
        [self resynchWindowTitle:window];
        
        NSToolbar *toolbar = [window toolbar];
        if (toolbar) {
            [toolbar validateVisibleItems];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RDLemuriaViewSelectionDidChange" object:aView];
    }
}

- (id <RDNestedViewDescriptor>) currentFocusedView
{
    if (![_rdAllViews containsObject:_rdCurView])
        _rdCurView = nil;
        
    return _rdCurView;
}

- (BOOL) hasActivity:(id <RDNestedViewDescriptor>)view
{
    if ([view subviewDescriptors]) {
        if ([[view subviewDescriptors] count]) {
            NSEnumerator * subviewEnum = [[view subviewDescriptors] objectEnumerator];
            
            id walk;
            BOOL result = NO;
            
            while (!result && (walk = [subviewEnum nextObject])) {
                result = [self hasActivity:walk];
            }
            
            return (result || [self hasActivitySelf:view]);
        }
        else
            return [self hasActivitySelf:view];
    }
    else {
        return [self hasActivitySelf:view];
    }
}

- (BOOL) hasActivitySelf:(id <RDNestedViewDescriptor>)view
{
    if ([_rdActiveViews containsObject:view])
        return YES;
    else
        return NO;
}

#pragma mark Window Management


- (BOOL) isTiger
{
/*
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *versionString = [dict objectForKey:@"ProductVersion"];
    NSArray *array = [versionString componentsSeparatedByString:@"."];
    int count = [array count];
    int major = (count >= 1) ? [[array objectAtIndex:0] intValue] : 0;
    int minor = (count >= 2) ? [[array objectAtIndex:1] intValue] : 0;
//    int bugfix = (count >= 3) ? [[array objectAtIndex:2] intValue] : 0;
    
    if (major > 10 || major == 10 && minor >= 4) {
        return YES;
    } else {
        return NO;
    }
    */
    
    SInt32 MacVersion;
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
        if (MacVersion >= 0x1040){
            return YES;
        }
    }    
    
    return NO;
}

- (BOOL) isLeopard
{
/*
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *versionString = [dict objectForKey:@"ProductVersion"];
    NSArray *array = [versionString componentsSeparatedByString:@"."];
    int count = [array count];
    int major = (count >= 1) ? [[array objectAtIndex:0] intValue] : 0;
    int minor = (count >= 2) ? [[array objectAtIndex:1] intValue] : 0;
//    int bugfix = (count >= 3) ? [[array objectAtIndex:2] intValue] : 0;
    
    if (major > 10 || major == 10 && minor >= 4) {
        return YES;
    } else {
        return NO;
    }
    */
    
    SInt32 MacVersion;
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
        if (MacVersion >= 0x1050){
            return YES;
        }
    }    
    
    return NO;
}


- (NSString *) currentWindowUID
{
    if (_rdNewWindowOpening) {
        return _rdOpeningWindowUID;
    }
    else {
        NSWindow *window = [NSApp mainWindow];
        if (window && [window isKindOfClass:[RDNestedViewWindow class]]) {
            return [(RDNestedViewWindow *)window windowUID];
        }
    }
    
    return nil;
}

- (RDNestedViewWindow *) newWindowWithName:(NSString *) name contentRect:(NSRect)rect
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _rdNewWindowOpening = YES;
    _rdOpeningWindowUID = name;
    
    float windowPosX = [defaults floatForKey:[NSString stringWithFormat:@"lemuria.windowPos.x.%@", name]];
    float windowPosY = [defaults floatForKey:[NSString stringWithFormat:@"lemuria.windowPos.y.%@", name]];
    float windowSizeW = [defaults floatForKey:[NSString stringWithFormat:@"lemuria.windowSize.width.%@", name]];
    float windowSizeH = [defaults floatForKey:[NSString stringWithFormat:@"lemuria.windowSize.height.%@", name]];
    
    if ((windowSizeW != 0.0f) && (windowSizeH != 0.0f)) {
        rect.size.width = windowSizeW;
        rect.size.height = windowSizeH;
    }
    
    if ((windowPosX != 0.0f) && (windowPosY != 0.0f)) {
        rect.origin.x = windowPosX;
        rect.origin.y = windowPosY;
    }
    
    unsigned int styleMask = (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask);
//    if ([self isTiger]) {
        styleMask = styleMask | (1 << 12);
//    }
    
    RDNestedViewWindow * window = [[RDNestedViewWindow alloc] initWithUID:name contentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];    
    [_rdWindows setValue:window forKey:name];
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(nestedWindowToolbar:)]) {
        NSToolbar *toolbar = [[self delegate] nestedWindowToolbar:[window windowUID]];
        if (toolbar) {
            [window setToolbar:toolbar];
        }
    }

    NSView<RDNestedViewDisplay> * displayView = [[_rdDisplayStyle alloc] initWithFrame:rect forWindowID:name];
    [window setDisplayView:displayView];
    
    NSString *windowTitle = [defaults stringForKey:[NSString stringWithFormat:@"lemuria.windowName.%@", name]];

    if (windowTitle)
        [window setTitle:windowTitle];
    else
        [window setTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];

    [window setDelegate:self];
    if (![NSApp keyWindow])
        [window makeKeyAndOrderFront:self];
    else
        [window orderFront:self];
    
    _rdNewWindowOpening = NO;
    _rdOpeningWindowUID = nil;    
    
    return window;
}

- (RDNestedViewWindow *) windowForUID:(NSString *) windowUID
{
    return [_rdWindows objectForKey:windowUID];
}

- (RDNestedViewWindow *) windowByName:(NSString *) name
{
    RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindows valueForKey:name];
    if (window)
        return window;
    else {
        NSRect frameRect = NSMakeRect(200,300,800,600);
    
        return [self newWindowWithName:name contentRect:frameRect];
    }
}

- (void) renameWindow:(RDNestedViewWindow *)window withTitle:(NSString *)title
{
    [[NSUserDefaults standardUserDefaults] setObject:title forKey:[NSString stringWithFormat:@"lemuria.windowName.%@", [window windowUID]]];

    [self resynchWindowTitle:window];
}

- (void) __removeWindowInternal:(RDNestedViewWindow *) window
{
    if ([_rdWindows objectForKey:[window windowUID]]) {
        [_rdWindows removeObjectForKey:[window windowUID]];
    }
}


- (void) removeWindow:(RDNestedViewWindow *) window
{
    [self __removeWindowInternal:window];
    [window close];
}

#pragma mark View Collection Management

- (void) selectView:(id <RDNestedViewDescriptor>) view
{
    RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[view viewUID]];
    
    if (window) {
        [[window displayView] selectView:view];
        [window makeKeyAndOrderFront:self];
    }
}

- (BOOL) selectNextActiveView
{
    if ([_rdActiveViews count] != 0) {
        id <RDNestedViewDescriptor> view = [_rdActiveViews objectAtIndex:0];
        
        [self selectView:view];
        return YES;
    }
    
    return NO;
}

- (NSArray *) activeViews
{
    return _rdActiveViews;
}

- (NSString *) _standardWindowForView:(id <RDNestedViewDescriptor>) view
{
    NSMutableString *tempString = [[view viewPath] mutableCopy];
    NSString *windowName = nil;
    NSRange lastPath;
    
    lastPath = [tempString rangeOfString:@":" options:NSBackwardsSearch];
    
    while (!windowName && lastPath.length) {
        [tempString replaceCharactersInRange:NSMakeRange(lastPath.location,[tempString length] - lastPath.location) withString:@""];
        
        id <RDNestedViewDescriptor> parent = [self viewByPath:tempString];
        if (parent) {
            NSWindow *window = [[parent view] window];
            if (window && [window isKindOfClass:[RDNestedViewWindow class]])
                windowName = [(RDNestedViewWindow *)window windowUID];
        }
        else {        
            windowName = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"lemuria.viewWindow.%@", tempString]];
        }
        
        lastPath = [tempString rangeOfString:@":" options:NSBackwardsSearch];
    }

    // Find our most-used window
    if (!windowName) {
        NSEnumerator *winEnum = [_rdWindows objectEnumerator];
        
        RDNestedViewWindow *winWalk;
        RDNestedViewWindow *result = nil;
        unsigned resultCount = 0;
        
        while (winWalk = [winEnum nextObject]) {
            if (result) {
                unsigned winWalkCount = [[[winWalk displayView] collection] count];
                if (winWalkCount > resultCount) {
                    result = winWalk;
                    resultCount = winWalkCount;
                }
            }
            else {
                result = winWalk;
                resultCount = [[[winWalk displayView] collection] count];
            }
        }
        
        if (result)
            windowName = [result windowUID];
    }

    // Give up
    if (!windowName)
        windowName = @"lemuria_main";
        
    return windowName;
}

- (NSString *) windowForView:(id <RDNestedViewDescriptor>) view
{
    NSString *viewLogic = [[NSUserDefaults standardUserDefaults] objectForKey:@"lemuria.window.behavior"];
    if (viewLogic && [viewLogic isEqualToString:@"contained"]) {
        return @"lemuria_main";
    }
    else if (viewLogic && [viewLogic isEqualToString:@"scattered"]) {
        NSString *windowName = [NSString stringWithFormat:@"window:%@", [view viewUID]];
     
        RDNestedViewWindow *window = [self windowByName:windowName];
        [[window displayView] collapseViewList];
        return [windowName autorelease];
    }
    else {
        return [self _standardWindowForView:view];
    }
}

- (void) addView:(id <RDNestedViewDescriptor>) view
{
    if (!view)
        return;
        
    [_rdAllViews addObject:view];
    
    // Allocate a window here
    NSString *windowName = nil; 

    if (![(NSObject *)view isKindOfClass:[RDNestedViewPlaceholder class]]) {
        windowName = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"lemuria.viewWindow.%@", [view viewPath]]];
    }

    if (!windowName)
        windowName = [self windowForView:view];
    
    RDNestedViewWindow *window = [self windowByName:windowName];
    if (window) {
        [[[window displayView] collection] addView:view];
        [_rdWindowMappings setValue:window forKey:[view viewUID]];
    }
}

- (void) removeView:(id <RDNestedViewDescriptor>) view
{
    NSArray *subviews = [view subviewDescriptors];
    
    if (subviews) {
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        
        id <RDNestedViewDescriptor> walkView;
        
        while (walkView = [viewEnum nextObject]) {
            [self removeView:walkView];
        }
    }
    
    [self view:view hasActivity:NO];    
    RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[view viewUID]];
    if (window) {
        [[[window displayView] collection] removeView:view];
    }
    
    [_rdWindowMappings removeObjectForKey:[view viewUID]];
    [_rdAllViews removeObject:view];
    [view close];
}

- (id <RDNestedViewDescriptor>) viewByPath:(NSString *) path
{
    NSEnumerator *viewEnum = [_rdAllViews objectEnumerator];
    
    id <RDNestedViewDescriptor> viewWalk;
    id <RDNestedViewDescriptor> result = nil;
    
    while (!result && (viewWalk = [viewEnum nextObject])) {
        if (![(NSObject *)viewWalk isKindOfClass:[RDNestedViewPlaceholder class]]) {
            if ([[[viewWalk viewPath] lowercaseString] isEqualToString:[path lowercaseString]])
                result = viewWalk;
        }
    }
    
    return result;
}

- (id <RDNestedViewDescriptor>) viewByUid:(NSString *) uid
{
    NSEnumerator *viewEnum = [_rdAllViews objectEnumerator];
    
    id <RDNestedViewDescriptor> viewWalk;
    id <RDNestedViewDescriptor> result = nil;
    
    while (!result && (viewWalk = [viewEnum nextObject])) {
        if (![(NSObject *)viewWalk isKindOfClass:[RDNestedViewPlaceholder class]]) {
            if ([[viewWalk viewUID] isEqualToString:uid])
                result = viewWalk;
        }
    }
    
    return result;
}


- (void) placeholderView:(id <RDNestedViewDescriptor>) view inWindow:(RDNestedViewWindow *)window
{
    [_rdWindowMappings setValue:window forKey:[view viewUID]];
}

- (void) view:(id <RDNestedViewDescriptor>) view inWindow:(RDNestedViewWindow *) window
{
    NSArray *subviews = [view subviewDescriptors];

    if (subviews) {
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        
        id <RDNestedViewDescriptor> walk;
        
        while (walk = [viewEnum nextObject]) {
            [self view:walk inWindow:window];
        }
    }
    
    [_rdWindowMappings setValue:window forKey:[view viewUID]];
    if (![(NSObject *)view isKindOfClass:[RDNestedViewPlaceholder class]]) {
        NSString *viewPath = [self windowForView:view];
        if (![viewPath isEqualToString:[window windowUID]])
            [[NSUserDefaults standardUserDefaults] setObject:[window windowUID] forKey:[NSString stringWithFormat:@"lemuria.viewWindow.%@",[view viewPath]]]; 
        else
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"lemuria.viewWindow.%@",[view viewPath]]];
    }
}

- (void) viewRequestedClose:(id <RDNestedViewDescriptor>) view
{
    BOOL skipCheck = NO;
    
    skipCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"lemuria.askViewClose"];
    if (!skipCheck) {
        if (![view isLive]) {
            skipCheck = YES;
        }
    }
    
    RDNestedViewWindow *realWindow = [_rdWindowMappings objectForKey:[view viewUID]];
    
    if (realWindow && !skipCheck) {
        NSBundle *lemuriaBundle = [NSBundle bundleForClass:[self class]];
        NSString *okString = [lemuriaBundle localizedStringForKey:@"RDOkayButton" value:@"OK" table:@"sheetinfo"];
        NSString *cancelString = [lemuriaBundle localizedStringForKey:@"RDCancelButton" value:@"Cancel" table:@"sheetinfo"];
        NSString *mainString = [lemuriaBundle localizedStringForKey:@"RDViewClose" value:@"Do you really want to close this view?" table:@"sheetinfo"];
        NSString *infoString = [view closeInfoString];
        
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        
        [alert addButtonWithTitle:okString];
        [alert addButtonWithTitle:cancelString];
        [alert setMessageText:mainString];
        [alert setInformativeText:infoString];

        [alert beginSheetModalForWindow:realWindow modalDelegate:self didEndSelector:@selector(closeViewSheetDidEnd:returnCode:contextInfo:) contextInfo:view];
    }
    else {
        [self removeView:view];
    }
}

#pragma mark Delegate Functions for Our Delegate

- (id) delegate
{
    return _rdDelegate;
}

- (void) setDelegate:(id) delegate
{
    _rdDelegate = delegate;
}

#pragma mark Delegate Functions for Things We Control

- (BOOL) windowShouldClose:(NSWindow *) window
{
    if ([window isKindOfClass:[RDNestedViewWindow class]]) {
        BOOL askMe = NO;
    
        RDNestedViewWindow *realWindow = (RDNestedViewWindow *)window;
        
        NSArray *subviews = [[[realWindow displayView] collection] topLevel];
        if (subviews && [subviews count]) {
            NSEnumerator *viewEnum = [subviews objectEnumerator];
            
            id <RDNestedViewDescriptor> walk;
            
            while (walk = [viewEnum nextObject]) {
                if ([walk isLive]) {
                    askMe = YES;
                }
            }
            
            if (askMe) {
                NSBundle *lemuriaBundle = [NSBundle bundleForClass:[self class]];
                NSString *okString = [lemuriaBundle localizedStringForKey:@"RDOkayButton" value:@"OK" table:@"sheetinfo"];
                NSString *cancelString = [lemuriaBundle localizedStringForKey:@"RDCancelButton" value:@"Cancel" table:@"sheetinfo"];
                NSString *mainString = [lemuriaBundle localizedStringForKey:@"RDWindowClose" value:@"Do you really want to close this window?" table:@"sheetinfo"];
                NSString *infoString = [lemuriaBundle localizedStringForKey:@"RDWindowCloseInfo" value:@"Closing a window will close all the views within it." table:@"sheetinfo"];
            
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                
                [alert addButtonWithTitle:okString];
                [alert addButtonWithTitle:cancelString];
                [alert setMessageText:mainString];
                [alert setInformativeText:infoString];
                
                [alert beginSheetModalForWindow:realWindow modalDelegate:self didEndSelector:@selector(closeWindowSheetDidEnd:returnCode:contextInfo:) contextInfo:realWindow];
                return NO;
            }
            else
                return YES;
        }
        else
            return YES;
    }
    else 
        return YES;
}

- (void) windowWillClose:(NSNotification *)notification
{
    NSWindow *window = (NSWindow *)[notification object];
    
    if ([window isKindOfClass:[RDNestedViewWindow class]]) {
        RDNestedViewWindow *realWin = (RDNestedViewWindow *)window;
        
        if (![realWin isClosing]) {
            [realWin setIsClosing:YES];
            [self __removeWindowInternal:realWin];
            [realWin setIsClosing:NO];
        }
    }
}

- (void) windowDidResize:(NSNotification *)notification
{
    NSWindow *window = (NSWindow *)[notification object];
    
    if ([window isKindOfClass:[RDNestedViewWindow class]]) {
        NSRect windowRect = [[window contentView] frame];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setFloat:windowRect.size.width forKey:[NSString stringWithFormat:@"lemuria.windowSize.width.%@", [(RDNestedViewWindow *)window windowUID]]];
        [defaults setFloat:windowRect.size.height forKey:[NSString stringWithFormat:@"lemuria.windowSize.height.%@", [(RDNestedViewWindow *)window windowUID]]];
    }
}

- (void) windowDidMove:(NSNotification *)notification
{
    NSWindow *window = (NSWindow *)[notification object];
    
    if ([window isKindOfClass:[RDNestedViewWindow class]]) {
        NSRect windowRect = [window frame];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setFloat:windowRect.origin.x forKey:[NSString stringWithFormat:@"lemuria.windowPos.x.%@", [(RDNestedViewWindow *)window windowUID]]];
        [defaults setFloat:windowRect.origin.y forKey:[NSString stringWithFormat:@"lemuria.windowPos.y.%@", [(RDNestedViewWindow *)window windowUID]]];
    }
}

- (void) windowBecameKey:(NSNotification *)notification
{
    NSWindow *window = [notification object];
    
    if (![window isKindOfClass:[RDNestedViewWindow class]]) {
        _rdCurView = nil;
    }
    else {
        id <RDNestedViewDisplay> display = [(RDNestedViewWindow *)window displayView];
        if (display) {
            _rdCurView = [display selectedView];
            [self viewReceivedFocus:_rdCurView];
        }
    }
}

- (void) appIsTerminating:(NSNotification *)notification
{
    _rdIsTerminating = YES;
}

- (void) appBecameActive:(NSNotification *)notification
{
    NSWindow *window = [NSApp keyWindow];
    
    if (window) {
        if (![window isKindOfClass:[RDNestedViewWindow class]]) {
            _rdCurView = nil;
        }
        else {
            id <RDNestedViewDisplay> display = [(RDNestedViewWindow *)window displayView];
            if (display) {
                _rdCurView = [display selectedView];
                if (_rdCurView) {
                    [self viewReceivedFocus:_rdCurView];
                }
            }
        }
    }
/*    else {
        NSArray *windows = [NSApp windows];
        NSMutableArray *visibleWindows = [[NSMutableArray alloc] init];
        
        NSEnumerator *winEnum = [windows objectEnumerator];
        NSWindow *windowWalk;
        
        while (windowWalk = [winEnum nextObject]) {
            if ([windowWalk isVisible])
                [visibleWindows addObject:windowWalk];
        }
        
        if (visibleWindows && [visibleWindows count]) {
            NSWindow *window = [visibleWindows objectAtIndex:0];
            
            if (window) {
                [window makeKeyAndOrderFront:self];
                if (![window isKindOfClass:[RDNestedViewWindow class]]) {
                    _rdCurView = nil;
                }
                else {
                    id <RDNestedViewDisplay> display = [(RDNestedViewWindow *)window displayView];
                    if (display) {
                        _rdCurView = [display selectedView];
                        if (_rdCurView) {
                            [self viewReceivedFocus:_rdCurView];
                        }
                    }
                }
            }
        }
    } */
}

- (void) appBecameInactive:(NSNotification *)notification
{
    _rdCurView = nil;
}

#pragma mark Sheet Callbacks

- (void)closeWindowSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
    if (returnCode == NSAlertFirstButtonReturn) {
        id item = (id) contextInfo;
        
        if ([item isKindOfClass:[RDNestedViewWindow class]]) {
            [self removeWindow:(RDNestedViewWindow *)item];
        }
    }
}


- (void)closeViewSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
    if (returnCode == NSAlertFirstButtonReturn) {
        id item = (id)contextInfo;
        
        if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
            [self removeView:item];
        }
    }
}

#pragma mark Drag and Drop Support

- (BOOL) beginDraggingView:(id <RDNestedViewDescriptor>) view onEvent:(NSEvent *)anEvent
{
    RDNestedViewWindow *window = (RDNestedViewWindow *)[_rdWindowMappings valueForKey:[view viewUID]];
    
    NSImage *appImage = [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]];
    [appImage setSize:NSMakeSize(45,45)];

    if (window) {
        [window setIsDragSource:YES];
        [[[window displayView] collection] removeView:view];
        [_rdWindowMappings removeObjectForKey:[view viewUID]];
    }    

    NSImage *dragImage = [[NSImage alloc] initWithSize:[_rdWindowIconBase size]];
    
    NSRect imageRect = NSMakeRect(0,0,0,0);
    imageRect.size = [_rdWindowIconBase size];
    NSRect appRect = NSMakeRect(0,0,0,0);
    appRect.size = [appImage size];
    
    NSPoint appPoint = NSMakePoint(0,0);
    appPoint.x = (imageRect.size.width / 2) - (appRect.size.width / 2);
    appPoint.y = (imageRect.size.height / 2) - (appRect.size.height / 2) - 2.5f;
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:13.0f],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:[view viewName] attributes:attrs];
    
    NSSize textSize = [titleString size];
    NSPoint textPoint = NSMakePoint(0,0);
    textPoint.x = (imageRect.size.width / 2) - (textSize.width / 2);
    textPoint.y = (imageRect.size.height / 2) - (textSize.height / 2) - 2.5f;
    
    [dragImage lockFocus];
    [_rdWindowIconBase drawAtPoint:NSMakePoint(0,0) 
                          fromRect:imageRect 
                         operation:NSCompositeCopy 
                          fraction:1.0f];
    [appImage  drawAtPoint:appPoint 
               fromRect:appRect 
               operation:NSCompositeSourceOver
               fraction:0.4f];
    [titleString drawAtPoint:textPoint];
    [dragImage unlockFocus];

    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray array] owner:self];
    [pboard setData:[[view viewPath] dataUsingEncoding:NSUTF8StringEncoding] forType:NSPasteboardTypeString];
        
    NSSize dragOffset = NSMakeSize(0,0);
    NSPoint dragPoint = [anEvent locationInWindow];
    
    dragPoint.x -= 5.0f;
    dragPoint.y -= (imageRect.size.height - 15.0f);

    _rdDraggedItem = view;
    _rdDragRect = [[window contentView] frame];
    _rdDragWindow = window;

    [window dragImage:dragImage
                   at:dragPoint
               offset:dragOffset
                event:anEvent
           pasteboard:pboard
               source:self
            slideBack:NO];

            
    return YES;
}

- (BOOL) isDragging
{
    return (_rdDraggedItem != nil);
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{	
    NSWindow *window = [NSApp windowAtPoint:aPoint ignoreWindow:nil];

    if (!window || (![window isKindOfClass:[RDNestedViewWindow class]])) {
        NSString *windowUID = [NSString stringWithFormat:@"lemuria_window:%f.%lu",
            [NSDate timeIntervalSinceReferenceDate], [[RDNestedViewManager manager] uidCounter]];
            
        NSRect frame = _rdDragRect;
        frame.origin = aPoint;
            
        RDNestedViewWindow *nestedWin = [self newWindowWithName:windowUID contentRect:frame];
        [self view:_rdDraggedItem inWindow:nestedWin];
        [nestedWin setAcceptsMouseMovedEvents:YES];
        [[[nestedWin displayView] collection] addView:_rdDraggedItem];
        [[nestedWin displayView] selectView:_rdDraggedItem];
        [nestedWin makeKeyAndOrderFront:self];
    }
    else {
        RDNestedViewWindow *nestedWin = (RDNestedViewWindow *)window;
        if (nestedWin == _rdDragWindow) {
            sleep(1); // Ensure we don't lose our view.
        }
        [self view:_rdDraggedItem inWindow:nestedWin];
        [nestedWin setAcceptsMouseMovedEvents:YES];
        [[[nestedWin displayView] collection] addView:_rdDraggedItem];
        [[nestedWin displayView] selectView:_rdDraggedItem];
        [nestedWin makeKeyAndOrderFront:self];
    }

    [_rdDragWindow setIsDragSource:NO];
    _rdDraggedItem = nil;
    _rdDragWindow = nil;
}

- (void) updateAllViews
{
    NSEnumerator *winEnum = [_rdWindows objectEnumerator];
    RDNestedViewWindow *window;
    
    while (window = [winEnum nextObject]) {
        [[[window displayView] collection] sortAllViews];
    }
}

- (void) setBordered:(BOOL)bordered
{
    [[NSUserDefaults standardUserDefaults] setBool:bordered forKey:@"lemuria.content.bordered"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RDLemuriaUpdatedSettingsNotification" object:self];
}

@end
