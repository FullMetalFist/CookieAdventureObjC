//
//  GameViewController.m
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/21/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import "GameViewController.h"
#import "RWTGameScene.h"

#import "RWTLevel.h"

@interface GameViewController()

@property (nonatomic) RWTLevel *level;
@property (nonatomic) RWTGameScene *scene;

@property (assign, nonatomic) NSUInteger movesLeft;
@property (assign, nonatomic) NSUInteger score;

@property (weak, nonatomic) IBOutlet UILabel *targetsLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

@end

@implementation SKScene (Unarchive)

+ (instancetype)unarchiveFromFile:(NSString *)file {
    /* Retrieve scene file path from the application bundle */
    NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];
    /* Unarchive the file to an SKScene object */
    NSData *data = [NSData dataWithContentsOfFile:nodePath
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
    NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [arch setClass:self forClassName:@"SKScene"];
    SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [arch finishDecoding];
    
    return scene;
}

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
    
    // Create and configure the scene.
    self.scene = [RWTGameScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Load the level
    self.level = [[RWTLevel alloc] initWithFile:@"Level_0"];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    // Enable swap
    id block = ^(RWTSwap *swap) {
        self.view.userInteractionEnabled = NO;
        
        if ([self.level isPossibleSwap:swap]) {
            [self.level performSwap:swap];
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
            }];
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
    };
    self.scene.swipeHandler = block;
    
    // Present the scene.
    [skView presentScene:self.scene];
    
    // Begin the game
    [self beginGame];
}

- (void)beginGame {
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    [self shuffle];
}

- (void)shuffle {
    NSSet *newCookies = [self.level shuffle];
    [self.scene addSpritesForCookies:newCookies];
}

- (void)handleMatches {
    NSSet *chains = [self.level removeMatches];
    
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    [self.scene animateMatchedCookies:chains completion:^{
        for (RWTChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingCookies:columns completion:^{
            [self.scene animateNewCookies:columns completion:^{
                [self handleMatches];
            }];
        }];
    }];
}

- (void)beginNextTurn {
    [self.level detectPossibleSwaps];
    self.view.userInteractionEnabled = YES;
}

- (void)updateLabels {
    self.targetsLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
