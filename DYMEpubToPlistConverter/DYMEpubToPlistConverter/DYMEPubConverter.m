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

-(void)updateChapterTitles:(dispatch_block_t)completion {
    [DYMEPubConverter doAsync:^{
        
        NSArray *plistFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"plist" inDirectory:@"plist"];
        __block long index = 0;
        
        [plistFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull plistFile, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSLog(@"%@", plistFile);
            
            NSMutableDictionary *bookDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistFile];
            NSArray *chapters = bookDic[@"chapterArrArr"];
            NSArray *innerChapters = chapters.firstObject;
            
            /// 修改的chapters
            NSMutableArray *editingChapters = [NSMutableArray array];
            [innerChapters enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableDictionary *editingChapter = [obj mutableCopy];
                if (editingChapter) {
                    editingChapter[@"chapterTitle"] = [NSString stringWithFormat:@"第%@章", @(idx + 1)];
                    
                    [editingChapters addObject:editingChapter];
                }
            }];
            
            bookDic[@"chapterArrArr"] = @[editingChapters];
            
            [bookDic writeToFile:plistFile atomically:YES];
            
            index++;
        }];
        
    } completion:completion];
}

-(void)splitPlistIntoCount:(NSUInteger)partCount {
    NSArray *plistFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"plist" inDirectory:@"large_plist"];
    if (plistFiles.count == 0) {
        return;
    }
    
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist" inDirectory:@"large_plist"];
    NSString *filePath = plistFiles.firstObject;
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSDictionary *bookDic = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSArray *chapters = bookDic[@"chapterArrArr"];
    NSArray *innerChapters = chapters.firstObject;
    
    NSUInteger maxChapterCount = innerChapters.count / partCount;
    NSUInteger location = 0;

    for (NSInteger i = 0; i < partCount; i++) {
        
        NSUInteger range = maxChapterCount;
        if (innerChapters.count - location <  maxChapterCount) {
            range = innerChapters.count - location;
        }
        NSArray *subArr = [innerChapters subarrayWithRange:NSMakeRange(location, range)];
        
        NSMutableDictionary *bookPart = [bookDic mutableCopy];
        bookPart[@"chapterArrArr"] = @[subArr];
        
        NSString *partFileName = [NSString stringWithFormat:@"%@%@.plist", fileName, @(i+1)];
        NSString *partFilePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:partFileName];
        [bookPart writeToFile:partFilePath atomically:YES];
        
        NSLog(@"%@", partFilePath);
        
        location = location + range;
    }
}

-(void)updatePlistFiles:(dispatch_block_t)completion {
    [DYMEPubConverter doAsync:^{
        
        NSArray *plistFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"plist" inDirectory:@"plist"];
        __block long index = 0;
        
        [plistFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull plistFile, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSLog(@"%@", plistFile);
            
            NSMutableDictionary *bookDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistFile];
            bookDic[@"isbn"] = [NSString stringWithFormat:@"isbn%05ld", index];
            bookDic[@"cover"] = @"no_cover.png"; //
            bookDic[@"order"] = @"9999"; //
            
            [bookDic writeToFile:plistFile atomically:YES];
            
            index++;
        }];
        
    } completion:completion];
}

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
