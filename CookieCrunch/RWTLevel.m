//
//  RWTLevel.m
//  CookieCrunch
//
//  Created by Michael Vilabrera on 7/21/15.
//  Copyright (c) 2015 Giving Tree. All rights reserved.
//

#import "RWTLevel.h"

@interface RWTLevel()

@property (nonatomic) NSSet *possibleSwaps;

@end

@implementation RWTLevel {
    RWTCookie *_cookies[NumColumns][NumRows];
    RWTTile *_tiles[NumColumns][NumRows];
}

- (instancetype)initWithFile:(NSString *)filename {
    self = [super init];
    
    if (self != nil) {
        NSDictionary *dictionary = [self loadJSON:filename];
        
        // loop through the rows
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            
            // loop through the columns in the current row
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                // note: in SpriteKit (0,0) is at the bottom of the screen
                // we will need to read the file upside down
                NSInteger tileRow = NumRows - row - 1;
                
                // if the value is 1, create a tile object
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[RWTTile alloc] init];
                }
            }];
        }];
    }
    
    return self;
}

- (RWTCookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column:%ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row:%ld", (long)row);
    
    return _cookies[column][row];
}

- (NSSet *)shuffle {
    NSSet *set;
    do {
        set = [self createInitialCookies];
        
        [self detectPossibleSwaps];
        
        NSLog(@"possible swaps: %@", self.possibleSwaps);
    } while ([self .possibleSwaps count] == 0);
    
    return set;
}

- (BOOL)hasChainAtColumn:(NSInteger)column row:(NSInteger)row {
    NSUInteger cookieType = _cookies[column][row].cookieType;
    
    NSUInteger horzLength = 1;
    for (NSInteger i = column - 1; i >= 0 && _cookies[i][row].cookieType == cookieType; i--, horzLength++);
    for (NSInteger i = column + 1; i < NumColumns && _cookies[i][row].cookieType == cookieType; i++, horzLength++);
    if (horzLength >= 3) return YES;
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row - 1; i >= 0 &&  _cookies[column][i].cookieType == cookieType; i--, vertLength++);
    for (NSInteger i = row + 1; i < NumRows && _cookies[column][i].cookieType == cookieType; i++, vertLength++);
    return (vertLength >= 3);
}

- (NSSet *)createInitialCookies {
    NSMutableSet *set = [NSMutableSet set];
    
    // 1
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            if (_tiles[column][row]) {
                // 2
                NSUInteger cookieType;
                
                do {
                    cookieType = arc4random_uniform(NumCookieTypes) +1;
                }
                while ((column >= 2 && _cookies[column - 1][row].cookieType == cookieType && _cookies[column - 2][row].cookieType == cookieType) || (row >= 2 &&  _cookies[column][row - 1].cookieType == cookieType && _cookies[column][row - 2].cookieType == cookieType));
                
                // 3
                RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                // 4
                [set addObject:cookie];
            }
        }
    }
    
    return set;
}

- (RWTCookie *)createCookieAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)cookieType {
    RWTCookie *cookie = [[RWTCookie alloc] init];
    cookie.cookieType = cookieType;
    cookie.column = column;
    cookie.row = row;
    _cookies[column][row] = cookie;
    return cookie;
}

- (RWTTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

- (NSDictionary *)loadJSON:(NSString *)filename {
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        NSLog(@"Could not find level file %@", filename);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        NSLog(@"Could not load level file: %@ error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Level file '%@' is not valid JSON: %@", filename, error);
        return nil;
    }
    
    return dictionary;
}

- (void)performSwap:(RWTSwap *)swap {
    NSInteger columnA = swap.cookieA.column;
    NSInteger rowA = swap.cookieA.row;
    NSInteger columnB = swap.cookieB.column;
    NSInteger rowB = swap.cookieB.row;
    
    _cookies[columnA][rowA] = swap.cookieB;
    swap.cookieB.column = columnA;
    swap.cookieB.row = rowA;
    
    _cookies[columnB][rowB] = swap.cookieA;
    swap.cookieA.column = columnB;
    swap.cookieA.row = rowB;
}

- (void)detectPossibleSwaps {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            RWTCookie *cookie = _cookies[column][row];
            if (cookie) {
                
                // is it possible to swap this cookie with the one on the right?
                if (column < NumColumns - 1) {
                    // have a cookie in this spot? if there is no tile, there is no cookie!
                    RWTCookie *other = _cookies[column + 1][row];
                    if (other) {
                        // swap them!
                        _cookies[column][row] = other;
                        _cookies[column + 1][row] = cookie;
                        
                        // is either cookie now a part of the chain?
                        if ([self hasChainAtColumn:column + 1 row:row] || [self hasChainAtColumn:column row:row]) {
                            RWTSwap *swap = [[RWTSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        // swap them back
                        _cookies[column][row] = cookie;
                        _cookies[column + 1][row] = other;
                    }
                }
                
                if (row < NumRows - 1) {
                    RWTCookie *other = _cookies[column][row + 1];
                    if (other) {
                        // swap them!
                        _cookies[column][row] = other;
                        _cookies[column][row + 1] = cookie;
                        
                        if ([self hasChainAtColumn:column row:row + 1] || [self hasChainAtColumn:column row:row]) {
                            RWTSwap *swap= [[RWTSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        _cookies[column][row] = cookie;
                        _cookies[column][row + 1] = other;
                    }
                }
            }
        }
    }
    
    self.possibleSwaps = set;
}

- (NSSet *)detectHorizontalMatches {
    // 1
    NSMutableSet *set = [NSMutableSet set];
    
    // 2
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            
            // 3
            if (_cookies[column][row]) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                // 4
                if (_cookies[column + 1][row].cookieType == matchType && _cookies[column + 2][row].cookieType == matchType) {
                    
                    // 5
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        column++;
                    } while (column < NumColumns && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            // 6
            column++;
        }
    }
    return set;
}

- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_cookies[column][row]) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column][row + 1].cookieType == matchType && _cookies[column][row + 2].cookieType == matchType) {
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        row++;
                    } while (row < NumRows && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            row++;
        }
    }
    
    return set;
}

- (NSSet *)removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    NSLog(@"Horizontal matches: %@", horizontalChains);
    NSLog(@"Vertical matches: %@", verticalChains);
    
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

- (BOOL) isPossibleSwap:(RWTSwap *)swap {
    return [self.possibleSwaps containsObject:swap];
}

- (NSSet *)detectHorizontalMatches {
    // 1
    NSMutableSet *set = [NSMutableSet set];
    
    // 2
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            
            // 3
            if (_cookies[column][row]) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                // 4
                if (_cookies[column + 1][row].cookieType == matchType && _cookies[column +2][row].cookieType == matchType) {
                    
                    // 5
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        column++;
                    } while (column < NumColumns && _cookies[column][row].cookieType == matchType);
                    [set addObject:chain];
                    continue;
                }
            }
            // 6
            column++;
        }
    }
    return set;
}

- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_cookies[column][row]) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column][row + 1].cookieType == matchType && _cookies[column][row].cookieType == matchType) {
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        row++;
                    } while (row < NumRows && _cookies[column][row].cookieType == matchType);
                    [set addObject:chain];
                    continue;
                }
            }
            row++;
        }
    }
    
    return set;
}

- (NSSet *)removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    [self removeCookies:horizontalChains];
    [self removeCookies:verticalChains];
    
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

- (void)removeCookies:(NSSet *)chains {
    for (RWTChain *chain in chains) {
        for (RWTCookie *cookie in chain.cookies) {
            _cookies[cookie.column][cookie.row] = nil;
        }
    }
}

- (NSArray *)fillHoles {
    NSMutableArray *columns = [NSMutableArray array];
    
    // 1
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        for (NSInteger row = 0; row < NumRows; row++) {
            
            // 2
            if (_tiles[column][row] != nil && _cookies[column][row] == nil) {
                
                // 3
                for (NSInteger lookup = row + 1; lookup < NumRows; lookup++) {
                    RWTCookie *cookie = _cookies[column][lookup];
                    if (cookie) {
                        
                        // 4
                        _cookies[column][lookup] = nil;
                        _cookies[column][row] = cookie;
                        cookie.row = row;
                        
                        // 5
                        if (nil == array) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        
                        [array addObject:cookie];
                        
                        // 6
                        break;
                    }
                }
            }
        }
    }
    
    return columns;
}

@end
