//
//  Tilemap.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-27.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Tilemap : SKNode

@property (readonly,nonatomic) CGSize tileSize;
@property (readonly,nonatomic) CGSize gridSize;
@property (readonly,nonatomic) CGSize layerSize;

- (instancetype)initWithAtlasNamed:(NSString *)atlasName tileSize:(CGSize)tileSize grid:(NSArray *)grid;


@end
