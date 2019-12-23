//
//  GCWKWebViewJSBridge.m
//  GCWKWebViewJSBridge
//
//  Created by StriVever on 2019/11/20.
//  Copyright © 2019 StriVever. All rights reserved.
//

#import "GCWKWebViewJSBridge.h"

#define MaxMatchScore  1000
@interface GCWKWebViewJSBridge ()
///
@property (nonatomic, strong) NSMutableDictionary<NSString *,handler> * jsHandlerDict;
///通过URL链接拦截形式回调
@property (nonatomic, strong) NSMutableDictionary * interceptURLHandlerDict;
///管理需要拦截的URL链接
@property (nonatomic, strong) NSMutableArray * interceptKeyURLArray;
@property (nonatomic, weak) WKWebView * webView;
@end
@implementation GCWKWebViewJSBridge
- (void)dealloc{
    [self clearAll];
}
#pragma mark --- public
+ (instancetype)bridgeWithWKWebView:(WKWebView *)webView{
    GCWKWebViewJSBridge * jsBridge = [[GCWKWebViewJSBridge alloc]init];
    [jsBridge setupWKWebView:webView];
    return jsBridge;
}
- (void)setupWKWebView:(WKWebView *)webView{
    self.webView = webView;
}
- (void)removeAllUserScripts{
    [self.webView.configuration.userContentController removeAllUserScripts];
}
- (void)removeScriptMessageHandlerForName:(NSString *)method{
    @try {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:method];
        [self.jsHandlerDict removeObjectForKey:method];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}
- (void)removeAllScriptMessageHandler{
    for (NSString * method in self.jsHandlerDict.allKeys) {
        [self removeScriptMessageHandlerForName:method];
    }
    [self.jsHandlerDict removeAllObjects];
}
- (void)clearAll{
    [self removeAllUserScripts];
    [self removeAllScriptMessageHandler];
    [self.interceptURLHandlerDict removeAllObjects];
}
- (NSString *)desciptionUserJScripts{
    NSString * description = @"已注入JS脚本:===================\n";
    for (WKUserScript * script in [self allUserScripts]) {
        description = [description stringByAppendingString:script.source];
        description = [description stringByAppendingString:@"\n\n"];
    }
    description = [description stringByAppendingString:@"\n==================="];
    return description;
}
- (NSArray *)allUserScripts{
    return self.webView.configuration.userContentController.userScripts.copy;
}
#pragma mark --- 捕获js控住台log
- (void)registCaptureJSConsoleLog{
#if defined(DEBUG) && DEBUG == 1
    NSString *jsCode = @"console.log = (function(consoleLog){\
    return function(jsLog)\
    {\
    window.webkit.messageHandlers.nativeLog.postMessage(jsLog);\
    consoleLog.call(console,jsLog);\
    }\
    })(console.log);";
    [self registNativeUserScript:jsCode inTime:WKUserScriptInjectionTimeAtDocumentStart];
    [self registJSMethod:@"nativeLog" nativeHandler:^(NSString * _Nonnull messageName, id  _Nonnull messageBody) {
        NSLog(@"\njs console log：%@\n",messageBody);
    }];
#endif
}
#pragma mark --- 捕获js异常
//注册js异常报错，跨域问题无法收集详细错误
- (void)registCaptureJSExceptionLog{
#if defined(DEBUG) && DEBUG == 1
    NSString *jsCode = @"window.onerror = function (msg, url, lineNum, columnNum, error) {\
        var string = msg.toLowerCase();\
        var substring = \"script error\";\
        if (string.indexOf(substring) > -1){\
            window.webkit.messageHandlers.nativeJSErrorLog.postMessage('Script Error: See Browser Console for Detail');\
        } else {\
            var message = [\
                'Message: ' + msg,\
                'URL: ' + url,\
                'Line: ' + lineNum,\
                'Column: ' + columnNum,\
                'Error object: ' + JSON.stringify(error)\
            ].join(' - ');\
            window.webkit.messageHandlers.nativeJSErrorLog.postMessage(message);\
        }\
        return false;\
    };";
    [self registNativeUserScript:jsCode inTime:WKUserScriptInjectionTimeAtDocumentStart];
    [self registJSMethod:@"nativeJSErrorLog" nativeHandler:^(NSString * _Nonnull messageName, id  _Nonnull messageBody) {
        NSLog(@"\njs exception %@\n",messageBody);
    }];
#endif
}
#pragma mark ---<##>注册URL拦截
- (void)registInterceptURLKeys:(NSArray *)keyUrls handler:(interceptURLHandler)handler{
    for (NSString * key in keyUrls) {
        [self registInterceptURLKey:key handler:handler];
    }
}

- (void)registInterceptURLKey:(NSString *)keyURL handler:(interceptURLHandler)handler{
    if (keyURL && handler) {
        [self.interceptKeyURLArray addObject:keyURL];
        [self.interceptURLHandlerDict setObject:[handler copy] forKey:keyURL];
    }
}
- (BOOL)webViewBridgeCanInterceptURL:(NSString *)URL{
    interceptURLHandler handler = nil;
    if ([self.interceptKeyURLArray count] == 0) {
        //不需要拦截事件
        return NO;
    }
    NSString * matchUrl = [self _machRuleWithUrl:URL];
    if ([matchUrl length] > 0) {
        handler = [self.interceptURLHandlerDict objectForKey:matchUrl];
        handler(matchUrl,URL);
        return YES;
    }
    return NO;
}
- (NSString *)_machRuleWithUrl:(NSString *)URL{
    NSString * matchedURL = @"";
    //匹配积分，取匹配最高的
    NSInteger currentMatchKeyScore = 0;
    for (NSString * keyURL in self.interceptKeyURLArray) {
        if ([keyURL isEqualToString:URL]){
            //精准匹配到了，退出循环
            matchedURL = keyURL;
            currentMatchKeyScore = MaxMatchScore;
            break;
        }
        //计算模糊匹配积分,以匹配到的keyURL长度计算积分，拦截得分最高的keyURL
        if ([URL containsString:keyURL]) {
            //以匹配到的字符长度为匹配分数
            NSInteger matchScore = keyURL.length;
            if (currentMatchKeyScore < matchScore) {
                matchedURL = keyURL;
                currentMatchKeyScore = matchScore;
            }
        }else continue;
    }
    return matchedURL;
}
#pragma mark ---<##>  注入JS脚本  js call native
- (void)nativeUploadJSArguments:(id)param filedName:(NSString *)filedName inTime:(WKUserScriptInjectionTime)userScriptInjectionTime{
    //向H5注入参数
    if (param) {
        NSString * jsonString = @"";
        NSString * jsCode = @"";
        if ([param isKindOfClass:[NSString class]]) {
            jsonString = param;
            jsCode = [NSString stringWithFormat:@"%@= '%@'",filedName,jsonString];
        }else{
            NSData * data = [NSJSONSerialization dataWithJSONObject:param options:(NSJSONWritingPrettyPrinted) error:nil];
            jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            jsCode = [NSString stringWithFormat:@"%@= %@",filedName,jsonString];
        }
        [self registNativeUserScript:jsCode inTime:userScriptInjectionTime];
    }
}
- (void)nativeUploadJSArguments:(id)param useMethod:(NSString *)methodName inTime:(WKUserScriptInjectionTime)userScriptInjectionTime{
    if (param) {
        NSString * jsonString = @"";
        NSString * jsCode = @"";
        if ([param isKindOfClass:[NSString class]]) {
            jsonString = param;
            jsCode = [NSString stringWithFormat:@"function %@(){return '%@';}",methodName,jsonString];
        }else{
            NSData * data = [NSJSONSerialization dataWithJSONObject:param options:(NSJSONWritingPrettyPrinted) error:nil];
            jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            jsCode = [NSString stringWithFormat:@"function %@(){return %@;}",methodName,jsonString];
        }
        [self registNativeUserScript:jsCode inTime:userScriptInjectionTime];
    }
}

- (void)registJSMethod:(NSString *)jsMethod nativeHandler:(handler)nativehandler{
    if (jsMethod && nativehandler) {
        if (self.jsHandlerDict[jsMethod]) {
            [self removeScriptMessageHandlerForName:jsMethod];
        }
        [self.jsHandlerDict setObject:[nativehandler copy] forKey:jsMethod];
        [self.webView.configuration.userContentController addScriptMessageHandler:self name:jsMethod];
    }
}
- (void)registJSMethods:(NSArray *)jsMethods nativeHandler:(handler)nativehandler{
    for (NSString * method in jsMethods) {
        [self registJSMethod:method nativeHandler:nativehandler];
    }
}

- (void)registNativeUserScript:(NSString *)jsCode inTime:(WKUserScriptInjectionTime)userScriptInjectionTime{
    WKUserScript *script = [[WKUserScript alloc] initWithSource:jsCode injectionTime:(userScriptInjectionTime) forMainFrameOnly:YES];
    NSAssert(self.webView != nil, @"请设置jsBridge webview");
    
    [self.webView.configuration.userContentController addUserScript:script];
}
#pragma mark --- native call js
- (void)nativeCallJSMethod:(NSString *)methodName arguments:(id)param completionHandler:(void (^)(id _Nullable result, NSError * _Nullable))completionHandler{
    NSString * jsCode = @"";
    NSString * jsonString = @"";
    if (param) {
        if ([param isKindOfClass:[NSString class]]) {
            jsonString = param;
            jsCode = [NSString stringWithFormat:@"%@('%@')",methodName,jsonString];
        }else{
            NSData * data = [NSJSONSerialization dataWithJSONObject:param options:(NSJSONWritingPrettyPrinted) error:nil];
            jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            jsCode = [NSString stringWithFormat:@"%@(%@)",methodName,jsonString];
        }
    }else{
         jsCode = [NSString stringWithFormat:@"%@()",methodName];
    }
    NSAssert(self.webView != nil, @"请设置jsBridge webview");
    [self.webView evaluateJavaScript:jsCode completionHandler:completionHandler];
}
- (void)nativeCallJSMethod:(NSString *)methodName completionHandler:(void (^)(id _Nullable result, NSError * _Nullable))completionHandler arguments:(NSString *)param, ...{
    va_list args;
    va_start(args, param);
    NSMutableArray * paramsList = [NSMutableArray array];
    for (NSString *str = param; str != nil; str = va_arg(args,NSString*)){
        str = [NSString stringWithFormat:@"'%@'",str];
        [paramsList addObject:str];
    }
    va_end(args);
    NSString * argStr = @"";
    NSString * jsCode = @"";
    if ([paramsList count] > 0) {
        argStr = [paramsList componentsJoinedByString:@","];
        jsCode = [NSString stringWithFormat:@"%@(%@)",methodName,argStr];
    }else{
        jsCode = [NSString stringWithFormat:@"%@()",methodName];
    }
     NSAssert(self.webView != nil, @"请设置jsBridge webview");
    [self.webView evaluateJavaScript:jsCode completionHandler:completionHandler];
}
#pragma mark ---<##>WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSString * methodName = message.name;
    id params = message.body;
    handler block = (handler)self.jsHandlerDict[methodName];
    if (block) {
        block(methodName,params);
    }
}
#pragma mark --- getter
- (NSMutableDictionary *)jsHandlerDict{
    if (_jsHandlerDict == nil) {
        _jsHandlerDict = @{}.mutableCopy;
    }
    return _jsHandlerDict;
}
- (NSMutableDictionary *)interceptURLHandlerDict{
    if (_interceptURLHandlerDict == nil) {
        _interceptURLHandlerDict = @{}.mutableCopy;
    }
    return _interceptURLHandlerDict;
}
- (NSMutableArray *)interceptKeyURLArray{
    if (_interceptKeyURLArray == nil) {
        _interceptKeyURLArray = @[].mutableCopy;
    }
    return _interceptKeyURLArray;
}

@end
