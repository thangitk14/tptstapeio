Pod::Spec.new do |s|
  s.name             = 'TPTStapeSDK'
  s.version          = '1.0.1'
  s.summary          = 'StapeSDK to use with Stape.io service'
  s.description      = 'Awesome Stape.io SDK, use it for fun and profit! Support Objective C'
  s.homepage         = 'https://akachains.utop.io'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'TPTStape' => 'thangtp@utop.io' }
  s.source           = { :git => 'https://github.com/stape-io/stape-sgtm-ios.git', :tag => s.version.to_s }
  s.swift_version    = '4.0'

  s.ios.deployment_target = '14.0'

  s.source_files = 'StapeSDK/StapeSDK/**/*'
end
