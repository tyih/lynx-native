// Copyright 2017 The Lynx Authors. All rights reserved.

#import "LynxRuntime.h"
#import "LYXModuleRegister.h"
#import "LYXDeviceInfoUtil.h"
#import "LYXScreenUtil.h"

#include "config/global_config_data.h"
#include "parser/render_parser.h"
#include "render/render_tree_host.h"
#include "render/ios/render_tree_host_impl_ios.h"
#include "runtime/base/lynx_function_object_ios.h"
#include "runtime/jsc/jsc_context.h"

@implementation LynxRuntime

static CGFloat kDefaultZoomRatio = -1;

+ (CGFloat) defaultZoomRatio {
    return kDefaultZoomRatio;
}

- (id) init {
    self = [super init];
    if (self) {
        runtime_ = new jscore::Runtime(new jscore::JSCContext());
        // Default
        runtime_->InitRuntime("");
    }
    return self;
}

- (void) prepare {
    [self prepareWithZoomRatio: -1];
}

- (void) prepareWithZoomRatio:(CGFloat) zoomRatio {
    std::string deviceInfo = [[LYXDeviceInfoUtil deviceInfo] UTF8String];
    config::GlobalConfigData::GetInstance()->SetScreenConfig([[LYXScreenUtil shareInstance] getScreenWidth],
                                                             [[LYXScreenUtil shareInstance] getScreenHeight],
                                                             [[LYXScreenUtil shareInstance] getScreenDensity],
                                                             zoomRatio,
                                                             deviceInfo);
}

- (LynxRenderTreeHostImpl *) active {
    // Create RenderTreeHost
    lynx::RenderTreeHost* render_tree_host = runtime_->SetupRenderHost();
    LYXModuleRegister *moduleRegister = [[LYXModuleRegister alloc] initWithRuntime:self];
    _host = reinterpret_cast<lynx::RenderTreeHostImplIOS*>(render_tree_host->host_impl())->ios();
    return _host;
}

- (void)loadUrl:(NSString *)url {
    runtime_->LoadUrl(std::string([url UTF8String]));
}

- (void)loadHtml:(NSString *)url withSource:(NSString*)html{
    base::PlatformString scoped_url(url);
    base::PlatformString scoped_source(html);
    runtime_->LoadHTML(scoped_url.ToString(), scoped_source.ToString());
}

- (void)loadHtmlData:(NSString *)html {
    base::PlatformString scoped_source(html);
    runtime_->LoadHTML(scoped_source.ToString());
}

- (NSString *) runScript:(NSString *)script {
    base::PlatformString scoped_source(script);
    runtime_->RunScript(scoped_source);
    return @"";
}

- (void) addJavaScriptInterface:(LYXFunctionObject *) object
                       withName:(NSString *) name {
    runtime_->AddJavaScriptInterface([name UTF8String], new jscore::LynxFunctionObjectIOS(object));
}

- (void)destroy {
    runtime_->Destroy();
}

@end
