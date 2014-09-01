//
//  XXXScore.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-01.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import "XXXGameRules.h"
#import "XXXPatient.h"
#import "XXXCharacter.h"

@interface XXXScore : NSObject

@property (readonly) NSInteger currentScore;

- (BOOL)deliverPatientInAmbulance:(XXXCharacter *)ambulance;

@end
