//
//  RDSourceListCell.m
//  Lemuria
//
//  Created by Rachel Blackman on 6/21/07.
//  Copyright 2007 Riverdark Studios. All rights reserved.
//

#import "RDSourceListCell.h"


@implementation RDSourceListCell

- (id) init {
    if (self = [super init])
    {
		[self setImageAlignment:NSImageAlignLeft];
		[self setImageScaling:NSScaleNone];
		[self setImageFrameStyle:NSImageFrameNone];
        _rdTitle = nil;
        _rdImage = nil;
	}

	return self;
}

- (id) copyWithZone:(NSZone *) zone {
    RDSourceListCell *cell = (RDSourceListCell *)[super copyWithZone:zone];
    
    cell->_rdImage = [_rdImage retain];
    cell->_rdTitle = [_rdTitle retain];
    cell->_rdStatusNumber = _rdStatusNumber;
    cell->_rdEnabled = _rdEnabled;
    cell->_rdToplevel = _rdToplevel;

	return cell;
}

- (void) dealloc {
	[_rdImage release];
	[_rdTitle release];

    _rdImage = nil;
    _rdTitle = nil;

	[super dealloc];
}


- (void) setIcon:(NSImage *)image
{
    if (_rdImage)
        [_rdImage release];
        
    _rdImage = [image retain];
}

- (void) setTitle:(NSString *)title
{
    if (_rdTitle)
        [_rdTitle release];
        
    _rdTitle = [title retain];
}

- (void) setStatusNumber:(unsigned) statusNumber
{
    _rdStatusNumber = statusNumber;
}

- (void) setEnabled:(BOOL)enabled
{
    _rdEnabled = enabled;
}

- (void) setTopLevel:(BOOL)toplevel
{
    _rdToplevel = toplevel;
}

- (void) setImageAlignment:(NSImageAlignment) newAlign {
	[super setImageAlignment:NSImageAlignLeft];
}

- (void) setStringValue:(NSString *) string {
	[self setTitle:string];
}

- (NSString *) stringValue
{
    return _rdTitle;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView 
{
    // Scary drawing code of DOOOOOM!
	BOOL highlighted = ( [self isHighlighted] && [[controlView window] firstResponder] == controlView && [[controlView window] isKeyWindow] && [[NSApplication sharedApplication] isActive] );

    NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paraStyle setAlignment:NSLeftTextAlignment];
    
    NSFont *font = [self font];
    
    NSMutableDictionary *fontAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,paraStyle,NSParagraphStyleAttributeName,
                                                        _rdEnabled ? (highlighted ? [NSColor alternateSelectedControlTextColor] : [NSColor controlTextColor]) : [[NSColor controlTextColor] colorWithAlphaComponent:0.5],NSForegroundColorAttributeName,
                                                        nil];

    NSSize textSize = [_rdTitle sizeWithAttributes:fontAttributes];

    if ([self isHighlighted]) {
		NSFont *boldFont = [[NSFontManager sharedFontManager] fontWithFamily:@"Lucida Grande" traits:0 weight:15 size:11.];
		NSShadow *shadow = [[NSShadow allocWithZone:nil] init];
		NSColor *whiteColor = [NSColor whiteColor];
		if( ! [self isEnabled] ) whiteColor = [whiteColor colorWithAlphaComponent:0.5];

        [shadow setShadowOffset:NSMakeSize( 0, -1 )];
		[shadow setShadowBlurRadius:0.1];
		[shadow setShadowColor:[[NSColor shadowColor] colorWithAlphaComponent:0.2]];

		[fontAttributes setObject:boldFont forKey:NSFontAttributeName];
		[fontAttributes setObject:whiteColor forKey:NSForegroundColorAttributeName];
		[fontAttributes setObject:shadow forKey:NSShadowAttributeName];

		[shadow release];
    }
                                                        
    NSImage *workImage = [self image];
    
    if (!_rdEnabled) {
        NSImage *fade = [workImage copy];
		[fade lockFocus];
		[_rdImage dissolveToPoint:NSMakePoint( 0., 0. ) fraction:0.5];
		[fade unlockFocus];
        [self setImage:fade];
    }

    float imageWidth = 0;
    if ([self image])
        imageWidth = [[self image] size].width;
    
    cellFrame = NSMakeRect( cellFrame.origin.x + 1., cellFrame.origin.y, cellFrame.size.width - 1., cellFrame.size.height );
	[super drawWithFrame:cellFrame inView:controlView];
    
    float statusWidth = 0.0;
    if (_rdStatusNumber) {
        NSColor *whiteColor = [NSColor whiteColor];
        NSColor *backgroundColor = [NSColor colorWithCalibratedRed:0.6 green:0.6705882352941176 blue:0.7725490196078431 alpha:1.];

		if( [self isHighlighted] ) {
			whiteColor = [backgroundColor shadowWithLevel:0.2];
			backgroundColor = [backgroundColor highlightWithLevel:0.7];
		}
        
		NSFont *numberFont = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:9 size:11.];
		NSMutableParagraphStyle *numberParaStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[numberParaStyle setAlignment:NSCenterTextAlignment];
        
        NSDictionary *statusNumberAttributes = [NSDictionary dictionaryWithObjectsAndKeys:numberFont, NSFontAttributeName, numberParaStyle, NSParagraphStyleAttributeName, whiteColor, NSForegroundColorAttributeName, [NSNumber numberWithFloat:1.0], NSKernAttributeName, nil];

		NSString *statusText;
        statusText = [NSString stringWithFormat:@"%d", _rdStatusNumber];
        if (_rdStatusNumber > 9999) {
            statusText = @"lots";
        }
		NSSize numberSize = [statusText sizeWithAttributes:statusNumberAttributes];
		statusWidth = numberSize.width + 12.;
        float radius = 7.0;
        NSRect mainRect = NSMakeRect( NSMinX( cellFrame ) + NSWidth( cellFrame ) - statusWidth - 2., NSMinY( cellFrame ) + ( ( NSHeight( cellFrame ) / 2 ) - radius ), statusWidth, radius * 2.0 );
        NSRect pathRect = NSInsetRect( mainRect, radius, radius );

        NSBezierPath *outline = [NSBezierPath bezierPath];
        [outline appendBezierPathWithArcWithCenter:NSMakePoint( NSMinX( pathRect ), NSMinY( pathRect ) ) radius:radius startAngle:180. endAngle:270.];
        [outline appendBezierPathWithArcWithCenter:NSMakePoint( NSMaxX( pathRect ), NSMinY( pathRect ) ) radius:radius startAngle:270. endAngle:360.];
        [outline appendBezierPathWithArcWithCenter:NSMakePoint( NSMaxX( pathRect ), NSMaxY( pathRect ) ) radius:radius startAngle:0. endAngle:90.];
        [outline appendBezierPathWithArcWithCenter:NSMakePoint( NSMinX( pathRect ), NSMaxY( pathRect ) ) radius:radius startAngle:90. endAngle:180.];
        [outline closePath];

        [backgroundColor set];
        [outline fill];
        [statusText drawInRect:mainRect withAttributes:statusNumberAttributes];
        statusWidth += 5.0;
    }
    
    if( NSHeight( cellFrame ) >= textSize.height ) {
        float mainYLocation = NSMinY( cellFrame ) + ( NSHeight( cellFrame ) / 2 ) - ( textSize.height / 2 );
        NSRect titleRect = NSMakeRect(cellFrame.origin.x + imageWidth + 5, mainYLocation, NSWidth(cellFrame) - imageWidth - 5 - statusWidth,textSize.height);
        [_rdTitle drawInRect:titleRect withAttributes:fontAttributes];
    }
    
    
}

@end
