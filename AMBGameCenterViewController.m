//
//  AMBGameCenterViewController.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-08-21.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBGameCenterViewController.h"

@interface AMBGameCenterViewController ()

@end

@implementation AMBGameCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end