//
//  DYMEPubConverter.h
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/12.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYMEPubConverter : NSObject

@property (nonatomic, strong, readonly) NSArray     *epubFiles;

-(void)loadEpubFiles:(dispatch_block_t)completion;

-(NSString *)bookNameAtIndex:(NSUInteger)index;

@end
