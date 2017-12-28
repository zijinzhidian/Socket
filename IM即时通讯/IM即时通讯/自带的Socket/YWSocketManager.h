//
//  YWSocketManager.h
//  IM即时通讯
//
//  Created by apple on 2017/12/25.
//  Copyright © 2017年 zjbojin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YWSocketManager : NSObject

+ (instancetype)shareManager;

- (void)connectSocket;

- (void)closeConnect;

- (void)sendMsg:(NSString *)msg;

- (void)recieveMsg;

@end
