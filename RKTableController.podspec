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
  
  s.dependency 'RestKit', '>= 0.20.0dev'
end
