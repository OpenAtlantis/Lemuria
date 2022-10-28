#import "RDNestedViewWindow.h"
#import "RDNestedViewCollection.h"

@implementation RDNestedViewWindow

- (id) initWithUID:(NSString *)uid contentRect:(NSRect) rect styleMask:(int) style backing:(NSBackingStoreType) backing defer:(BOOL)defer
{
    self = [super initWithContentRect:rect styleMask:style backing:backing defer:defer];
    if (self) {
        _rdWindowUID = [uid retain];
        [self setFrameAutosaveName:_rdWindowUID];
        _rdIsDragSource = NO;
    }
    return self;
}

- (void) dealloc
{
    _rdIsClosing = NO;
    [_rdWindowUID release];
    [super dealloc];
}

- (NSString *) windowUID
{
    return _rdWindowUID;
}

- (void) setDisplayView:(NSView<RDNestedViewDisplay> *)displayView
{
    [self setContentView:displayView];
}

- (NSView<RDNestedViewDisplay> *) displayView
{
    NSView *view = [self contentView];
    
    if ([view conformsToProtocol:@protocol(RDNestedViewDisplay)])
        return (NSView<RDNestedViewDisplay> *)view;
    else
        return nil;
}

- (BOOL) isDragSource
{
    return _rdIsDragSource;
}

- (void) setIsDragSource:(BOOL) isDrag
{
    _rdIsDragSource = isDrag;
    if (!_rdIsDragSource) {
        RDNestedViewCache *views = [[self displayView] collection];
        if ([[views topLevel] count] == 0) {
            [[self displayView] collectionIsEmpty:views];
        }
    }
}

- (void) close
{
    [[[self displayView] collection] closeAllViews];
    [[[self displayView] collection] removeAllViews];
    [super close];
}

- (BOOL) isClosing
{
    return _rdIsClosing;
}

- (void) setIsClosing:(BOOL) isClosing
{
    _rdIsClosing = isClosing;
}

- (void) mouseMoved:(NSEvent *)theEvent
{
    [[self displayView] mouseMoved:theEvent];
}
@end
