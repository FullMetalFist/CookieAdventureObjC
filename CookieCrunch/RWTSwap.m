//
//  RWTSwap.m
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/22/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import "RWTSwap.h"

@implementation RWTSwap

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.cookieA, self.cookieB];
}

@end
