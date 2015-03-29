//
//  GameViewController.m
//  CharacterTests_iOS
//
//  Created by Alex Taylor on 2014-12-24.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBMainMenuViewController.h"
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

        /*  The scene is designed for iPhone aspect ratio (1.78), and simply increases the width if an iPad (1.33) is detected. */
        /* iPhone 4s: 960x640 / 1.5 */
        CGSize sceneSize = CGSizeMake(576, 1024);
        
        CGFloat screenAspect = [UIScreen mainScreen].bounds.size.height / [UIScreen mainScreen].bounds.size.width;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
           sceneSize = CGSizeMake(768, 1024);
        }
        
        if (screenAspect == 1.5) {
            // handle iPhone 4S
            sceneSize = CGSizeMake(682, 1024);
        }
        
        

        _gameScene = [[AMBLevelScene alloc]initWithSize:sceneSize gameType:self.gameType vehicleType:self.vehicleType levelType:self.levelType tutorial:_tutorialMode];
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
        [self.view sendSubviewToBack:_skView];
        // add HUD stuff here, if using UIKit
        
//        __weak GameViewController *weakSelf = self;
//        _scene.gameOverBlock = ^(BOOL didWin) {
//            [weakSelf gameOverWithWin:didWin];
//        };
    }
    
    
}



- (IBAction)pauseButtonPressed:(id)sender {
    [_gameScene pauseScene];
    
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"Game Paused" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *resume = [UIAlertAction actionWithTitle:@"Resume" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [_gameScene resumeScene]; }];
    
    UIAlertAction *mainmenu = [UIAlertAction actionWithTitle:@"Main Menu" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    
        [self.navigationController popToRootViewControllerAnimated:NO];
    
    }];
    
    UIAlertAction *restart = [UIAlertAction actionWithTitle:@"Restart" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { [_gameScene restart]; }];
    
    [menu addAction:mainmenu];
    [menu addAction:restart];
    [menu addAction:resume];
    
    [self presentViewController:menu animated:YES completion:nil];

    
    
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
