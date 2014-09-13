//
//  AMBGameScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-13.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBGameScene.h"
#import "JSTileMap.h"

@implementation AMBGameScene

- (JSTileMap *)tileMapFromFile:(NSString *)filename {
    return [JSTileMap mapNamed:filename];
}



@end
