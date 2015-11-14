//
//  DYMEPubConverter.h
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/12.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DYMEPubBook.h"

@interface DYMEPubConverter : NSObject

@property (nonatomic, strong, readonly) NSArray     *epubFiles;
@property (nonatomic, strong, readonly) NSArray     *books;

-(void)loadEpubFiles:(dispatch_block_t)completion;

-(DYMEPubBook *)bookAtIndex:(NSUInteger)index;


+(void)doAsync:(dispatch_block_t)block completion:(dispatch_block_t)completionBlock;

+(void)doInMainThread:(dispatch_block_t)block;

@end
