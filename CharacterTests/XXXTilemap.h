//
//  XXXTilemap.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//


#import "JSTileMap.h"

@interface XXXTilemap : SKNode

- (instancetype)initWithTmxLayer:(TMXLayer*)layer;
- (instancetype)initWithTmxObjectGroup:(TMXObjectGroup *)group;

@end
