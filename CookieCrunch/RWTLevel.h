//
//  RWTLevel.h
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/21/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWTCookie.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface RWTLevel : NSObject

- (NSSet *)shuffle;
- (RWTCookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row;

@end