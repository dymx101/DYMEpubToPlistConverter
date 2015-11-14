//
//  DYMEPubConverter.m
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/12.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import "DYMEPubConverter.h"


@interface DYMEPubConverter () {
    
}

@end

@implementation DYMEPubConverter



-(void)loadEpubFiles:(dispatch_block_t)completion {
    
    [DYMEPubConverter doAsync:^{
        
        _epubFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"epub" inDirectory:@"epub"];
        
        NSMutableArray *books = [NSMutableArray array];
        [_epubFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull epubFile, NSUInteger idx, BOOL * _Nonnull stop) {
            DYMEPubBook *book = [[DYMEPubBook alloc] initWithEPubPath:epubFile];
            [books addObject:book];
        }];
        
        _books = books;
        
    } completion:completion];
}

-(DYMEPubBook *)bookAtIndex:(NSUInteger)index {
    if (index < _books.count) {
        return _books[index];
    }
    
    return nil;
}

#pragma mark - helper
+(void)doAsync:(dispatch_block_t)block completion:(dispatch_block_t)completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (block) {
            block();
        }
        
        dispatch_async(dispatch_get_main_queue(), completionBlock);
    });
}

+(void)doInMainThread:(dispatch_block_t)block {
    
    dispatch_async(dispatch_get_main_queue(), block);
}

@end
