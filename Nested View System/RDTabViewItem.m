//
//  RDTabViewItem.m
//  Lemuria
//
//  Created by Rachel Blackman on 7/2/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDTabViewItem.h"


@implementation RDTabViewItem

- (void) setActivityCount:(unsigned int) count
{
    if (count != _rdActivityCount) {
        _rdActivityCount = count;
        [self setLabel:[self label]];
    }
}

- (unsigned int) activityCount
{
    return _rdActivityCount;
}

#pragma mark Overrides

- (NSSize) sizeOfLabel:(BOOL)shouldTruncateLabel
{
    NSSize parentSize = [super sizeOfLabel:shouldTruncateLabel];
    
    if (_rdActivityCount) {
        NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSColor whiteColor], NSForegroundColorAttributeName,
            [[self tabView] font], NSFontAttributeName, 
            nil];
        
        NSString *activeString = [NSString stringWithFormat:@"%d", _rdActivityCount];
        NSSize activeSize = [activeString sizeWithAttributes:attrs];
        
        if (activeSize.width < activeSize.height) {
            activeSize.width += 6;
        }
        
        parentSize.width += activeSize.width + 6;
        
        [attrs release];
    }
    
    return parentSize;
}

- (void) drawLabel:(BOOL) shouldTruncateLabel inRect:(NSRect) tabRect
{
    [super drawLabel:shouldTruncateLabel inRect:tabRect];
    
    if (_rdActivityCount) {
        NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSColor whiteColor], NSForegroundColorAttributeName,
            [[self tabView] font], NSFontAttributeName, 
            nil];
        
        NSString *activeString = [NSString stringWithFormat:@"%d", _rdActivityCount];
        NSSize activeSize = [activeString sizeWithAttributes:attrs];
        
        
        NSRect activeRect;
        
        activeRect.size.width = activeSize.width + 3;
        activeRect.size.height = activeSize.height - 1;
        
        if (activeSize.width < activeSize.height) {
            activeRect.size.width += 6;
        }
        
        activeRect.origin.x = tabRect.origin.x + (tabRect.size.width - activeRect.size.width);
        activeRect.origin.y = tabRect.origin.y + 1;
        
        int minX = NSMinX(activeRect);
        int midX = NSMidX(activeRect);
        int maxX = NSMaxX(activeRect);
        int minY = NSMinY(activeRect);
        int midY = NSMidY(activeRect);
        int maxY = NSMaxY(activeRect);
        float radius = 6.0;
        NSBezierPath *bgPath = [NSBezierPath bezierPath];
        
        // Bottom edge and bottom-right curve
        [bgPath moveToPoint:NSMakePoint(midX, minY)];
        [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                         toPoint:NSMakePoint(maxX, midY) 
                                          radius:radius];
        
        // Right edge and top-right curve
        [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                         toPoint:NSMakePoint(midX, maxY) 
                                          radius:radius];
        
        // Top edge and top-left curve
        [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                         toPoint:NSMakePoint(minX, midY) 
                                          radius:radius];
        
        // Left edge and bottom-left curve
        [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) 
                                         toPoint:NSMakePoint(midX, minY) 
                                          radius:radius];
        [bgPath closePath];
        
        if ([[[self tabView] window] isMainWindow])
            [[NSColor darkGrayColor] set];
        else
            [[NSColor lightGrayColor] set];
        [bgPath fill];
        
        NSRect rect = activeRect;
        rect.origin.x += (rect.size.width - activeSize.width) / 2;
        rect.origin.y -= 0.5;
        
        [activeString drawAtPoint: rect.origin withAttributes:attrs];
        
        [attrs release];
    }
    
}

@end
