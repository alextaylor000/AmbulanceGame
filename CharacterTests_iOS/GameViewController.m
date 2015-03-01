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

        /*  The scene is designed for iPhone aspect ratio, and simply increases the width if an iPad is detected. */
        CGSize sceneSize = CGSizeMake(576, 1024);
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
           sceneSize = CGSizeMake(768, 1024);
        }

        _gameScene = [[AMBLevelScene alloc]initWithSize:sceneSize gameType:self.gameType vehicleType:self.vehicleType levelType:self.levelType tutorial:NO];
        _gameScene.scaleMode = SKSceneScaleModeAspectFit;

        

        
        
        NSLog(@"Presenting game view with a size of %1.0f,%1.0f, ScaleMode %ld", _skView.bounds.size.width, _skView.bounds.size.height, _gameScene.scaleMode);
        /*
         For reference:
         0 SKSceneScaleModeFill ,
         1 SKSceneScaleModeAspectFill ,
         2 SKSceneScaleModeAspectFit ,
         3 SKSceneScaleModeResizeFill
         */
        
        
        [_skView presentScene:_gameScene];
        
        [self.view addSubview:_skView];

        // add HUD stuff here, if using UIKit
        
//        __weak GameViewController *weakSelf = self;
//        _scene.gameOverBlock = ^(BOOL didWin) {
//            [weakSelf gameOverWithWin:didWin];
//        };
    }
    
    
}


- (void)viewDidAppear:(BOOL)animated {
    [self.view sendSubviewToBack:_skView];
}

- (IBAction)pauseButtonPressed:(id)sender {
    // for now, pause just resets to main menu.
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    
}



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
