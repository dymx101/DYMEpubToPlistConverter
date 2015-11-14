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
/// 创建者/作者
@property (nonatomic, strong, readonly) NSString *creator;
/// ID
@property (nonatomic, strong, readonly) NSString *identifier;
/// 简介
@property (nonatomic, strong, readonly) NSString *desc;
/// 书名-From MetaData
@property (nonatomic, strong, readonly) NSString *title;

-(instancetype)initWithEPubPath:(NSString *)epubPath;

-(void)unzip;

-(void)parse;

@end
