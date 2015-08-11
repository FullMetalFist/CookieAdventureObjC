//
//  RWTChain.m
//  CookieCrunch
//
//  Created by Michael Vilabrera on 8/11/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import "RWTChain.h"
#import "RWTCookie.h"

@implementation RWTChain {
    NSMutableArray *_cookies;
}

- (void)addCookie:(RWTCookie *)cookie {
    if (!_cookies) {
        _cookies = [NSMutableArray array];
    }
    [_cookies addObject:cookie];
}

- (NSArray *)cookies {
    return _cookies;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld cookies:%@", (long)self.chainType, self.cookies];
}


@end
