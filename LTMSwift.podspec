#
# Be sure to run `pod lib lint LTMSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LTMSwift'
  s.version          = '0.1.1'
  s.summary          = 'LTMSwift is swift often uselib.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  LTMSwift is swift often uselib.
                       DESC

  s.homepage         = 'https://github.com/Les-Trois-Mousquetaires/LTMSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kenan0620' => 'coenen@aliyun.com' }
  s.source           = { :git => 'https://github.com/Les-Trois-Mousquetaires/LTMSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'LTMSwift/Classes/LTMExtension/**/*'
  
  # s.resource_bundles = {
  #   'LTMSwift' => ['LTMSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
