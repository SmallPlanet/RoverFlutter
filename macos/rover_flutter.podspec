#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rover_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rover_flutter'
  s.version          = '0.1.0'
  s.summary          = 'Flutter wrapper for Rover (https://github.com/SmallPlanet/RoveriOS)'
  s.description      = 'Flutter wrapper for Rover (https://github.com/SmallPlanet/RoveriOS)'
  s.homepage         = 'https://www.smallplanet.com'
  s.license          = "MIT"
  s.author           = { 'Small Planet' => 'support@smallplanet.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  s.dependency "RoveriOS", '0.4.19'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '12.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
