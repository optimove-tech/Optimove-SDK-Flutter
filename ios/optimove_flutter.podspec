#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint optimove_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'optimove_flutter'
  s.version          = '3.3.2'
  s.summary          = 'Optimove SDK Flutter plugin project.'
  s.description      = <<-DESC
The Optimove SDK framework is used for reporting events and receive push notifications.
                       DESC
  s.homepage         = 'https://www.optimove.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Optimove' => 'mobile@optimove.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.dependency 'OptimoveCore', '~> 6.2.3'
  s.dependency 'OptimoveSDK', '~> 6.2.3'
end
