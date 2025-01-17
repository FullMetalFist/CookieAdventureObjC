//
//  RWTGameScene.m
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/21/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "RWTGameScene.h"

#import "RWTCookie.h"
#import "RWTLevel.h"
#import "RWTSwap.h"

static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface RWTGameScene()

@property (nonatomic) SKNode *gameLayer;
@property (nonatomic) SKNode *tilesLayer;
@property (nonatomic) SKNode *cookiesLayer;

@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;

@property (nonatomic) SKSpriteNode *selectionSprite;

@property (nonatomic) SKAction *swapSound;
@property (nonatomic) SKAction *invalidSwapSound;
@property (nonatomic) SKAction *matchSound;
@property (nonatomic) SKAction *fallingCookieSound;
@property (nonatomic) SKAction *addCookieSound;


@end

@implementation RWTGameScene

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.anchorPoint = CGPointMake(0.5, 0.5);
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        self.gameLayer = [SKNode node];
        self.gameLayer.hidden = YES;
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth * NumColumns/2, -TileHeight * NumRows/2);
        
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        self.cookiesLayer = [SKNode node];
        self.cookiesLayer.position = layerPosition;
        
        [self.gameLayer addChild:self.cookiesLayer];
        
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        self.selectionSprite = [SKSpriteNode node];
        [self preloadResources];
    }
    return self;
}

- (void) addTiles {
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"Tile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

- (void)addSpritesForCookies:(NSSet *)cookies {
    for (RWTCookie *cookie in cookies) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
        sprite.position = [self pointForColumn:cookie.column row:cookie.row];
        [self.cookiesLayer addChild:sprite];
        cookie.sprite = sprite;
    }
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column * TileWidth + TileWidth/2, row * TileHeight + TileHeight/2);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // 1
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    // 2
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // 3
        RWTCookie *cookie = [self.level cookieAtColumn:column row:row];
        if (cookie != nil) {
            
            // 4
            self.swipeFromColumn = column;
            self.swipeFromRow = row;
            
            [self showSelectionForCookie:cookie];
        }
    }
}

- (BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row {
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // is this a valid location within the cookies layer?
    // if yes, calculate the corresponding row and column numbers.
    if (point.x >= 0 && point.x < NumColumns * TileWidth &&
        point.y >= 0 && point.y < NumRows * TileHeight) {
        
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
    } else {
        // invalid location
        *column = NSNotFound;
        *row = NSNotFound;
        return NO;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // 1
    if (self.swipeFromColumn == NSNotFound) return;
    
    // 2
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // 3
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {
            horzDelta = -1;     // swipe Left
        } else if (column > self.swipeFromColumn) {
            horzDelta = 1;      // swipe Right
        } else if (row < self.swipeFromRow) {
            vertDelta = -1;     // swipe Down
        } else if (row > self.swipeFromRow) {
            vertDelta = 1;      // swipe Up
        }
        
        // 4
        if (horzDelta != 0 || vertDelta != 0) {
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            
            [self hideSelectionIndicator];
            
            // 5
            self.swipeFromColumn = NSNotFound;
        }
    }
}

- (void)trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)vertDelta {
    // 1
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    // 2
    if (toColumn < 0 || toColumn >= NumColumns) return;
    if (toRow < 0 || toRow >= NumRows) return;
    
    // 3
    RWTCookie *toCookie = [self.level cookieAtColumn:toColumn row:toRow];
    if (toCookie == nil) return;
    
    // 4
    RWTCookie *fromCookie = [self.level cookieAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    NSLog(@"*** swapping %@ with %@", fromCookie, toCookie);
    if (self.swipeHandler != nil) {
        RWTSwap *swap = [[RWTSwap alloc] init];
        swap.cookieA = fromCookie;
        swap.cookieB = toCookie;
        
        self.swipeHandler(swap);
    }
}

- (void)showSelectionForCookie:(RWTCookie *)cookie {
    // if the selection indicator is still visible, then first remove it.
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    SKTexture *texture = [SKTexture textureWithImageNamed:[cookie highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    [cookie.sprite addChild:self.selectionSprite];
    self.selectionSprite.alpha = 1.0;
}

- (void)hideSelectionIndicator {
    [self.selectionSprite runAction:[SKAction sequence:@[[SKAction fadeOutWithDuration:0.7],[SKAction removeFromParent]]]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self hideSelectionIndicator];
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)preloadResources {
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingCookieSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addCookieSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-Bold"];
}

#pragma mark -- animate cookie methods

- (void)animateSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion {
    // put the cookie you started with on top
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.cookieB.sprite runAction:moveB];
    [self runAction:self.swapSound];
}

- (void)animateInvalidSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion {
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.cookieB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
    [self runAction:self.invalidSwapSound];
}

- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion {
    for (RWTChain *chain in chains) {
        
        [self animateScoreForChain:chain];
        
        for (RWTCookie *cookie in chain.cookies) {
            // 1
            if (cookie.sprite) {
                
                // 2
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [cookie.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                // 3
                cookie.sprite = nil;
            }
        }
    }
    
    [self runAction:self.matchSound];
    
    // 4
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.3], [SKAction runBlock:completion]]]];
}

- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        [array enumerateObjectsUsingBlock:^(RWTCookie *cookie, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            
            // 2
            NSTimeInterval delay = 0.05 + 0.15 * idx;
            
            // 3
            NSTimeInterval duration = ((cookie.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            // 4
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 5
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            [cookie.sprite runAction:[SKAction sequence:@[[SKAction waitForDuration:delay], [SKAction group:@[moveAction, self.fallingCookieSound]]]]];
        }];
    }
    
    // 6
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:longestDuration], [SKAction runBlock:completion]]]];
}

- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        // 2
        NSInteger startRow = ((RWTCookie *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(RWTCookie *cookie, NSUInteger idx, BOOL *stop) {
            // 3
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
            sprite.position  = [self pointForColumn:cookie.column row:startRow];
            [self.cookiesLayer addChild:sprite];
            cookie.sprite = sprite;
            
            // 4
            NSTimeInterval delay = 0.1 + 0.2 * ([array count] - idx - 1);
            
            // 5
            NSTimeInterval duration = (startRow - cookie.row) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 6
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            cookie.sprite.alpha = 0;
            [cookie.sprite runAction:[SKAction sequence:@[[SKAction waitForDuration:delay], [SKAction group:@[[SKAction fadeInWithDuration:0.05], moveAction, self.addCookieSound]]]]];
        }];
    }
    
    // 7
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:longestDuration], [SKAction runBlock:completion]]]];
}

- (void)animateScoreForChain:(RWTChain *)chain {
    // Figure out what the midpoint of the chain is.
    RWTCookie *firstCookie = [chain.cookies firstObject];
    RWTCookie *lastCookie = [chain.cookies lastObject];
    CGPoint centerPosition = CGPointMake(
     (firstCookie.sprite.position.x + lastCookie.sprite.position.x) / 2,
     (firstCookie.sprite.position.y + lastCookie.sprite.position.y) / 2 - 8);
    
    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-Bold"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.cookiesLayer addChild:scoreLabel];
    
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[moveAction, [SKAction removeFromParent]]]];
}

- (void)animateGameOver {
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

- (void)animateBeginGame {
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

- (void)removeAllCookieSprites {
    [self.cookiesLayer removeAllChildren];
}

@end
