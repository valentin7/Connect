//
//  ProfileCell.h
//  OAuthStarterKit
//
//  Created by Paul Wong on 1/25/14.
//  Copyright (c) 2014 self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCell : UICollectionViewCell
@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UIImageView *profileImageView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *keywordsLabel;

@end
