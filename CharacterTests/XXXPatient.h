//
//  XXXPatient.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-08-30.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "XXXGameRules.h"

@interface XXXPatient : SKSpriteNode

@property PatientSeverity severity;
@property CGPoint position;
@property PatientState state;

- (instancetype) initWithSeverity:(PatientSeverity)severity position:(CGPoint)position;
- (void)updatePatient;
- (void)changeState:(PatientState)newState;

@end
