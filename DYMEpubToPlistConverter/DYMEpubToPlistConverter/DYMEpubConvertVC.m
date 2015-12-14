//
//  ViewController.m
//  DYMEpubToPlistConverter
//
//  Created by Dong Yiming on 15/11/12.
//  Copyright © 2015年 Dong Yiming. All rights reserved.
//

#import "DYMEpubConvertVC.h"
#import "DYMEPubConverter.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface DYMEpubConvertVC () {
    DYMEPubConverter    *_converter;
}
@property (weak, nonatomic) IBOutlet UITextField *tfPlistName;
@property (weak, nonatomic) IBOutlet UITextField *tfPlistParts;

@end

@implementation DYMEpubConvertVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _converter = [DYMEPubConverter new];
}

- (IBAction)startUpdatingPlistFiles:(UIButton *)sender {
    sender.enabled = NO;
    
    [SVProgressHUD showWithStatus:@"正在更新Plist文件"];
    [_converter updatePlistFiles:^{
        [SVProgressHUD showSuccessWithStatus:@"更新完成"];
        sender.enabled = YES;
    }];
}

- (IBAction)startConvertion:(UIButton *)sender {
    sender.enabled = NO;
    
    [_converter loadEpubFiles:^{
        

        [DYMEPubConverter doAsync:^{
            
            [_converter.books enumerateObjectsUsingBlock:^(DYMEPubBook * _Nonnull book, NSUInteger idx, BOOL * _Nonnull stop) {
                
                [DYMEPubConverter doInMainThread:^{
                    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"正在转化\n《%@》\n...", book.bookName]];
                }];
                
                [book parse];
            }];
            
        } completion:^{
            [SVProgressHUD showSuccessWithStatus:@"转化完成"];
            sender.enabled = YES;
        }];
    }];
}

- (IBAction)addChapterTitles:(UIButton *)sender {
    sender.enabled = NO;
    
    [SVProgressHUD showWithStatus:@"Adding chapter titles"];
    [_converter updateChapterTitles:^{
        [SVProgressHUD showSuccessWithStatus:@"Done"];
        sender.enabled = YES;
    }];
}

- (IBAction)splitPlist:(id)sender {
    
    if (_tfPlistParts.text.length <= 0) {
        [SVProgressHUD showInfoWithStatus:@"请输入拆分数量"];
        return;
    }
    
    
    [SVProgressHUD showWithStatus:@"正在拆分"];
    [DYMEPubConverter doAsync:^{
        
        [_converter splitPlistIntoCount:[_tfPlistParts.text integerValue]];
    } completion:^{
        [SVProgressHUD showSuccessWithStatus:@"拆分完成"];
    }];
    
}


@end
