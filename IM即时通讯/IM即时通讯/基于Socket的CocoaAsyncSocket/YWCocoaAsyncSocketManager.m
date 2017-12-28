//
//  YWCocoaAsyncSocketManager.m
//  IM即时通讯
//
//  Created by apple on 2017/12/26.
//  Copyright © 2017年 zjbojin. All rights reserved.
//

#import "YWCocoaAsyncSocketManager.h"
#import "GCDAsyncSocket.h"


static NS_ENUM(NSInteger, SocketOfflineType) {
    
    SocketOfflineByServer = 0,      //服务器掉线(比如:服务器断开socket连接)
    SocketOfflineByUser,            //用户主动断开(比如:退出登陆,程序进入后台)
    SocketOfflineByNetBad           //无网络或网络超时(比如:在电梯里信号差)
    
};

//服务器ip地址
static NSString *kHost = @"127.0.0.1";
//端口号
static const uint16_t kPort = 5222;

@interface YWCocoaAsyncSocketManager()<GCDAsyncSocketDelegate>

@property(nonatomic,strong)GCDAsyncSocket *clientSocket;    //客户端socket

@property(nonatomic,assign)enum SocketOfflineType socketType;

@property(nonatomic,strong)NSTimer *connectTimer;

@end

@implementation YWCocoaAsyncSocketManager


#pragma mark - Private Actions
/**
 添加长连定时器
 */
- (void)addConnectTimer {
    
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:3 * 60 target:self selector:@selector(longConnectedToSocket) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    
}


/**
 心跳连接
 */
- (void)longConnectedToSocket {
    
    //心跳包(固定格式数据,尽可能减小心跳包大小)
    NSData *data = [@"I Love you, do not leave me" dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:101];
    
    /*
     注意:
     心跳包数据和心跳的时间间隔需要和后台服务器商定,后台服务器也需要相对应的心跳检测,以此检测客户端是否在线
    */
    
}


#pragma mark - GCDAsyncSocketDelegate
//当超时的时候,是否选择续时
//- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
//    
//}

/**
 连接服务器成功回调
 */
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    //连接成功后读取服务端的数据
    /*
     注意:<1>我们调用一次这个方法，只能触发一次读取消息的代理，如果我们调用的时候没有未读消息，它就会等在那，直到消息来了被触发。一旦被触发一次代理后，我们必须再次调用这个方法，否则，之后的消息到了仍旧无法触发我们读取消息的代理。
     
     <2>timeout:监听的时间,如果设置10秒则会监听服务器10秒,如果10秒过后没有消息或服务器未响应,则会调用是否续时的代理方法。如果选择不续时,那么socket会自动断开连接。-1则代表永远监听,不超时
    */
    [self.clientSocket readDataWithTimeout:-1 tag:100];
    
    //连接成功,开启定时器(心跳机制)
    [self addConnectTimer];
}


/**
 断开服务器连接、连接失败时调用

 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
    //重连机制,程序在前台时才需要重连
    if (self.socketType == SocketOfflineByServer) {
        //服务器掉线,重连
        
    } else if (self.socketType == SocketOfflineByUser) {
        //用户断开,不进行重连
        
        
    } else if (self.socketType == SocketOfflineByNetBad) {
        //网络断开,不进行重连
        
        
    }
    
}


/**
 收到服务器消息的回调
 @param tag 本次读取的标记
 
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您有新的消息" message:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:sureAction];
    [self.currentController presentViewController:alert animated:YES completion:nil];
    
    //继续读取服务器数据
    [self.clientSocket readDataWithTimeout:-1 tag:100];
    
}


/**
 发送消息成功的回调

 */
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
    if (tag == 101) {
        NSLog(@"心跳连接成功");
    } else if (tag == 100) {
        NSLog(@"发送消息成功");
    }
    
}


#pragma mark - Public Actions

/**
 建立连接

 @return 是否连接成功
 */
- (BOOL)connectSocket {
    
    //连接指定服务器的对应端口
    return [self.clientSocket connectToHost:kHost onPort:kPort viaInterface:nil withTimeout:-1 error:nil];
    
}


/**
 断开连接
 */
- (void)closeSocket {
    
    self.socketType = SocketOfflineByUser;
    [self.clientSocket disconnect];
    
    //注意:断开连接时,需要清理代理和客户端的socket
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
    
    //停止心跳连接
    if (self.connectTimer) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
    
}


/**
 发送消息
 */
- (void)sendMsg:(NSString *)msg {
    
    //timeout:请求超时时间,-1-->无穷大,一直等    tag:消息标记
    [self.clientSocket writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:100];
    
}

#pragma mark - Getters And Setters
- (GCDAsyncSocket *)clientSocket {
    if (_clientSocket == nil) {
        
        //创建客户端socket,代理队列必须为主队列
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
    }
    return _clientSocket;
}

@end
