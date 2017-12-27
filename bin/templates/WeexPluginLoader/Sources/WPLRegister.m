//
//  WPRegister.m
//  WeexPluginDemo
//
//  Created by 齐山 on 17/3/7.
//  Copyright © 2017年 taobao. All rights reserved.
//

#import "WPLRegister.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <WeexSDK/WeexSDK.h>

#define WeexPluginSectionName "WeexPlugin"

#define WX_PlUGIN_REGISTER_MODULE(js_name,cls_name) \
[WXSDKEngine registerModule:js_name withClass:NSClassFromString(cls_name)];

#define WX_PlUGIN_REGISTER_COMPONENT(js_name,cls_name) \
[WXSDKEngine registerComponent:js_name withClass:NSClassFromString(cls_name)];

#define WX_PlUGIN_REGISTER_HANDLER(js_impl,js_protocol_name) \
[WXSDKEngine registerHandler:[NSClassFromString(js_impl) new] withProtocol:NSProtocolFromString(js_protocol_name)];



static NSArray<Class>* readConfigurations(){
//    static NSMutableArray<Class> *classes;
    static NSMutableArray *configs;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Dl_info info;
        dladdr(readConfigurations, &info);
        
#ifndef __LP64__
        //        const struct mach_header *mhp = _dyld_get_image_header(0); // both works as below line
        const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
        unsigned long size = 0;
        uint32_t *memory = (uint32_t*)getsectiondata(mhp, "__DATA", WeexPluginSectionName, & size);
#else /* defined(__LP64__) */
        const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
        unsigned long size = 0;
        uint64_t *memory = (uint64_t*)getsectiondata(mhp, "__DATA", WeexPluginSectionName, & size);
#endif /* defined(__LP64__) */
        
        configs = [NSMutableArray new];
        
        for(int idx = 0; idx < size/sizeof(void*); ++idx){
            char *string = (char*)memory[idx];
            
            NSString *str = [NSString stringWithUTF8String:string];
            
            if (str && [str length] > 0) {
                [configs addObject:str];
            }
        }
    });
    
    return configs;
}

@implementation WPRegister

+(void)load
{
    NSString *bundleName = [[NSBundle mainBundle] bundleIdentifier];
    //淘宝的不需要使用load
    if([@"com.taobao.taobao4iphone" isEqualToString:bundleName]) {
        return;
    }
    [self registerPlugins];
}

+(void )registerPlugins
{
    NSArray *array = readConfigurations();
    if (array && [array count]>0) {
        for (NSString *str in array) {
            NSArray<NSString*> *components = [str componentsSeparatedByString:@"&"];
            if (!components || [components count] == 0) {
                return ;
            }
            if ([components count] < 3){
                continue;
            }
            NSString *type = [components objectAtIndex:0];
            NSString *name = [components objectAtIndex:1];
            NSString *className = [components objectAtIndex:2];
            if (type && name && className) {
                if ([type length]>0&&[name length]>0 && [className length]>0 ) {
                    if([type isEqualToString:@"module"] && NSClassFromString(className)) {
                        WX_PlUGIN_REGISTER_MODULE(name,className);
                        NSLog(@"class %@ register name %@",className,name);
                    }
                    if([type isEqualToString:@"component"] && NSClassFromString(className)) {
                        WX_PlUGIN_REGISTER_COMPONENT(name,className);
                        NSLog(@"class %@ register name %@",className,name);
                    }
                    if([type isEqualToString:@"protocol"]) {
                        WX_PlUGIN_REGISTER_HANDLER(name,className);
                        NSLog(@"class %@ register name %@",className,name);
                    }
                }
            }
        }
    }
}

@end
