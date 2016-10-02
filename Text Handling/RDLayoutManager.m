//
//  RDLayoutManager.m
//  Lemuria
//
//  Created by Rachel Blackman on 10/28/07.
//  Copyright 2007 Riverdark Studios. All rights reserved.
//

#import "RDLayoutManager.h"
#import "RDTextView.h"

#if __LP64__
typedef int NSInteger;
typedef unsigned int NSUInteger;
#else
typedef long NSInteger;
typedef unsigned long NSUInteger;
#endif 

@implementation RDLayoutManager

- (id) init
{
    self = [super init];
    if (self) {
        _rdTextView = nil;
    }
    return self;
}

- (void)addTextContainer:(NSTextContainer *)container
{
    if ([[container textView] isKindOfClass:[RDTextView class]])
        _rdTextView = (RDTextView *)[container textView];
    [super addTextContainer:container];
}

- (void)setTextContainer:(NSTextContainer *)aTextContainer forGlyphRange:(NSRange)glyphRange
{
    if ([[aTextContainer textView] isKindOfClass:[RDTextView class]]) {
        _rdTextView = (RDTextView *)[aTextContainer textView];
        [_rdTextView commit];
    }
    [super setTextContainer:aTextContainer forGlyphRange:glyphRange];
}

- (NSTextContainer *)textContainerForGlyphAtIndex:(NSUInteger)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange
{
    NSTextContainer *result = [super textContainerForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange];
    if ([[result textView] isKindOfClass:[RDTextView class]]) {
        RDTextView *textView = (RDTextView *)[result textView];
        [textView commit];
    }
    
    return result;
}

- (BOOL)inSync
{
    BOOL passOn = YES;
    
    if (_rdTextView)
        passOn = ![_rdTextView commit];    
    else
        NSLog(@"NO RDTextView!  GAH!");
        
    return passOn;
}

- (void)invalidateDisplayForGlyphRange:(NSRange)glyphRange
{
    [self inSync];
    [super invalidateDisplayForGlyphRange:glyphRange];
}

- (void)invalidateDisplayForCharacterRange:(NSRange)glyphRange
{
    [self inSync];
    [super invalidateDisplayForCharacterRange:glyphRange];
}

- (NSRange)characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange
{
    [self inSync];
    return [super characterRangeForGlyphRange:glyphRange actualGlyphRange:actualGlyphRange];
}

@end
