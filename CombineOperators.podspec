#
# Be sure to run `pod lib lint RxOperators.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CombineOperators'
  s.version          = '1.45.0'
  s.summary          = 'A short description of CombineOperators.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/dankinsoid/CombineOperators'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Voidilov' => 'voidilov@gmail.com' }
  s.source           = { :git => 'https://github.com/dankinsoid/CombineOperators.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.1'
  s.source_files = 'Sources/CombineOperators/**/*'
  s.dependency 'VD', '~> 1.13.0'
  s.frameworks = 'Foundation', 'UIKit', 'Combine'

  s.subspec 'CombineCocoa' do |provider|
    provider.source_files = 'Sources/CombineCocoa/**/*.swift', 'Sources/CombineCocoaRuntime/**/*', 'Sources/CombineOperators/**/*'
  	provider.frameworks = 'Foundation', 'UIKit', 'Combine'
  	provider.dependency 'VD'
  end
  
end
