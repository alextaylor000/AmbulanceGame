//
//  AMBCreditsViewController.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-02.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBCreditsViewController.h"
#import "GameViewController.h"

@interface AMBCreditsViewController ()

@end

@implementation AMBCreditsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
    self.vehicleType = 0;
    self.levelType = 0; // currently only one level type


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tutorialButtonPressed:(id)sender {
    GameViewController *gameView = [self.storyboard instantiateViewControllerWithIdentifier:@"AMBGameViewController"];
    
    gameView.gameType = self.gameType;
    gameView.vehicleType = self.vehicleType;
    gameView.levelType = self.levelType;
    gameView.tutorialMode = YES;
    
    
    [self.navigationController pushViewController:gameView animated:YES];
}


- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
