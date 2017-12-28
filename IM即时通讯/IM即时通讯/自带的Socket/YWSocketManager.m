//
//  YWSocketManager.m
//  IM即时通讯
//
//  Created by apple on 2017/12/25.
//  Copyright © 2017年 zjbojin. All rights reserved.
//

#import "YWSocketManager.h"
#import <sys/socket.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface YWSocketManager()

@property(nonatomic,assign)int clientSocket;    //客户端socket

@end

@implementation YWSocketManager

//IM客户端
/*
 1.客户端调用socket(...)创建socket
 2.客户端调用connect(...)向服务器发起连接请求
 3.客户端与服务器建立连接之后,通过send(...)／receive(...)发送或接收数据
 4.客户端调用close()关闭socket
 
 */

+ (instancetype)shareManager {
    
    static YWSocketManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[YWSocketManager alloc] init];
        
        //接收服务器消息
//        [manager startThreadRecieveMsg];
        
    });
    return manager;
}


#pragma mark - Privite Actions
/**
 创建客户端Socket
 
 */
static int CreateClientSocket() {
    
    //创建一个socket,返回值为int,若返回-1表示创建失败(注:socket其实就是int类型)
    /*
     1.第一个参数addressFamiy:IPv4(AF_INET)或IPv6(AF_INET6)
     2.第二个参数type(socket的类型):通常是流stream(SOCK_STREAM)或数据报文datagram(SOCK_DGRAM)
     
     流--->使用的网络协议是TCP协议,其流程是客户端建立socket,通过connect与服务器连接,read和write
     传输数据。在服务器端先建立连接，向内核申请socket，返回socket标识符，调用bind，将目标地
     址分配给socket，listen请求内核允许socket接入呼叫，accept接受呼叫，read和write传送
     呼叫。
     数据报文--->使用的网络协议是UDP协议,其流程是客户建立socket,传入主机号和目的端口,sendto发送消息。服务器建立socket，recvfrom接受消息，应答。
     
     3.第三个参数protocol:通常设着为0,以便让系统自动为我们选择合适的协议。对于stream socket来说是TCP协议(IPPROTP_TCP),对于datagram socket来说就是UDP协议(IPPROTO_UDP)
     */
    
    return socket(AF_INET, SOCK_STREAM, 0);
    
}


/**
 连接服务器
 
 @param client_socket 客户端Socket
 @param server_ip 服务器ip
 @param port 端口号
 @return 0--->连接失败
 */

static int ConnectToServer(int client_socket, const char *server_ip, unsigned short port) {
    
    /*
     * Socket address, internet style.
     */
    //生成一个sockaddr_in类型的结构体
    struct sockaddr_in sAddr = {0};
    sAddr.sin_len = sizeof(sAddr);
    //设置IPv4
    sAddr.sin_family = AF_INET;
    //设置端口号,htons是将整型变量从主机字节顺序转变成网络字节顺序，赋值端口号
    sAddr.sin_port = htons(port);
    
    //inet_aton是一个改进的方法来将一个字符串IP地址转换为一个32位的网络序列IP地址
    //如果这个函数成功，函数的返回值非零，如果输入地址不正确则会返回零。
    inet_aton(server_ip, &sAddr.sin_addr);
    
    //客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1
    //注意：该接口调用会阻塞当前线程，直到服务器返回
    if (connect(client_socket, (struct sockaddr *)&sAddr, sizeof(sAddr)) == 0 ) {
        return client_socket;
    }
    
    return 0;
    
}

#pragma mark - 开启新线程接收服务器消息
- (void)startThreadRecieveMsg {
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(recieveMsg) object:nil];
    [thread start];
    
}


#pragma mark - Public Actions
/**
 开始客户端socket连接
 */
- (void)connectSocket {
    
    //每次连接前,先断开连接
    if (self.clientSocket != 0) {
        [self closeConnect];
        _clientSocket = 0;
    }
    
    //创建客户端socket
    self.clientSocket = CreateClientSocket();
    
    //服务器ip
    const char *server_ip = "127.0.0.1";
    //服务器端口
    short server_port = 5222;
    //连接服务器
    if (ConnectToServer(self.clientSocket, server_ip, server_port) == 0) {
        NSLog(@"连接失败");
    } else {
        NSLog(@"连接成功");
    }
    
}


/**
 关闭客户端socket连接
 */
- (void)closeConnect {
    
    close(self.clientSocket);
    
}


/**
 发送消息

 @param msg 需要发送的消息内容
 */
- (void)sendMsg:(NSString *)msg {
    
    const char *send_Message = [msg UTF8String];
    //发送数据,发送成功则返回发送的字节数,否则返回-1
    ssize_t size = send(self.clientSocket, send_Message, strlen(send_Message) + 1, 0);
    if (size == -1) {
        NSLog(@"发送失败");
    } else {
        NSLog(@"发送成功字节数：%ld",size);
    }
}


/**
 接收服务器消息
 */
- (void)recieveMsg {
    
    while (1) {
        char recieve_Message[1024] = {0};
        recv(self.clientSocket, recieve_Message, sizeof(recieve_Message), 0);
        printf("----%s\n",recieve_Message);
    }
    
}



@end
