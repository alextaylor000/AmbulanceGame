//
//  Tilemap.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-27.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "Tilemap.h"

@implementation Tilemap
{
    SKTextureAtlas *atlas;
}

- (SKSpriteNode *)nodeForCode:(unichar)tileCode {
    SKSpriteNode *tile;
    
    switch (tileCode) {
        case 'o':
            tile = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"tile_road"]];
            tile.name = @"road";
            break;
            
        case 'x':
            tile = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"tile_wall"]];
            tile.name = @"wall";
            break;
            
        default:
            NSLog(@"unknown tile code: %d", tileCode);
            break;
    }
    
    tile.blendMode = SKBlendModeReplace;
    return tile;
}

- (CGPoint)positionForRow:(NSInteger)row col:(NSInteger)col {
    return CGPointMake(col * self.tileSize.width + self.tileSize.width /2,
                       self.layerSize.height - (row * self.tileSize.height + self.tileSize.height /2));
}

- (instancetype)initWithAtlasNamed:(NSString *)atlasName tileSize:(CGSize)tileSize grid:(NSArray *)grid {
    if (self = [super init]) {
        atlas = [SKTextureAtlas atlasNamed:atlasName];
        
        _tileSize = tileSize;
        
        _gridSize = CGSizeMake([grid.firstObject length], grid.count);
        _layerSize = CGSizeMake(_tileSize.width * _gridSize.width, _tileSize.height * _gridSize.height);
        
        for (int row = 0; row < grid.count; row++) {
            NSString *line = grid[row];
            
            for (int col = 0; col < line.length; col++) {
                SKSpriteNode *tile = [self nodeForCode:[line characterAtIndex:col]];
                
                if (tile != nil) {
                    tile.position = [self positionForRow:row col:col];
                    [self addChild:tile];
                }
            }
        }
    }
    
    return self;
}



@end
