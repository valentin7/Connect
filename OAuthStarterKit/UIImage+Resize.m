//
//  UIImage+Resize.m
//  OAuthStarterKit
//
//  Created by Paul Wong on 1/24/14.
//  Copyright (c) 2014 self. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)resizedImageToWidth:(float)width andHeight:(float)height
{
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRect = CGRectMake(0, 0, width, height);
    
    UIGraphicsBeginImageContext(newSize);
    [self drawInRect:newRect];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

@end
