//
//  AMBGameSetupViewController.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-02.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//


#import "AMBGameSetupViewController.h"
#import "GameViewController.h"


@implementation AMBGameSetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // initialize level and vehicle type
    self.vehicleType = 0;
    self.levelType = 0; // currently only one level type
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)vehicleSelected:(UIButton *)sender {
    self.vehicleType = sender.tag;
    NSLog(@"Selected vehicle type %i", self.vehicleType);
}

- (IBAction)levelSelected:(UIButton *)sender {
    self.levelType = sender.tag - 10;
    NSLog(@"Selected level type %i", self.levelType);
    
}

- (IBAction)goButtonPressed:(id)sender {
    GameViewController *gameView = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBGameViewController"];
    
    gameView.gameType = self.gameType;
    gameView.vehicleType = self.vehicleType;
    gameView.levelType = self.levelType;

    
    [self.navigationController pushViewController:gameView animated:YES];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
