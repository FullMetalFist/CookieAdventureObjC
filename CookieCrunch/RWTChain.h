//
//  RWTChain.h
//  CookieCrunch
//
//  Created by Michael Vilabrera on 8/11/15.
//  Created by Michael Vilabrera on 8/18/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RWTCookie;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainTypeHorizontal,
    ChainTypeVertical,
};

@interface RWTChain : NSObject

@property (nonatomic, readonly) NSArray *cookies;

@property (nonatomic, assign) ChainType chainType;

@property (nonatomic, assign) NSUInteger score;

- (void)addCookie:(RWTCookie *)cookie;

@end
