#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint multi_ads_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'multi_ads_sdk'
  s.version          = '1.0.5'
  s.summary          = 'A comprehensive Flutter SDK for multi-provider ads'
  s.description      = <<-DESC
A comprehensive Flutter SDK for multi-provider ads (AdMob, AdX, Facebook) with single-load and single-show pattern.
                       DESC
  s.homepage         = 'https://github.com/yourusername/multi_ads_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Ad dependencies
  s.dependency 'Google-Mobile-Ads-SDK', '~> 10.0'
  s.dependency 'FBAudienceNetwork', '~> 6.16'
end
