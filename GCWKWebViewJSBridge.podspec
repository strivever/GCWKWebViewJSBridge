#
# Be sure to run `pod lib lint GCWKWebViewJSBridge.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GCWKWebViewJSBridge'
  s.version          = '0.1.0'
  s.summary          = 'iOS native 与 WKWebView深度交互，并提供了js日志输出到xcode控制台'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/458362366@qq.com/GCWKWebViewJSBridge'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "gancaoyisheng"
  s.source           = { :git => 'https://github.com/strivever/GCWKWebViewJSBridge.git', :tag => '0.1.0' }
  s.ios.deployment_target = '8.0'
  s.source_files = 'GCWKWebViewJSBridge/Classes/*.{h,m}'
  s.public_header_files = "GCWKWebViewJSBridge/Classes/GCWKWebViewJSBridge.h"
end
