//
//  RDChainedListButton.m
//  CLVTest
//
//  Created by Rachel Blackman on 2/23/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import "RDChainedListButton.h"


@implementation RDChainedListButton

- (id) initWithImage:(NSImage *)image action:(SEL)selector target:(id)target
{
    self = [super init];
    if (self) {
        _rdButtonImage = [image retain];
        _rdAction = selector;
        _rdTarget = target;
    }
    return self;
}

- (void) dealloc
{
    [_rdButtonImage release];
    [super dealloc];
}

- (NSImage *) image
{
    return _rdButtonImage;
}

- (SEL) action
{
    return _rdAction;
}

- (id) target
{
    return _rdTarget;
}

@end
