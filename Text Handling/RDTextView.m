//
//  RDTextView.m
//  RDControlsTest
//
//  Created by Rachel Blackman on 9/17/05.
//  Copyright 2005 Riverdark Studios. All rights reserved.
//

#import "RDTextView.h"
#import "RDScrollView.h"
#import "RDNestedViewWindow.h"
#import "RDNestedViewDisplay.h"
#import "RDNestedViewManager.h"
#import "RDLayoutManager.h"

@interface RDTextView (Private)
- (void) windowLostFocus:(NSNotification *)notification;
- (void) windowGainedFocus:(NSNotification *)notification;
- (void) quickFinishEdit;
@end

@interface RDTextView (TooltipDelegate)
- (BOOL) shouldShowTooltipFor:(RDTextView *) textview;
@end

@implementation RDTextView

- (void) awakeFromNib
{
	_rdMaxBufferLines = 0;
    _rdTotalLines = 0;
    _rdInEditBlock = NO;
	[self setUp];
}

- (id) initWithFrame:(NSRect) frame 
{
    self = [super initWithFrame:frame];

	_rdMaxBufferLines = 0;
	[self setUp];

    return self;
}

- (void) setUp
{
    _rdBaseCursor = nil;
    _rdHandCursor = nil;
    _rdTooltipDelegate = nil;
    
    _rdEditBuffer = nil;
    [[[self textContainer] layoutManager] setBackgroundLayoutEnabled:NO];
    
	[self setUsesFontPanel:NO];
	[self setFont:[NSFont userFixedPitchFontOfSize:10.0f]];
	[self setDelegate:self];
    [self setDrawsBackground:YES];

    _rdLastEndPos = 0;
    _rdLastSearch = nil;
	
	_rdRollOverTracker = 0;

    _rdRollOverWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0,0,100,25)
							styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [_rdRollOverWindow setFloatingPanel:YES];
    [_rdRollOverWindow setHidesOnDeactivate:YES];
    [_rdRollOverWindow setBackgroundColor:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.800 alpha:1.0]];
    [_rdRollOverWindow setAlphaValue:0.9];
    [_rdRollOverWindow setHasShadow:YES];	

    _rdRollOverText = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,100,25)];
    [_rdRollOverText setFont:[NSFont labelFontOfSize:11]];
    [_rdRollOverText setBordered:NO];
    [_rdRollOverText setBezeled:NO];
    [_rdRollOverText setSelectable:NO];
    [_rdRollOverText setDrawsBackground:NO];	

	[(NSView *)[_rdRollOverWindow contentView] addSubview:_rdRollOverText];

	NSRect trackRect;
	
	trackRect = [self bounds];
	trackRect.size.width = 30;
	
	_rdRollOverTracker = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:@"NSViewFrameDidChangeNotification" object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) name:@"NSApplicationDidResignActiveNotification" object:NSApp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowLostFocus:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowGainedFocus:) name:@"NSWindowDidBecomeKeyNotification" object:[self window]];
}

- (void) recolorCursor
{
    if ([[RDNestedViewManager manager] isTiger]) {
        if (!_rdBaseCursor) {
            NSCursor *iBeam = [NSCursor IBeamCursor];
            NSImage *iBeamImg = [[iBeam image] copy];
            
            // First, the iBeam
            NSRect imgRect = {NSZeroPoint, [iBeamImg size]};
            [iBeamImg lockFocus];
            
            NSColor *tempBackground = [[self backgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

            float backgroundRed = [tempBackground redComponent];
            float backgroundGreen = [tempBackground blueComponent];
            float backgroundBlue = [tempBackground greenComponent];
            
            NSColor *tempColor = [NSColor colorWithCalibratedRed:(1.0 - backgroundRed) green:(1.0 - backgroundGreen) blue:(1.0 - backgroundBlue) alpha:1.0];            
            [tempColor set];
                        
            NSRectFillUsingOperation(imgRect,NSCompositeSourceAtop);
            [iBeamImg unlockFocus];
            _rdBaseCursor = [[NSCursor alloc] initWithImage:iBeamImg hotSpot:[iBeam hotSpot]];
            [_rdBaseCursor setOnMouseEntered:YES];
        }
        
        [[self enclosingScrollView] setDocumentCursor:_rdBaseCursor];
        [self addCursorRect:[self visibleRect] cursor:_rdBaseCursor];
    }
}

- (void) setBackgroundColor:(NSColor *)color
{
    [super setBackgroundColor:color];
    [_rdBaseCursor release];
    _rdBaseCursor = nil;
    [self recolorCursor];
}

- (void)resetCursorRects
{
	NSRect			visible;
	NSRange			glyphRange;
	NSRange			charRange;
	NSRange			linkRange;
	NSRectArray		linkRects;
	unsigned		linkCount;
	int				scanLoc;
	int				index;
	
    if (_rdInEditBlock)
        [self quickFinishEdit];
        
    [self recolorCursor];
    
    NSCursor *handCursor = [NSCursor pointingHandCursor];
    if (_rdHandCursor) {
        handCursor = _rdHandCursor;
    }
	    
	visible = [[self enclosingScrollView] documentVisibleRect];
	glyphRange = [[self layoutManager] glyphRangeForBoundingRect:visible inTextContainer:[self textContainer]];
	charRange = [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
	
	// Loop through all the visible characters
	scanLoc = charRange.location;
	while( (scanLoc < charRange.location + charRange.length) && (scanLoc < [[self textStorage] length]) )
	{
		// Find the next range of characters with a link attribute
		if( [[self textStorage] attribute:NSLinkAttributeName atIndex:scanLoc effectiveRange:&linkRange] )
		{
			// Get the array of rects represented by an attribute range
			linkRects = [[self layoutManager] rectArrayForCharacterRange:linkRange withinSelectedCharacterRange:linkRange inTextContainer:[self textContainer] rectCount:&linkCount];
			
			// Loop through these rects adding them as cursor rects
			for( index = 0; index < linkCount; index++ )
				[self addCursorRect:NSIntersectionRect( visible, linkRects[ index ] ) cursor:handCursor];
		}
		
		// Even if we didn't find a link, the range returned tells us where to check next
		scanLoc = linkRange.location + linkRange.length;
	}    
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performScrollToEnd) object:NULL];
    [_rdBaseCursor release];
    [_rdHandCursor release];
	[_rdLastSearch release];
	[super dealloc];
}

- (void) windowLostFocus:(NSNotification *)notification
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
    [self performSelectorOnMainThread:@selector(hideCustomTooltip) withObject:nil waitUntilDone:NO];
}

- (void) windowGainedFocus:(NSNotification *)notification
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
	[self performSelector:@selector(testForCustomTooltip) withObject:nil afterDelay:0.2f]; 	
}


- (void) appChanged:(NSNotification *) notification
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [self performSelectorOnMainThread:@selector(hideCustomTooltip) withObject:nil waitUntilDone:NO];
}

- (void) setFrame:(NSRect)frame
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [super setFrame:frame];
}

- (void) setBounds:(NSRect)bounds
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [super setBounds:bounds];
}

- (void) frameChanged:(NSNotification *) notification
{
    if (_rdInEditBlock)
        [self quickFinishEdit];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
	[self hideCustomTooltip];	

    NSRect              frameRect;
    
    if(_rdRollOverTracker != 0){
        [self removeTrackingRect:_rdRollOverTracker];
    }
    
    frameRect = [self visibleRect];    
    frameRect.size.width = 30;
    _rdRollOverTracker = [self addTrackingRect:frameRect owner:self userData:nil assumeInside:NO]; 	

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowLostFocus:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowGainedFocus:) name:@"NSWindowDidBecomeKeyNotification" object:[self window]];

	[self performSelector:@selector(testForCustomTooltip) withObject:nil afterDelay:0.2f]; 	
}

- (void) setNeedsDisplay:(BOOL)display
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [super setNeedsDisplay:display];
}

- (BOOL) acceptsFirstResponder
{
	return YES;
}

- (BOOL) becomeFirstResponder
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [super becomeFirstResponder];
	return YES;
}

- (BOOL) resignFirstResponder
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
	[self hideCustomTooltip];
	return YES;
}


- (BOOL) shouldDrawInsertionPoint
{
    if ([self isEditable])
        return [super shouldDrawInsertionPoint];
    else
        return NO;
}

- (void) mouseEntered:(NSEvent *)event
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
	[self performSelector:@selector(testForCustomTooltip) withObject:nil afterDelay:0.01]; 	
//    [self recolorCursor];
}

- (void) mouseMoved:(NSEvent *)event
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];

	NSRect visibleRect = [self visibleRect];
	NSPoint mouseLoc;
	mouseLoc = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];

	if (!NSMouseInRect(mouseLoc,visibleRect,[self isFlipped])) {
        NSWindow *window = [self window];
        if ([window isKindOfClass:[RDNestedViewWindow class]]) {
            id <RDNestedViewDisplay> displayView = [(RDNestedViewWindow *)window displayView];
            if (displayView) {
                [displayView mouseMoved:event];
            }
        }
    }
    else {
        [self performSelector:@selector(testForCustomTooltip) withObject:nil afterDelay:0.01];    
    }
}

- (void) mouseExited:(NSEvent *)event
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(testForCustomTooltip) object:NULL];
	[self hideCustomTooltip];
}

- (void) mouseDown:(NSEvent *)theEvent
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [super mouseDown:theEvent];
}

- (void) mouseUp:(NSEvent *)theEvent
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    [super mouseUp:theEvent];
}

- (void) insertText:(id)sender
{
    if ([self isEditable])
        [super insertText:sender];
    else {
        if (_rdRedirectFocusOnKeyTo && [_rdRedirectFocusOnKeyTo respondsToSelector:@selector(insertText:)]) {
            [_rdRedirectFocusOnKeyTo insertText:sender];
            [[self window] makeFirstResponder:_rdRedirectFocusOnKeyTo];
        }
    }
}

- (void) paste:(id)sender
{
    if ([self isEditable])
        [super paste:sender];
    else {
        if (_rdRedirectFocusOnKeyTo && [_rdRedirectFocusOnKeyTo respondsToSelector:@selector(paste:)]) {
            [(id)_rdRedirectFocusOnKeyTo paste:sender];
            [[self window] makeFirstResponder:_rdRedirectFocusOnKeyTo];
        }
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(paste:))
        return YES;
        
    return [super validateMenuItem:menuItem];
}

- (void) insertNewline:(id)sender
{
    if (_rdInEditBlock)
        [self quickFinishEdit];

    if ([self isEditable])
        [super insertNewline:sender];
    else {
        if (_rdRedirectFocusOnKeyTo && [_rdRedirectFocusOnKeyTo respondsToSelector:@selector(insertNewline:)]) {
            [[self window] makeFirstResponder:_rdRedirectFocusOnKeyTo];
            [_rdRedirectFocusOnKeyTo insertNewline:sender];
        }
    }
}



#pragma mark Riverdark Functionality

- (void) performScrollToEnd
{
    [super doCommandBySelector:@selector(scrollToEndOfDocument:)];
}

- (void) _adjustClippingLocation
{
    if (_rdInEditBlock)
        [self quickFinishEdit];

	id tempview = [self superview];
	
	if (![tempview isKindOfClass:[NSClipView class]])
		return;
		
	NSClipView *clipView = (NSClipView *)tempview;

	NSRect newDocumentRect = [clipView documentRect];
//	NSRect newVisibleRect = [clipView documentVisibleRect];
	
	float heightDiff = (_rdOldDocumentRect.size.height - newDocumentRect.size.height);
	
	NSPoint newPoint = _rdOldVisibleRect.origin;
	newPoint.y = newPoint.y - heightDiff;

	if (newPoint.y < 15)
		newPoint.y = 0;

//	newPoint = [clipView constrainScrollPoint:newPoint];
	[clipView scrollToPoint:newPoint];
	[[clipView superview] reflectScrolledClipView:clipView];				
}

- (void) clearSearchString:(id) sender
{
    [_rdLastSearch release];
    _rdLastSearch = nil;
    _rdLastEndPos = 0;
}

- (void) searchForString:(id) sender
{
    if (_rdInEditBlock)
        [self quickFinishEdit];

    NSString *tempString = [sender stringValue];
    
    if ([tempString isEqualToString:@""])
        return;
    
    [tempString retain];
    if (![tempString isEqualToString:_rdLastSearch])
    {
        [_rdLastSearch release];
        _rdLastSearch = tempString;
        _rdLastEndPos = 0;        
    }
    else
        [tempString release];
    
    NSString *searchMe = [[self textStorage] string];
    NSRange searchRange = NSMakeRange(_rdLastEndPos,[searchMe length] - _rdLastEndPos);
    
    NSRange foundSearchRange = [searchMe rangeOfString:_rdLastSearch options:NSCaseInsensitiveSearch range:searchRange];
    if (foundSearchRange.length > 0) {
        [self setSelectedRange:foundSearchRange];
        _rdLastEndPos = foundSearchRange.location + foundSearchRange.length;
        [self scrollRangeToVisible:foundSearchRange];
        [[sender window] makeFirstResponder:sender];
    }
    else 
        NSBeep();
}

- (BOOL) constrainBufferLength
{
    if (_rdMaxBufferLines == 0)
        return NO;
        
    if (_rdTotalLines >= _rdMaxBufferLines) {
        if (_rdInEditBlock)
            [self quickFinishEdit];

        int eatLines = (_rdTotalLines - _rdMaxBufferLines) + (_rdMaxBufferLines * 0.25);
        
        if (eatLines > _rdTotalLines)
            eatLines = _rdTotalLines;

        const char *mainString = [[[self textStorage] string] cString];
        const char *ptr, *lastPtr;
        unsigned int mainLength = [[self textStorage] length];
        NSRange killRange = NSMakeRange(0,0);
        int eaten = 0;
        lastPtr = mainString;
        ptr = strchr(lastPtr,'\n');
               
        while (ptr && *ptr && (eaten < eatLines) && (ptr <  (mainString + mainLength))) {
            eaten++;
            killRange.length += ((ptr - lastPtr) + 1);
            lastPtr = ptr + 1;
            if (*lastPtr)
                ptr = strchr(lastPtr,'\n');
            else
                ptr = 0;
        }
        
        _rdTotalLines -= eaten;
        
        if (killRange.length) {
            NSRange oldRange = [self selectedRange];
            BOOL isEnd = NO;
            
            if ((oldRange.length == 0) || (oldRange.length > mainLength))
                isEnd = YES;
                
            NSTextContainer *container = [self textContainer];
            NSLayoutManager *layout = [container layoutManager];
            NSRange actualRange;
            NSRange glyphRange = [layout glyphRangeForCharacterRange:killRange actualCharacterRange:&actualRange];
            NSRect glyphRect = [layout boundingRectForGlyphRange:glyphRange inTextContainer:container];
            
            _rdHeightEaten == glyphRect.size.height;
            
            [[self textStorage] deleteCharactersInRange:killRange];

            if (!isEnd) {
                if (oldRange.location < killRange.length) {
                    oldRange.length -= (killRange.length - oldRange.location);
                    oldRange.location = 0;
                }
                else {
                    oldRange.location -= killRange.length;
                }
            
                [self setSelectedRange:oldRange];
            }
            else {
                [self setSelectedRange:NSMakeRange([[self textStorage] length],0)];
            }
                        
            return YES;
        }        
    }
    
    return NO;
}

- (void) copy:(id) sender
{
    if (_rdInEditBlock)
        [self quickFinishEdit];

    NSRange selected = [self selectedRange];
    if (selected.length) {
        NSAttributedString *string = [[self textStorage] attributedSubstringFromRange:selected];
        NSPasteboard *generalPboard = [NSPasteboard generalPasteboard];
        [generalPboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType,@"RDTextType",nil] owner:nil];
        [generalPboard setString:[string string] forType:NSStringPboardType];
        [generalPboard setData:[NSArchiver archivedDataWithRootObject:string] forType:@"RDTextType"];
    }
    else {
        NSBeep();
    }
}

- (NSLayoutManager *)layoutManager
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
        
    return [super layoutManager]; 
}

- (NSTextContainer *)textContainer
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
        
    return [super textContainer];
}

- (void) setMaxLines:(unsigned) maxLines
{
    _rdMaxBufferLines = maxLines;
    [self constrainBufferLength];
}

- (void) addLines:(NSString *)string
{    
    _rdTotalLines += [[string componentsSeparatedByString:@"\n"] count] - 1;
}

- (void) clearTextView
{
    if (_rdInEditBlock) {
        [self quickFinishEdit];
    }

    NSRange killRange = NSMakeRange(0,[[self textStorage] length]); 
    [[self textStorage] beginEditing];
    [[self textStorage] deleteCharactersInRange:killRange];
    [[self textStorage] endEditing];
}

- (void) forceLayout
{
    unsigned firstChar, firstGlyph;
    
    firstChar = firstGlyph = 0;
    
    [[self layoutManager] getFirstUnlaidCharacterIndex:&firstChar glyphIndex:&firstGlyph];
    if (firstGlyph) {
        NSRange glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
        NSRange effectiveRange;
        [[self layoutManager] lineFragmentUsedRectForGlyphAtIndex:(glyphRange.location + glyphRange.length) effectiveRange:&effectiveRange];
    }
}

- (void) quickFinishEdit
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(quickFinishEdit) object:nil];
    
    if (!_rdInEditBlock)
        return;
    
    _rdInEditBlock = NO;    
    [_rdEditBlockBegan release];
    _rdEditBlockBegan = nil;

    NSScrollView *tempView = [self enclosingScrollView];
    
    BOOL shouldDisplay = NO;
    NSRect visibleRect = NSMakeRect(0,0,0,0);
    BOOL isRdScroll = [tempView isKindOfClass:[RDScrollView class]];
    
    if (!isRdScroll) {
        shouldDisplay = YES;
    }
    else {
        shouldDisplay = ([(RDScrollView *)tempView autoScroll]);
        visibleRect = [(RDScrollView *)tempView documentVisibleRect];
    }

    [self addLines:[_rdEditBuffer string]];

    NSTextStorage *storage = [self textStorage];
    [storage beginEditing];
    [storage appendAttributedString:_rdEditBuffer];
    [storage endEditing];
    
    [_rdEditBuffer release];
    _rdEditBuffer = nil;
    
    BOOL constrained = [self constrainBufferLength];

    NSClipView *clipView = (NSClipView *)[self superview];

    if (constrained && !shouldDisplay) {
        visibleRect = [(RDScrollView *)tempView documentVisibleRect];
        
        visibleRect.origin.y -= _rdHeightEaten;
        _rdHeightEaten = 0;
        if ((visibleRect.origin.y + visibleRect.size.height) >= [self frame].size.height) {
            visibleRect.origin.y = [self frame].size.height - visibleRect.size.height;
        }
        if (visibleRect.origin.y <= 0) {
            visibleRect.origin.y = 0;
        }
        [clipView scrollToPoint:visibleRect.origin];
        [(RDScrollView *)tempView reflectScrolledClipView:clipView];
        [self setNeedsDisplayInRect:[(RDScrollView *)tempView documentVisibleRect]];
    }
    else if (shouldDisplay) {
        [self performScrollToEnd];
    }
    else {
        [self forceLayout];
    }
}

- (BOOL) commit
{
    if (_rdInEditBlock) {
        [self quickFinishEdit];
        return YES;
    }
    
    return NO;
}

- (void) appendString:(NSAttributedString *) string
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(quickFinishEdit) object:nil];

    if (!_rdInEditBlock) {
        _rdInEditBlock = YES;
        _rdEditBlockBegan = [[NSDate date] copy];
        _rdEditBuffer = [[NSMutableAttributedString alloc] init];
    }

    [_rdEditBuffer appendAttributedString:string];
    
    if (_rdEditBlockBegan && ([[NSDate date] timeIntervalSinceDate:_rdEditBlockBegan] > 1)) {
        [self quickFinishEdit];
    }
    else
        [self performSelector:@selector(quickFinishEdit) withObject:nil afterDelay:0.005];            
}

- (void) hideCustomTooltip
{
	if ([_rdRollOverWindow isVisible])
		[_rdRollOverWindow orderOut:nil];
}

- (void) showCustomTooltip
{
	if (![_rdRollOverWindow isVisible] && [NSApp isActive])
		[_rdRollOverWindow orderFront:nil];
}

- (void) setTooltipDelegate:(id) delegate
{
    _rdTooltipDelegate = delegate;
}

- (void) testForCustomTooltip
{
	NSRect visibleRect = [self visibleRect];
    
    if (_rdInEditBlock)
        return;
    
    if (![NSApp isActive]) {
        [self hideCustomTooltip];
        return;
    }
    
    if (_rdTooltipDelegate && [_rdTooltipDelegate respondsToSelector:@selector(shouldShowTooltipFor:)]) {
        if (![_rdTooltipDelegate shouldShowTooltipFor:self]) {
            [self hideCustomTooltip];
            return;
        }
    }
	
	NSPoint mouseLoc;
	
	mouseLoc = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];

	if (!NSMouseInRect(mouseLoc,visibleRect,[self isFlipped])) {
		[self hideCustomTooltip];
		return;
	}
	
	if (mouseLoc.x >= 25) {
		[self hideCustomTooltip];
		return;
	}
	
	mouseLoc = [NSEvent mouseLocation];
	unsigned offset = [self characterIndexForPoint:mouseLoc];
	unsigned length = [[self textStorage] length];

    if (!length || (offset == NSNotFound)) {
        [self hideCustomTooltip];
        return;
    }
    
	if (offset >= (length - 2)) {
		[self hideCustomTooltip];
		return;
	}
	
	NSDate *tooltipDate = [[self textStorage] attribute:@"RDTimeStamp" atIndex:offset effectiveRange:nil];

    NSString *infoString;
    NSRect rollOverRect;
    unsigned int rollOverWidth;
    unsigned int rollOverHeight;
    
	if (tooltipDate) {
		infoString = [tooltipDate descriptionWithCalendarFormat:@"Timestamp: %m/%d/%y %H:%M:%S.%F   " timeZone:nil locale:nil];
	}
    else {
        infoString = @"";
    }
    
    NSArray *tooltipExtras = [[self textStorage] attribute:@"RDTooltips" atIndex:offset effectiveRange:nil];
    if (tooltipExtras) {
        NSMutableString *newString = [[NSString string] mutableCopy];
        
        NSEnumerator *ttEnum = [tooltipExtras objectEnumerator];
        NSString *walk;
        BOOL first = YES;
        
        while (walk = [ttEnum nextObject]) {
            if (!first)
                [newString appendString:@"\n"];
            [newString appendString:walk];
            first = NO;
        }
        
        if (![infoString isEqualToString:@""]) {
            infoString = [NSString stringWithFormat:@"%@\n%@", infoString, newString];
        }
        else {
            infoString = [NSString stringWithString:newString];
        }
    }
    
    if (!infoString) {
        [self hideCustomTooltip];
        return;
    }
    
    [_rdRollOverText setStringValue:infoString];
    [_rdRollOverText sizeToFit];
    
    rollOverWidth = [_rdRollOverText bounds].size.width;
    rollOverHeight = [_rdRollOverText bounds].size.height;
    
    rollOverRect.size.width = rollOverWidth;
    rollOverRect.size.height = rollOverHeight;

	rollOverRect.origin = mouseLoc;
    
    [_rdRollOverWindow setFrame:rollOverRect display:YES];	
	[self showCustomTooltip];
}

- (BOOL)tryToPerform:(SEL)anAction with:(id)anObject
{
    if (_rdInEditBlock)
        [self quickFinishEdit];
    return [super tryToPerform:anAction with:anObject];
}

- (void) doCommandBySelector:(SEL)selector
{    
    if (_rdInEditBlock) {
        [self quickFinishEdit];
        usleep(50);
    }

    [super doCommandBySelector:selector];
    
    if((selector == @selector(scrollPageUp:)) ||
       (selector == @selector(scrollPageDown:)) ||
       (selector == @selector(pageUp:)) ||
       (selector == @selector(pageDown:)) ||
       (selector == @selector(moveToEndOfDocument:)) ||
       (selector == @selector(moveToBeginningOfDocument:)) ||
       (selector == @selector(scrollToBeginningOfDocument:)) ||
       (selector == @selector(scrollToEndOfDocument:))) {
        
        NSScrollView *scrollView = [self enclosingScrollView];
        if ([scrollView isKindOfClass:[RDScrollView class]]) {
            [(RDScrollView *)scrollView recalculateAutoScroll];
        }
    }
}

@end
