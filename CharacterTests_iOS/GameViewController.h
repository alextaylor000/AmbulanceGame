//
//  GameViewController.h
//  CharacterTests_iOS
//

//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "AMBConstants.h" // for the NS_ENUMs that define game options

@interface GameViewController : UIViewController

@property (nonatomic, assign) AMBGameType gameType;
@property (nonatomic, assign) AMBVehicleType vehicleType;
@property (nonatomic, assign) AMBLevelType levelType;
@property (nonatomic, assign) BOOL tutorialMode;

- (void)loadMainMenu;


@end
