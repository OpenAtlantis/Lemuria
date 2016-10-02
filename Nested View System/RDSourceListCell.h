//
//  RDSourceListCell.h
//  Lemuria
//
//  Created by Rachel Blackman on 6/21/07.
//  Copyright 2007 Riverdark Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RDSourceListCell : NSImageCell {

    @private
        NSImage             *_rdImage;
        NSString            *_rdTitle;
        unsigned             _rdStatusNumber;
        BOOL                 _rdEnabled;
        BOOL                 _rdToplevel;

}

- (void) setIcon:(NSImage *)image;
- (void) setTitle:(NSString *)title;
- (void) setStatusNumber:(unsigned) statusNumber;
- (void) setEnabled:(BOOL)enabled;
- (void) setTopLevel:(BOOL)toplevel;

@end
