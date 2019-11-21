//
//  ViewController.m
//  GCWKWebViewJSBridge
//
//  Created by StriVever on 2019/11/20.
//  Copyright © 2019 StriVever. All rights reserved.
//

#import "GCViewController.h"
#import <GCWKWebViewJSBridge/GCWKWebViewJSBridge.h>
@import WebKit;
@interface GCViewController ()<WKNavigationDelegate>{
    WKWebView * webView;
    GCWKWebViewJSBridge * bridge;
}

@end

@implementation GCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    webView = [[WKWebView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    webView.navigationDelegate = self;
    bridge = [GCWKWebViewJSBridge bridgeWithWKWebView:webView];
    NSString * bundleStr = [[NSBundle mainBundle] pathForResource:@"GCTest" ofType:@"html"];
        
    NSURL * htmlURL = [NSURL fileURLWithPath:bundleStr];
    [webView loadRequest:[NSURLRequest requestWithURL:htmlURL]];
    [self.view addSubview:webView];
    
    
    //注册xcode控制台 输出web控制台信息
    [bridge registCaptureJSConsoleLog];
    [bridge registCaptureJSExceptionLog];
    //注册JS调用ocShare函数
    [bridge registJSMethod:@"ocCamera" nativeHandler:^(NSString * _Nonnull messageName, id  _Nonnull messageBody) {
        NSLog(@"%@",messageBody);
    }];
     //批量注册JS调用oc函数
    [bridge registJSMethods:@[@"ocShare",@"getUserJson"] nativeHandler:^(NSString * _Nonnull messageName, id  _Nonnull messageBody) {
         NSLog(@"%@:%@",messageName,messageBody);
    }];
    
    //oc向JS注入实例变量，可用来向h5注入用户token，信息等等
    NSDictionary * userInfo = @{@"uid":@"10086",@"name":@"中国移动",@"age":@"22",@"token":@"oidahnfjabfiabfuaojfbaiufbafo"};
    [bridge nativeUploadJSArguments:userInfo filedName:@"uoloadUser" inTime:WKUserScriptInjectionTimeAtDocumentStart];
   
    //oc向JS注入参数，可用来向h5注入一个带参数返回值的函数，供h5调用
    NSArray * lists = @[@"周1",@"周2",@"周3",@"周4"];
    [bridge nativeUploadJSArguments:lists useMethod:@"getOCMessage" inTime:WKUserScriptInjectionTimeAtDocumentStart];
    
    //注册拦截www.baidu.com
    [bridge registInterceptURLKey:@"www.baidu.com" handler:^(NSString * _Nonnull keyURL, NSString * _Nonnull URL) {
        
    }];
    //批量注册拦截www.baidu.com
    [bridge registInterceptURLKeys:@[@"share:123",@"share:12345",@"share://info#"] handler:^(NSString * _Nonnull keyURL, NSString * _Nonnull URL) {
        NSLog(@"%@====\n%@",keyURL,URL);
    }];
    
    UIButton  * btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn1 setTitle:@"App调用JS1" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(callJS:) forControlEvents:UIControlEventTouchUpInside];
    btn1.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:btn1];
    btn1.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 300, [UIScreen mainScreen].bounds.size.height - 50, 60, 30);
    btn1.tag = 1;
    [btn1 sizeToFit];
    UIButton  * btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn2 setTitle:@"App调用JS2" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(callJS:) forControlEvents:UIControlEventTouchUpInside];
    btn2.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 180, [UIScreen mainScreen].bounds.size.height - 50, 60, 30);
    [btn2 sizeToFit];
    btn2.backgroundColor = [UIColor redColor];
    [self.view addSubview:btn2];
}
#pragma mark ---WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    if ([bridge webViewBridgeCanInterceptURL:navigationAction.request.URL.absoluteString]) {
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
#pragma mark --- click response
- (void)callJS:(UIButton *)button{
    if (button.tag == 1) {
        //app调用js,带一个参数的，参数可以为字典和字符串
        [bridge nativeCallJSMethod:@"ocCallJS" arguments:@"app调用JS成功" completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
            
        }];
    }else{
         //app调用js,带多个可变参数，个数与JS端保持一致
        [bridge nativeCallJSMethod:@"ocCallJS1" completionHandler:^(id  _Nullable result, NSError * _Nullable error) {
            
        } arguments:@"我叫中国移动",@"今年1岁了",@"性别男",@"uid10086",nil];
    }
}

@end
