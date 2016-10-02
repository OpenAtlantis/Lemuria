//
//  RDNestedViewCollection.m
//  RDNestingViewsTest
//
//  Created by Rachel Blackman on 1/4/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDNestedViewCollection.h"
#import "RDNestedViewManager.h"
#import "RDNestedViewWindow.h"

static NSImage *s_folderIcon = nil;

#pragma mark Helper Functions

int compareViews(id view1, id view2, void *context)
{
    unsigned weight1 = [view1 viewWeight];
    unsigned weight2 = [view2 viewWeight];
    
    if (weight1 < weight2) {
        return NSOrderedDescending;
    }
    else if (weight1 > weight2) {
        return NSOrderedAscending;
    }
    else {
        return [[view1 viewName] compare:[view2 viewName]];
    }
}

@implementation RDNestedViewPlaceholder

- (id) initWithPath:(NSString *)path forSubviews:(NSArray *)subviews
{
    if (subviews) {
        _rdSubviews = [[[NSMutableArray alloc] initWithArray:subviews] retain];
    }
    else {
        _rdSubviews = [[[NSMutableArray alloc] init] retain];
    }
    
    RDNestedViewManager *manager = [RDNestedViewManager manager];
    if ([manager delegate] && [[manager delegate] respondsToSelector:@selector(weightForView:)]) {
        _rdWeight = [[manager delegate] weightForView:path];
    }
    else
        _rdWeight = 1;
    _rdViewPath = [[path copyWithZone:nil] retain];
    _rdViewName = [[[[path componentsSeparatedByString:@":"] lastObject] description] retain];
    _rdViewUID = [[NSString stringWithFormat:@"placeholderView:%lu.%lu", [NSDate timeIntervalSinceReferenceDate], [[RDNestedViewManager manager] uidCounter]] retain];
    
    return self;
}

- (void) dealloc
{
    [self close];
    [_rdSubviews release];
    [_rdViewPath release];
    [_rdViewName release];
    [_rdViewUID release];
    
    [super dealloc];
}

- (void) close
{
    // Nothing
}

- (NSString *) viewUID
{
    return _rdViewUID;
}

- (NSString *) viewName
{
    return _rdViewName;
}

- (NSString *) viewPath
{
    return _rdViewPath;
}

- (NSImage *) viewIcon
{
    if (!s_folderIcon) {
        s_folderIcon = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[RDNestedViewManager class]] pathForImageResource:@"folder"]];
    }
    return s_folderIcon;
}

- (BOOL) isFolder
{
    return YES;
}

- (NSArray *) subviewDescriptors
{
    return _rdSubviews;
}

- (NSView *) view
{
    return nil;
}

- (BOOL) isLive
{
    BOOL result = NO;
    
    NSEnumerator *enumerator = [_rdSubviews objectEnumerator];
    id walk;
    while ((walk = [enumerator nextObject]) && !result) {
        if ([walk conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
            if ([walk isLive])
                result = YES;
        }
    }
    
    return result;
}

- (BOOL) isLiveSelf
{
    return NO;
}

- (BOOL) hasActivitySelf
{
    return NO;
}

- (BOOL) hasActivity
{
    BOOL result = NO;
    
    NSEnumerator *enumerator = [_rdSubviews objectEnumerator];
    id walk;
    while ((walk = [enumerator nextObject]) && !result) {
        if ([walk conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
            if ([walk hasActivity])
                result = YES;
        }
    }
    
    return result;
}

- (BOOL) addSubview:(id <RDNestedViewDescriptor>)newView
{
    if (!newView)
        return NO;

    NSString *basePath = [newView viewPath];
    NSRange finalBlock = [basePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"] options:NSBackwardsSearch];
    basePath = [basePath substringWithRange:NSMakeRange(0,finalBlock.location)];

    if (![basePath isEqualToString:[self viewPath]])
        return NO;
        
    [_rdSubviews addObject:newView];
    [_rdSubviews sortUsingFunction:compareViews context:NULL];
    return YES;
}

- (BOOL) removeSubview:(id <RDNestedViewDescriptor>)newView
{
    if (!newView)
        return NO;

    NSString *basePath = [newView viewPath];
    NSRange finalBlock = [basePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"] options:NSBackwardsSearch];
    basePath = [basePath substringWithRange:NSMakeRange(0,finalBlock.location)];

    if (![basePath isEqualToString:[self viewPath]])
        return NO;

    [_rdSubviews removeObject:newView];
    return YES;
}

- (unsigned) viewWeight
{
    return _rdWeight;
}

- (NSString *) closeInfoString
{
    NSBundle *lemuriaBundle = [NSBundle bundleForClass:[self class]];
    NSString *infoString = nil;
    if (lemuriaBundle)
        infoString = [[[lemuriaBundle localizedStringForKey:@"RDViewGeneric" value:@"Closing this view will close all views beneath it." table:@"sheetinfo"] retain] autorelease];
    else 
        infoString = @"Closing this view will close all views beneath it.";
    
    return infoString;
}

- (void) sortSubviews
{
    RDNestedViewManager *manager = [RDNestedViewManager manager];
    if ([manager delegate] && [[manager delegate] respondsToSelector:@selector(weightForView:)]) {
        _rdWeight = [[manager delegate] weightForView:_rdViewPath];
    }
    [_rdSubviews sortUsingFunction:compareViews context:NULL];
}

- (void) viewWasFocused
{
    // This never happens, so we do nothing.
}

- (void) viewWasUnfocused
{
    // This never happens, so we do nothing.
}


@end

@implementation RDNestedViewCache

- (id) init
{
    _rdCachedObjects = [[[NSMutableArray alloc] init] retain];
    _rdDelegate = nil;
    return self;
}

- (void) dealloc
{
    [_rdCachedObjects release];
    [super dealloc];
}

- (id) copyWithZone:(NSZone *) zone 
{
    RDNestedViewCache *newCache = [[RDNestedViewCache allocWithZone:zone] init];

    [newCache->_rdCachedObjects release];
    newCache->_rdCachedObjects = [[NSMutableArray alloc] initWithArray:_rdCachedObjects];
    
    return newCache;
}

- (NSArray *) topLevel
{
    return (NSArray *)_rdCachedObjects;
}

- (void) realViewsRecursive:(NSArray *)array addToArray:(NSMutableArray *)results
{
    NSEnumerator *arrayEnum = [array objectEnumerator];
    
    id <RDNestedViewDescriptor> walk;
    
    while (walk = [arrayEnum nextObject]) {
        if ([walk view]) {
            [results addObject:walk];
        }
        if ([walk subviewDescriptors]) {
            [self realViewsRecursive:[walk subviewDescriptors] addToArray:results];
        }
    }
}

- (NSArray *) realViewsFlattened
{
    NSMutableArray *views = [NSMutableArray array];

    [self realViewsRecursive:[self topLevel] addToArray:views];
    
    return [NSArray arrayWithArray:views];
}

- (id <RDNestedViewDescriptor>) getViewByPath:(NSString *)path
{
    NSEnumerator *pathEnum = [[path componentsSeparatedByString:@":"] objectEnumerator];
    id walk;
    id current = [self topLevel];
    
    while (walk = [pathEnum nextObject]) {
        NSArray *views = nil;
        
        if (current) {
            if ([current isKindOfClass:[NSArray class]])
                views = (NSArray *)current;
            else if ([current conformsToProtocol:@protocol(RDNestedViewDescriptor)])
                views = [(id <RDNestedViewDescriptor>)current subviewDescriptors];
        }
        
        if (views) {
            NSEnumerator *viewEnum = [views objectEnumerator];
            id viewWalk = nil;
            id <RDNestedViewDescriptor> viewDesc = nil;
            
            while (!viewDesc && (viewWalk = [viewEnum nextObject])) {
                if ([[(id <RDNestedViewDescriptor>)viewWalk viewName] isEqualToString:(NSString *)walk])
                    viewDesc = viewWalk;
            }
            
            current = viewDesc;
        }
    }
    
    if (current && [current conformsToProtocol:@protocol(RDNestedViewDescriptor)])
        return current;
    else
        return nil;
}

- (void) populatePath:(NSString *) path
{
    id walk;
    
    NSArray *elements = [path componentsSeparatedByString:@":"];
    NSEnumerator *pathEnum = [elements objectEnumerator];
    NSMutableString *curPath = [[NSString string] mutableCopy];
    id <RDNestedViewDescriptor> nvd = nil;
    
    while (walk = [pathEnum nextObject]) {
        if (![curPath isEqualToString:@""])
            [curPath appendString:@":"];
        
        [curPath appendString:walk];
    
        NSArray *subviews;
        if (!nvd) {
            subviews = [self topLevel];
        }
        else {
            subviews = [nvd subviewDescriptors];
        }
        
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        id viewWalk;
        id newView = nil;
        
        while (!newView && (viewWalk = [viewEnum nextObject])) {
            if ([[(id <RDNestedViewDescriptor>)viewWalk viewName] isEqualToString:walk]) {
                newView = viewWalk;
            }
        }
        
        if (!newView) {
            newView = [[RDNestedViewPlaceholder alloc] initWithPath:curPath forSubviews:nil];
            if (newView) {
                if (nvd)
                    [nvd addSubview:newView];
                else
                    [_rdCachedObjects addObject:newView];
                
                id delegate = [self delegate];
                if ([delegate isKindOfClass:[NSView class]]) {
                    NSWindow *window = [(NSView *)delegate window];
                    
                    if ([window isKindOfClass:[RDNestedViewWindow class]])
                        [[RDNestedViewManager manager] placeholderView:newView inWindow:(RDNestedViewWindow *)window];
                }
                
                [delegate collection:self hasUpdatedAddingView:newView];
            }
        }
        
        nvd = newView;
    }
    
    [_rdCachedObjects sortUsingFunction:compareViews context:NULL];
}

- (id <RDNestedViewDescriptor>) firstRealView
{
    id <RDNestedViewDescriptor> realView = nil;
    id <RDNestedViewDescriptor> curView = nil;
    
    if ([_rdCachedObjects count] == 0)
        return nil;
    
    curView = [_rdCachedObjects objectAtIndex:0];
    
    while (!realView && curView) {
        if ([curView view])
            realView = curView;
        else if ([curView subviewDescriptors] && [[curView subviewDescriptors] count]) {
            curView = [[curView subviewDescriptors] objectAtIndex:0];
        }
        else {
            curView = nil;
        }
    }

    return realView;
}

- (void) __updateDelegateAddSubviewsOf:(id <RDNestedViewDescriptor>)view
{
    if (!view)
        return;
        
    NSArray *subviews = [view subviewDescriptors];
    if (subviews) {
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        
        id <RDNestedViewDescriptor> walk;
        
        while (walk = [viewEnum nextObject]) {
            [self __updateDelegateAddSubviewsOf:walk];
        }
    }
    
    [[self delegate] collection:self hasUpdatedAddingView:view];
}

- (void) __updateDelegateRemoveSubviewsOf:(id <RDNestedViewDescriptor>)view
{
    if (!view)
        return;
        
    NSArray *subviews = [view subviewDescriptors];
    if (subviews) {
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        
        id <RDNestedViewDescriptor> walk;
        
        while (walk = [viewEnum nextObject]) {
            [self __updateDelegateRemoveSubviewsOf:walk];
        }
    }
    
    [[self delegate] collection:self hasUpdatedRemovingView:view];
}

- (void) addSubviewsOf:(id <RDNestedViewDescriptor>)srcView toView:(id <RDNestedViewDescriptor>) destView
{
    NSArray *srcSubviews = [srcView subviewDescriptors];
    NSArray *destSubviews = [destView subviewDescriptors];
    
    if (srcSubviews) {    
        NSEnumerator *srcEnum = [srcSubviews objectEnumerator];
        
        id <RDNestedViewDescriptor> walk;
        
        while (walk = [srcEnum nextObject]) {
            BOOL gotIt = NO;
            NSEnumerator *destEnum = [destSubviews objectEnumerator];
            
            id <RDNestedViewDescriptor> walk2;
            
            while (walk2 = [destEnum nextObject]) {
                if ([[walk2 viewPath] isEqualToString:[walk viewPath]]) {
                    gotIt = YES;
                    
                    if ([walk view] && ![walk2 view]) {
                        [self addSubviewsOf:walk2 toView:walk];
                        [destView removeSubview:walk];
                        [destView addSubview:walk2];
                    }
                    else {
                        [self addSubviewsOf:walk toView:walk2];
                        [srcView removeSubview:walk];                 
                    }
                }
            }
            
            if (!gotIt) {
                [destView addSubview:walk];
                [srcView removeSubview:walk];
            }
        }
    }
}

- (void) addView:(id <RDNestedViewDescriptor>)newView
{
    id <RDNestedViewDescriptor> viewDesc;
    id <RDNestedViewDescriptor> finalDesc;

    if (!newView)
        return;
        
    NSArray *subviews = [[newView subviewDescriptors] copy];
    
    viewDesc = [self getViewByPath:[newView viewPath]];
    finalDesc = newView;

    if (viewDesc) {
        // This is the same view, just abort
        if ([(NSObject *)viewDesc isEqualTo:newView])
            return;
        
        // This is a real view, ours is a placeholder
        if (![viewDesc view] && [newView view]) {

            [self addSubviewsOf:viewDesc toView:newView];
            
            NSString *basePath = [newView viewPath];
            NSRange finalBlock = [basePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"] options:NSBackwardsSearch];
            id <RDNestedViewDescriptor> parentDesc = nil;
            
            if (!finalBlock.length) {
                [_rdCachedObjects addObject:newView];
            }
            else {
                basePath = [basePath substringWithRange:NSMakeRange(0,finalBlock.location)];
                parentDesc = [self getViewByPath:basePath];
            
                if (parentDesc) {
                    [parentDesc removeSubview:viewDesc];
                    [parentDesc addSubview:newView];
                }
            }

            [[RDNestedViewManager manager] removeView:viewDesc];
        }
        else {
            [self addSubviewsOf:newView toView:viewDesc];
            finalDesc = viewDesc;
                        
            [[RDNestedViewManager manager] removeView:newView];
        }
    }
    else {
        // We didn't have a view.  Let's walk up the tree until we find the
        // first thing in our heirarchy.
        NSString *basePath = [newView viewPath];
        NSRange finalBlock = [basePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"] options:NSBackwardsSearch];

        if (!finalBlock.length) {
            // This *is* a top-level view.
            [_rdCachedObjects addObject:newView];
            [_rdCachedObjects sortUsingFunction:compareViews context:NULL];
        }
        else {
            basePath = [basePath substringWithRange:NSMakeRange(0,finalBlock.location)];
            
            [self populatePath:basePath];
            viewDesc = [self getViewByPath:basePath];
            [viewDesc addSubview:newView];
        }
    }
    
    if ([self delegate]) {
        if (finalDesc == newView)
            [[self delegate] collection:self hasUpdatedAddingView:finalDesc];
        
        if (subviews) {
            NSEnumerator *viewEnum = [subviews objectEnumerator];
            
            id <RDNestedViewDescriptor> walk;
            
            while (walk = [viewEnum nextObject]) {
                [self __updateDelegateAddSubviewsOf:walk];
            }
        }
    }
    
    [subviews release];
}

- (void) __collapsePlaceholders:(id <RDNestedViewDescriptor>)curView inParent:(id <RDNestedViewDescriptor>)parent
{
    NSArray *subviews = [curView subviewDescriptors];
    
    if (subviews && ([subviews count] != 0)) {
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        
        id <RDNestedViewDescriptor> walk;
        
        while (walk = [viewEnum nextObject]) {
            [self __collapsePlaceholders:walk inParent:curView];
        }
        [curView sortSubviews];
    }
    
    if (!subviews || ([subviews count] == 0)) {
        if ([(NSObject *)curView isKindOfClass:[RDNestedViewPlaceholder class]]) {
            if (parent) {
                [parent removeSubview:curView];
            }
            else {
                [_rdCachedObjects removeObject:curView];
            }

            [[self delegate] collection:self hasUpdatedRemovingView:curView];
        }
    } 
}

- (void) collapsePlaceholders
{
    NSEnumerator *viewEnum = [_rdCachedObjects objectEnumerator];
    id walk;
    
    while (walk = [viewEnum nextObject]) {
        [self __collapsePlaceholders:walk inParent:nil];
    }    
}

- (BOOL) isEmpty
{
    if ([_rdCachedObjects count] == 0) {
        return YES;
    }
    else
        return NO;
}

- (void) removeView:(id <RDNestedViewDescriptor>)oldView
{
    id <RDNestedViewDescriptor> viewDesc;

    if (!oldView) {
        NSLog(@"Trying to remove a nil view?");
        return;
    }

    viewDesc = [self getViewByPath:[oldView viewPath]];

    // Do we even have this view?
    if (!viewDesc)
        return;
        
    // Is this really the same view?  (Better be!)
    if (![(NSObject *)viewDesc isEqual:oldView])
        return;

    NSString *basePath = [oldView viewPath];
    NSRange finalBlock = [basePath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"] options:NSBackwardsSearch];
    if (finalBlock.length) {
        basePath = [basePath substringWithRange:NSMakeRange(0,finalBlock.location)];
        
        id <RDNestedViewDescriptor> parentDesc;
        
        parentDesc = [self getViewByPath:basePath];
        if (parentDesc) {
            [parentDesc removeSubview:oldView];
        }    
    }
    else {
        [_rdCachedObjects removeObject:oldView];
    }

    [self collapsePlaceholders];

    if ([self delegate]) {
        [[self delegate] collection:self hasUpdatedRemovingView:oldView];
        
        NSArray *subviews = [oldView subviewDescriptors];
        
        if (subviews) {
            NSEnumerator *viewEnum = [subviews objectEnumerator];
            
            id <RDNestedViewDescriptor> walk;
            
            while (walk = [viewEnum nextObject]) {
                [self __updateDelegateRemoveSubviewsOf:walk];
            }
        }
        
        if ([_rdCachedObjects count] == 0) {
            [[self delegate] collectionIsEmpty:self];
        }
    }
}

- (void) removeAllViews
{
    NSEnumerator *viewEnum = [_rdCachedObjects reverseObjectEnumerator];
    
    id <RDNestedViewDescriptor> walk;
    
    while (walk = [viewEnum nextObject]) {
        [self removeView:walk];
    }
}

- (void) __closeAllSubviews:(id <RDNestedViewDescriptor>)view
{
    NSArray *subviews = [view subviewDescriptors];
    if (subviews && [subviews count]) {
        NSEnumerator *viewEnum = [subviews objectEnumerator];
        id walk;
        while (walk = [viewEnum nextObject]) {
            [self __closeAllSubviews:walk];
            [walk close];
        }
    }
}

- (void) closeAllViews
{
    NSEnumerator *viewEnum = [_rdCachedObjects objectEnumerator];
    
    id <RDNestedViewDescriptor> walk;
    
    while (walk = [viewEnum nextObject]) {
        [self __closeAllSubviews:walk];
        [walk close];
    }
}

- (void) sortAllViews
{
    NSEnumerator *viewEnum = [_rdCachedObjects objectEnumerator];
    
    id <RDNestedViewDescriptor> walk;
    
    while (walk = [viewEnum nextObject]) {
        [walk sortSubviews];
    }
    [_rdCachedObjects sortUsingFunction:compareViews context:nil];
    [[self delegate] resynchViews];
}

- (unsigned) countInView:(id <RDNestedViewDescriptor>) view
{
    unsigned result = [[view subviewDescriptors] count];
    NSEnumerator *subViewEnum = [[view subviewDescriptors] objectEnumerator];
    
    id <RDNestedViewDescriptor> walk;
    
    while (walk = [subViewEnum nextObject]) {
        result += [self countInView:walk];
    }
    
    return result;
}

- (unsigned) count
{
    unsigned result = [_rdCachedObjects count];
    
    NSEnumerator *viewEnum = [_rdCachedObjects objectEnumerator];
    id <RDNestedViewDescriptor> walk;
    
    while (walk = [viewEnum nextObject]) {
        result += [self countInView:walk];
    }
    
    return result;
}

- (id) delegate
{
    return _rdDelegate;
}

- (void) setDelegate:(id) delegate
{
    _rdDelegate = delegate;
}

@end

