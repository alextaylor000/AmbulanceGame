//
//  XXXTilemap.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXTilemap.h"

@interface XXXTilemap ()

@property TMXLayer *layer;

@end


@implementation XXXTilemap

-(instancetype)initWithTmxLayer:(TMXLayer *)layer {
    if (self = [super init]) {
        _layer = layer;
    }
    
    return self;
}



@end
