#
# Be sure to run `pod lib lint LTMSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LTMSwift'
  s.version          = '0.2.2'
  s.summary          = 'LTMSwift is swift often uselib.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  LTMSwift is swift often uselib.
  LTMExtension is Swift Classes folder tool
  LTMExtension is tools folder

                       DESC

  s.homepage         = 'https://github.com/Les-Trois-Mousquetaires/LTMSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'coenen' => 'coenen@aliyun.com' }
  s.source           = { :git => 'https://github.com/Les-Trois-Mousquetaires/LTMSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'LTMSwift/Classes/**/*'
  s.swift_versions = '5.2'
  # s.resource_bundles = {
  #   'LTMSwift' => ['LTMSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'Foundation'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.subspec "LTMExtension" do |ss|
    ss.source_files  = 'LTMSwift/Classes/LTMExtension/'
    ss.framework  = 'UIKit', 'Foundation'
  end
  
  s.subspec "LTMFoundation" do |ss|
    ss.source_files  = 'LTMSwift/Classes/LTMFoundation/'
    ss.framework  = 'UIKit', 'Foundation'
    ss.dependency "LTMSwift/LTMExtension"

  end

end
