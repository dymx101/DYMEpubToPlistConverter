//
//  DYMEPubBook.h
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/13.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYMEPubBook : NSObject
/// epub在bundle中的路径
@property (nonatomic, strong, readonly) NSString *epubPath;
/// 解压缩路径
@property (nonatomic, strong, readonly) NSString *unzipPath;
/// 书名
@property (nonatomic, strong, readonly) NSString *bookName;


-(instancetype)initWithEPubPath:(NSString *)epubPath;

-(void)unzip;

-(void)parse;

@end
