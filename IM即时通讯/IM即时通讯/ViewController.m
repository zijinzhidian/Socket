//
//  ViewController.m
//  IM即时通讯
//
//  Created by apple on 2017/12/25.
//  Copyright © 2017年 zjbojin. All rights reserved.
//

#import "ViewController.h"
#import "YWSocketManager.h"

@interface ViewController ()

@end

@implementation ViewController

//Socket原生
//基于Socket封装的WebSocket
//MQTT
//XMPP


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)sendMsg:(id)sender {
    
    [[YWSocketManager shareManager] sendMsg:self.msgTextField.text];
    
}

- (IBAction)connectServer:(id)sender {
    
    [[YWSocketManager shareManager] connectSocket];
    
}

- (IBAction)disconnectServer:(id)sender {
    
    [[YWSocketManager shareManager] closeConnect];
    
    
}

@end
