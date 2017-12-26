//
//  WPRegister.h
//  WeexPluginDemo
//
//  Created by 齐山 on 17/3/7.
//  Copyright © 2017年 taobao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ResultBlock)(NSArray *);

@interface WPLRegister : NSObject

+(void)registerPlugins;

+(void)registerPlugins:(ResultBlock)block;

@end
