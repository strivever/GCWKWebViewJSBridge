//
//  GCWKWebViewJSBridge.h
//  GCWKWebViewJSBridge
//
//  Created by StriVever on 2019/11/20.
//  Copyright © 2019 StriVever. All rights reserved.
//

#import <Foundation/Foundation.h>
@import WebKit;
NS_ASSUME_NONNULL_BEGIN
typedef void(^interceptURLHandler)(NSString *keyURL,NSString * URL);
typedef void(^handler)(NSString *messageName,id messageBody);

@interface GCWKWebViewJSBridge : NSObject<WKScriptMessageHandler>
+ (instancetype)bridgeWithWKWebView:(WKWebView *)webView;
//注册捕获JS异常，跨域问题详细信息可能捕获不到；能捕获到JS未实现OC需要调用的函数错误
- (void)registCaptureJSExceptionLog;
/// 注册输出web端控制台信息
- (void)registCaptureJSConsoleLog;
- (void)registInterceptURLKeys:(NSArray *)keyUrls handler:(interceptURLHandler)handler;
- (void)registInterceptURLKey:(NSString *)keyURL handler:(interceptURLHandler)handler;
- (BOOL)webViewBridgeCanInterceptURL:(NSString *)URL;
/// @param jsCode js代码以字符串形式
/// @param userScriptInjectionTime 注入时机
- (void)registNativeUserScript:(NSString *)jsCode inTime:(WKUserScriptInjectionTime)userScriptInjectionTime;

/// 向JS注入一个全局变量，供JS使用
/// @param param  变量值,可以是字符串，或者JSON对象
/// @param filedName 变量名称
/// @param userScriptInjectionTime 注入时机
/// 前端使用：取值即可
- (void)nativeUploadJSArguments:(id)param filedName:(NSString *)filedName inTime:(WKUserScriptInjectionTime)userScriptInjectionTime;

/// 向JS注入带返回值得函数，供JS获取native信息
/// @param param 变量值 可以是字符串，或者JSON对象
/// @param methodName  js调用函数名
/// @param userScriptInjectionTime js注入时机
/**
 前端使用：
 Let x = window.【methodName()】
 x为获得参数值
 */
- (void)nativeUploadJSArguments:(id)param useMethod:(NSString *)methodName inTime:(WKUserScriptInjectionTime)userScriptInjectionTime;

/// JS调用native
/// @param jsMethod js函数名称
/// @param nativehandler native响应的回调
/**
 前端用法
 window.webkit.messageHandlers.【jsMethod】.postMessage(【需要传给native的参数】)
 ,支持重复注入相同js method，覆盖旧的。
 */
- (void)registJSMethod:(NSString *)jsMethod nativeHandler:(handler)nativehandler;
/// 批量注册
- (void)registJSMethods:(NSArray *)jsMethods nativeHandler:(handler)nativehandler;
/**
native 调用JS函数
@param methodName JS函数名
@param param 向JS传入参数,只支持一个参数，可以是字符串，或者JSON对象
@param completionHandler JS回调

前端：
实现 相应的method
*/
- (void)nativeCallJSMethod:(NSString *)methodName arguments:(id)param completionHandler:(void (^)(id _Nullable result, NSError * _Nullable))completionHandler;
/**
native 调用JS函数
@param methodName JS函数名
@param param 向JS传入多个参数,必须都为字符串形式，参数个数 与JS端保持一致，可以是字符串，或者JSON对象
@param completionHandler JS回调
前端：
实现 相应的method
*/
- (void)nativeCallJSMethod:(NSString *)methodName completionHandler:(void (^)(id _Nullable result, NSError * _Nullable))completionHandler arguments:(NSString *)param, ...;
///移除所有注入脚本
- (void)removeAllUserScripts;
- (void)removeScriptMessageHandlerForName:(NSString *)method;

/// 查看注入的所有js脚本，用于debug
- (NSString *)desciptionUserJScripts;
///清除所有注入JS脚本，注入回调
- (void)clearAll;
@end

NS_ASSUME_NONNULL_END
