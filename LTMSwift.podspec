#
# Be sure to run `pod lib lint LTMSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LTMSwift'
  s.version          = '0.2.8'
  s.summary          = 'Swift 项目常用组件库.'

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
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kenan' => 'houkenan0620@126.com' }
  s.source           = { :git => 'https://github.com/Les-Trois-Mousquetaires/LTMSwift.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '11.0'

#  s.source_files = 'LTMSwift/Classes/**/*'
  s.swift_versions = '5.2'
  # s.resource_bundles = {
  #   'LTMSwift' => ['LTMSwift/Assets/*.png']
  # }

   s.frameworks = 'UIKit', 'Foundation'
  
  s.subspec 'Extension' do |ss|
      ss.source_files = 'LTMSwift/Classes/{*}+{*}.swift'
  end
  
  s.subspec 'HUDManage' do |ss|
      ss.source_files = 'LTMSwift/Classes/LTMHUDManage.swift'
  end
  
  s.subspec 'PopView' do |ss|
      ss.source_files = 'LTMSwift/Classes/Pop{*}.swift'
  end
  
  s.subspec 'Cell' do |ss|
      ss.source_files = 'LTMSwift/Classes/{*}Cell{*}.swift'
  end

end
