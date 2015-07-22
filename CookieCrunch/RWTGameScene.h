//
//  RWTGameScene.h
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/21/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

@import SpriteKit;

@class RWTLevel;

@interface RWTGameScene : SKScene

@property (nonatomic) RWTLevel *level;

- (void)addTiles;
- (void)addSpritesForCookies:(NSSet *)cookies;

@end
