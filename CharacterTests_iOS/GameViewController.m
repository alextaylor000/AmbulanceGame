//
//  GameViewController.m
//  CharacterTests_iOS
//
//  Created by Alex Taylor on 2014-12-24.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "GameViewController.h"
#import "AMBLevelScene.h"

@interface GameViewController ()

@property SKView *skView;
@property AMBLevelScene *gameScene;

@end


@implementation GameViewController


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!_skView) {
        _skView = [[SKView alloc] initWithFrame:self.view.bounds];
        _gameScene = [[AMBLevelScene alloc]initWithSize:_skView.bounds.size gameType:self.gameType vehicleType:self.vehicleType levelType:self.levelType];
        
        _gameScene.scaleMode = SKSceneScaleModeAspectFill;
        [_skView presentScene:_gameScene];
        
        [self.view addSubview:_skView];

        // add HUD stuff here, if using UIKit
        
//        __weak GameViewController *weakSelf = self;
//        _scene.gameOverBlock = ^(BOOL didWin) {
//            [weakSelf gameOverWithWin:didWin];
//        };
    }
    
    
}

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    
//    
//    // Configure the view.
//    SKView * skView = (SKView *)self.view;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
//    skView.showsDrawCount = YES;
//    skView.showsQuadCount = YES;
//    
//    /* Sprite Kit applies additional optimizations to improve rendering performance */
//    skView.ignoresSiblingOrder = YES;
//    
//    // Create and configure the scene.
//    CGSize view = self.view.bounds.size;
//    
//    SKScene *scene = [AMBLevelScene sceneWithSize:view];
//    scene.scaleMode = SKSceneScaleModeAspectFill;
//    
//    // Present the scene.
//    [skView presentScene:scene];
//}


- (BOOL)shouldAutorotate
{
    return NO;
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
