//
//  GameViewController.m
//  CharacterTests_iOS
//
//  Created by Alex Taylor on 2014-12-24.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "GameViewController.h"
#import "AMBLevelScene.h"
#import <sys/utsname.h> // for deviceModelName


@interface GameViewController ()

@property SKView *skView;
@property AMBLevelScene *gameScene;

@end


@implementation GameViewController




+ (NSString*)deviceModelName {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //MARK: More official list is at
    //http://theiphonewiki.com/wiki/Models
    //MARK: You may just return machineName. Following is for convenience
    
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iPhone Simulator",
      @"x86_64":   @"iPad Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      
      @"iPhone7,1":    @"iPhone 6+ (GSM+CDMA)",
      @"iPhone7,2":    @"iPhone 6 (GSM+CDMA)",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini 1G (WiFi)",
      @"iPad2,6":  @"iPad Mini 1G (GSM)",
      @"iPad2,7":  @"iPad Mini 1G (GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      
      @"iPad4,1":  @"iPad Air(WiFi)",
      @"iPad4,2":  @"iPad Air(GSM)",
      @"iPad4,3":  @"iPad Air(GSM+CDMA)",
      
      @"iPad4,4":  @"iPad Mini 2G (WiFi)",
      @"iPad4,5":  @"iPad Mini 2G (GSM)",
      @"iPad4,6":  @"iPad Mini 2G (GSM+CDMA)",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
    }
    
    return deviceName;
}


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
