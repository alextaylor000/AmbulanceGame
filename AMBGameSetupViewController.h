//
//  AMBGameSetupViewController.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-02.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMBGameScene.h" // for the NS_ENUMs that define game options

@interface AMBGameSetupViewController : UIViewController

@property (nonatomic, assign) AMBGameType gameType;
@property (nonatomic, assign) AMBVehicleType vehicleType;
@property (nonatomic, assign) AMBLevelType levelType;


@end
