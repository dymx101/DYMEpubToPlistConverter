//
//  ViewController.m
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/12.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import "DYMEpubConvertVC.h"
#import "DYMEPubConverter.h"

@interface DYMEpubConvertVC () {
    DYMEPubConverter    *_converter;
}

@end

@implementation DYMEpubConvertVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _converter = [DYMEPubConverter new];
    [_converter loadEpubFiles:^{
        DYMEPubBook *book = [_converter bookAtIndex:0];
        [book parse];
    }];
    
    
}


@end
