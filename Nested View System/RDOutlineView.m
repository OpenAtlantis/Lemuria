#import "RDOutlineView.h"

#import "RDNestedViewDescriptor.h"
#import "RDNestedViewManager.h"

@protocol RDOutlineViewExtension
- (BOOL) outlineView:(NSOutlineView *)outlineView clickedItem:(id) item inColumn:(NSTableColumn *)tableColumn;
- (void) outlineView:(NSOutlineView *)outlineView cannotHandleEvent:(NSEvent *)event;
@end

@interface NSOutlineView (Private)
- (NSColor *) _highlightColorForCell:(NSCell *) cell;
- (void) _highlightRow:(int) row clipRect:(NSRect) clip;
@end

static void gradientInterpolate( void *info, double const *inData, double *outData ) {
	static double light[4] = { 0.67843137, 0.73333333, 0.81568627, 1. };
	static double dark[4] = { 0.59607843, 0.66666667, 0.76862745, 1. };
	float a = inData[0];
	int i = 0;

	for( i = 0; i < 4; i++ )
		outData[i] = ( 1. - a ) * dark[i] + a * light[i];
}

@implementation RDOutlineView

- (id) initWithFrame:(NSRect) frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _rdTrackingRect = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:@"NSViewFrameDidChangeNotification" object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowLostFocus:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowGainedFocus:) name:@"NSWindowDidBecomeKeyNotification" object:[self window]];

        _rdMouseOverView = NO;
        _rdMouseOverRow = -1;
        _rdLastOverRow = -1;
        _rdMouseOverCol = -1;
        _rdLastOverCol = -1;
        _rdGradientSelection = NO;
    }
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_rdTrackingRect != 0) {
        [self removeTrackingRect:_rdTrackingRect];
    }
    
	[super dealloc];
}


- (void) frameChanged:(NSNotification *) notification
{
    NSRect              frameRect;
    
    if(_rdTrackingRect != 0){
        [self removeTrackingRect:_rdTrackingRect];
    }
    
    frameRect = [self bounds];    
    _rdTrackingRect = [self addTrackingRect:frameRect owner:self userData:nil assumeInside:NO]; 	
}

- (void) windowLostFocus:(NSNotification *)notification
{
	_rdMouseOverView = NO;
	[self setNeedsDisplayInRect:[self rectOfRow:_rdMouseOverRow]];
	_rdMouseOverRow = -1;
	_rdLastOverRow = -1;
    [[self window] setAcceptsMouseMovedEvents:_rdWindowMouseMove];
}

- (void) windowGainedFocus:(NSNotification *)notification
{
    NSPoint mousePoint = [[self window] mouseLocationOutsideOfEventStream];
    
    _rdWindowMouseMove = [[self window] acceptsMouseMovedEvents];
    if (!_rdWindowMouseMove)
        [[self window] setAcceptsMouseMovedEvents:YES];       

    NSRect visibleRect = [self visibleRect];
    NSPoint localPoint = [self convertPoint:mousePoint fromView:nil];

    if (NSMouseInRect(localPoint,visibleRect,[self isFlipped])) {
        _rdMouseOverView = YES;
    }
}

- (int) mouseOverRow
{
    return _rdMouseOverRow;
}

- (int) mouseOverColumn
{
    return _rdMouseOverCol;
}

- (void) keyDown:(NSEvent *) theEvent
{
    NSString *charString = [theEvent characters];
    if (charString && [charString length]) {
        unichar keyChar = [charString characterAtIndex:0];
        if (isalnum(keyChar) || isspace(keyChar) || ispunct(keyChar)) {
            if ([[self delegate] respondsToSelector:@selector(outlineView:cannotHandleEvent:)])
                [(id <RDOutlineViewExtension>)[self delegate] outlineView:self cannotHandleEvent:theEvent];
        }
        else {
            [super keyDown:theEvent];
        }
    }
    else {
        [super keyDown:theEvent];
    }
}

- (void)mouseEntered:(NSEvent*)theEvent
{
    if ([[self window] isKeyWindow]) {
        _rdMouseOverView = YES;
    }
}

- (void)mouseMoved:(NSEvent*)theEvent
{
	id myDelegate = [self delegate];

	if (!myDelegate)
		return; // No delegate, no need to track the mouse.
	if (![myDelegate respondsToSelector:@selector(outlineView:willDisplayCell:forTableColumn:item:)])
		return; // If the delegate doesn't modify the drawing, don't track.

        
    NSRect visibleRect = [self visibleRect];
    NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    if (NSMouseInRect(localPoint,visibleRect,[self isFlipped])) {
        
        _rdMouseOverRow = [self rowAtPoint:localPoint];
        _rdMouseOverCol = [self columnAtPoint:localPoint];
        
        if ((_rdLastOverRow == _rdMouseOverRow) && (_rdLastOverCol == _rdMouseOverCol))
            return;
        else {
            if (_rdLastOverRow != -1)
                [self setNeedsDisplayInRect:[self rectOfRow:_rdLastOverRow]];
            _rdLastOverRow = _rdMouseOverRow;  
            _rdLastOverCol = _rdMouseOverCol;         
        }
        
        if ((_rdMouseOverRow != -1) && (_rdMouseOverCol != -1))
            [self setNeedsDisplayInRect:[self rectOfRow:_rdMouseOverRow]];
    }
    else {
        [self setNeedsDisplayInRect:[self rectOfRow:_rdMouseOverRow]];
        _rdMouseOverRow = -1;
        _rdLastOverRow = -1;
        _rdMouseOverCol = -1;
        _rdLastOverCol = -1;    
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
	_rdMouseOverView = NO;
	[self setNeedsDisplayInRect:[self rectOfRow:_rdMouseOverRow]];
	_rdMouseOverRow = -1;
	_rdLastOverRow = -1;
    _rdMouseOverCol = -1;
    _rdLastOverCol = -1;
}


- (void) mouseDown:(NSEvent *)theEvent
{
	NSEvent *nextEvent = [NSApp
		nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask
					untilDate:[NSDate distantFuture] // or perhaps some reasonable time-out
					   inMode:NSEventTrackingRunLoopMode
					  dequeue:NO];	// don't dequeue in case it's not a drag
	
	if (([nextEvent type] == NSLeftMouseDragged) && (![[NSUserDefaults standardUserDefaults] boolForKey:@"lemuria.dragging.disabled"])) {
        NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        int row = [self rowAtPoint:clickPoint];
        if (row != -1) {
            id item = [self itemAtRow:row];
            
            if ([item conformsToProtocol:@protocol(RDNestedViewDescriptor)]) {
                [[RDNestedViewManager manager] beginDraggingView:(id <RDNestedViewDescriptor>)item onEvent:theEvent];
            }
        }
    }
    else { 
        BOOL blockMe = NO;
        
        if ([nextEvent type] == NSLeftMouseUp) {
            NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            
            int row = [self rowAtPoint:clickPoint];
            int col = [self columnAtPoint:clickPoint];
            if (row != -1) {
                if ([[self delegate] respondsToSelector:@selector(outlineView:clickedItem:inColumn:)])
                    blockMe = [(id <RDOutlineViewExtension>)[self delegate] outlineView:self clickedItem:[self itemAtRow:row] inColumn:[[self tableColumns] objectAtIndex:col]];
            }
        }
        
        if (!blockMe)
            [super mouseDown:theEvent];
    }
}

- (NSColor *) _highlightColorForCell:(NSCell *) cell {
    if (!_rdGradientSelection && [[[self class] superclass] instancesRespondToSelector:@selector(_highlightColorForCell:)]) 
        return [super _highlightColorForCell:cell];
    else
        return nil;
}

- (void) _highlightRow:(int) row clipRect:(NSRect) clip {
    if (!_rdGradientSelection && [[[self class] superclass] instancesRespondToSelector:@selector(_highlightRow:clipRect:)]) {
        [super _highlightRow:row clipRect:clip];
        return;
    }

	NSRect highlight = [self rectOfRow:row];

	struct CGFunctionCallbacks callbacks = { 0, gradientInterpolate, NULL };
	CGFunctionRef function = CGFunctionCreate( NULL, 1, NULL, 4, NULL, &callbacks );
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();

	CGShadingRef shading = CGShadingCreateAxial( cspace, CGPointMake( NSMinX( highlight ), NSMaxY( highlight ) ), CGPointMake( NSMinX( highlight ), NSMinY( highlight ) ), function, false, false );
	CGContextDrawShading( [[NSGraphicsContext currentContext] graphicsPort], shading );

	CGShadingRelease( shading );
	CGColorSpaceRelease( cspace );
	CGFunctionRelease( function );

	static NSColor *rowBottomLine = nil;
	if( ! rowBottomLine )
		rowBottomLine = [[NSColor colorWithCalibratedRed:( 140. / 255. ) green:( 152. / 255. ) blue:( 176. / 255. ) alpha:1.] retain];

	[rowBottomLine set];

	NSRect bottomLine = NSMakeRect( NSMinX( highlight ), NSMaxY( highlight ) - 1., NSWidth( highlight ), 1. );
	NSRectFill( bottomLine );
}

- (void) drawBackgroundInClipRect:(NSRect) clipRect {
	static NSColor *backgroundColor = nil;

    if (_rdGradientSelection) {
        if( ! backgroundColor )
            backgroundColor = [[NSColor colorWithCalibratedRed:( 229. / 255. ) green:( 237. / 255. ) blue:( 247. / 255. ) alpha:1.] retain];
        [backgroundColor set];
        NSRectFill( clipRect );
    }
    else {
        [super drawBackgroundInClipRect:clipRect];
    }
}

- (void) setUsesGradientSelection:(BOOL) gradient
{
    _rdGradientSelection = gradient;
}

- (BOOL) usesGradientSelection
{
    return _rdGradientSelection;
}


@end
