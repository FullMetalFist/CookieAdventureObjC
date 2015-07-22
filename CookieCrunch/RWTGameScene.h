//
//  RWTGameScene.h
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/21/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

@import SpriteKit;

@class RWTLevel;
@class RWTSwap;

@interface RWTGameScene : SKScene

@property (nonatomic) RWTLevel *level;

@property (copy, nonatomic) void (^swipeHandler)(RWTSwap *swap);

- (void)addTiles;
- (void)addSpritesForCookies:(NSSet *)cookies;

- (void)animateSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion;

@end
