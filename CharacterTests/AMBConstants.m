//
//  AMBConstants.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-09-05.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBConstants.h"

@implementation AMBConstants

/**
 Instantiates a ScoreKeeper instance, and ensures that only one instance can be created.
 */
+ (AMBConstants *)sharedInstance {
    static AMBConstants *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AMBConstants alloc]init];
    });
    
    return _sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        
        _SuddenDeathPatientTimeBonus = 10;
        _SuddenDeathOverridePatientTTL = 20;
        
        
    }
    
    return self;
}


@end