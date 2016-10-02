/* RDOutlineView */

#import <Cocoa/Cocoa.h>

@interface RDOutlineView : NSOutlineView
{
    NSTrackingRectTag       _rdTrackingRect;
	BOOL                    _rdMouseOverView;
	int                     _rdMouseOverRow;
    int                     _rdMouseOverCol;
	int                     _rdLastOverRow; 
    int                     _rdLastOverCol;  
    
    BOOL                    _rdWindowMouseMove;
    BOOL                    _rdGradientSelection;
}

- (int) mouseOverRow;
- (int) mouseOverColumn;

- (void) setUsesGradientSelection:(BOOL) gradient;
- (BOOL) usesGradientSelection;

@end
