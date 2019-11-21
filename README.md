# GCWKWebViewJSBridge

[![CI Status](https://img.shields.io/travis/458362366@qq.com/GCWKWebViewJSBridge.svg?style=flat)](https://travis-ci.org/458362366@qq.com/GCWKWebViewJSBridge)
[![Version](https://img.shields.io/cocoapods/v/GCWKWebViewJSBridge.svg?style=flat)](https://cocoapods.org/pods/GCWKWebViewJSBridge)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://cocoapods.org/pods/GCWKWebViewJSBridge)
[![Platform](https://img.shields.io/cocoapods/p/GCWKWebViewJSBridge.svg?style=flat)](https://cocoapods.org/pods/GCWKWebViewJSBridge)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

GCWKWebViewJSBridge is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GCWKWebViewJSBridge', '~> 0.1.0'
```

## Author
strivever
## Description
WKWebView深度交互，并提供了js日志输出到xcode控制台;提供JS调用OC；提供OC调用JS；
OC通过注入变量给JS传参数；OC通过注册JS函数，供JS调用；js给OC传参；通过拦截链接，进行交互，进行了统一封装，统一管理你的拦截回调；
## use 
```
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
```
## License

GCWKWebViewJSBridge is available under the MIT license. See the LICENSE file for more info.
