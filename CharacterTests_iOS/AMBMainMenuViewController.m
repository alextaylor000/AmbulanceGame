//
//  AMBMainMenuViewController.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-02.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBMainMenuViewController.h"
#import "AMBGameSetupViewController.h"
#import "GameViewController.h"
#import "AMBCreditsViewController.h"
#import "AMBSettingsViewController.h"
#import "AMBGameCenterViewController.h"
#import "AMBLevelScene.h" // for preloading

@interface AMBMainMenuViewController ()

@end

@implementation AMBMainMenuViewController

- (void)viewWillAppear:(BOOL)animated {

    [AMBLevelScene loadSceneAssetsWithCompletionHandler:^ {
        // will this keep the launch screen visible until the assets are loaded?
        // continue with loading the view
        //NSLog(@"Finished loading shared assets.");
        [super viewWillAppear:animated];
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self quickStartButtonPressed:nil]; // automatically pushes the game view immediately
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)gameModeButtonPressed:(UIButton *)sender {
    AMBGameSetupViewController *gameSetup = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBGameSetupViewController"];
    gameSetup.gameType = sender.tag;
    
    [self.navigationController pushViewController:gameSetup animated:YES];
}



- (IBAction)creditsButtonPressed:(id)sender {
#warning Figure out how to best reuse these view controllers
    AMBCreditsViewController *credits = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBCreditsViewController"];
    
    [self.navigationController pushViewController:credits animated:YES];
}

- (IBAction)gameCenterButtonPressed:(id)sender {
    AMBGameCenterViewController *gameCenter = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBGameCenterViewController"];
    [self.navigationController pushViewController:gameCenter animated:YES];
}

- (IBAction)settingsButtonPressed:(id)sender {
    AMBSettingsViewController *settings = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBSettingsViewController"];
    [self.navigationController pushViewController:settings animated:YES];
}

- (IBAction)quickStartButtonPressed:(UIButton *)sender {
    GameViewController *gameView = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBGameViewController"];
    
    gameView.gameType = 0;
    gameView.vehicleType = AMBVehicleWhite;
    gameView.levelType = AMBCity1;
    gameView.tutorialMode = sender.tag;
    
    [self.navigationController pushViewController:gameView animated:YES];

}

@end
