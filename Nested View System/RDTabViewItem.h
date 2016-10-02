//
//  RDTabViewItem.h
//  Lemuria
//
//  Created by Rachel Blackman on 7/2/06.
//  Copyright 2006 Riverdark Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RDTabViewItem : NSTabViewItem {

    unsigned int                _rdActivityCount;

}

- (unsigned int) activityCount;
- (void) setActivityCount:(unsigned int) activity;

@end
