Pod::Spec.new do |s|
  s.name         = "RKTableController"
  s.version      = "0.5.0"
  s.summary      = "RKTableController provides stateful, network integrated UITableViews powered by RestKit."
  s.homepage     = "https://github.com/RestKit/RKTableController"

  s.license      = { :type => 'Apache', :file => 'LICENSE'}

  s.author       = { "Blake Watters" => "blakewatters@gmail.com" }

  s.platform     = :ios, '5.0'
  s.requires_arc = true
  
  s.source       = { :git => "https://github.com/RestKit/RKTableController.git" }
  s.source_files = 'Code/*.{h,m}'
  s.ios.framework    = 'QuartzCore'
  
  s.dependency 'RestKit', '~> 0.22.0'
  
  s.prefix_header_contents = <<-EOS
#import <Availability.h>

#define _AFNETWORKING_PIN_SSL_CERTIFICATES_

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <MobileCoreServices/MobileCoreServices.h>
  #import <Security/Security.h>
#else
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <CoreServices/CoreServices.h>
  #import <Security/Security.h>
#endif

#ifdef COCOAPODS_POD_AVAILABLE_RestKit_CoreData
    #import <CoreData/CoreData.h>
#endif
EOS
end
