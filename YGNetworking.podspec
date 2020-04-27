#
# Be sure to run `pod lib lint YGNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YGNetworking'
  s.version          = '4.0.1'
  s.summary          = '基于 AFNetworking 封装的一个网络库.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
基于 AFNetworking 封装的一层网络请求库，更便捷的使用方式和更好的扩展性。
                       DESC

  s.homepage         = 'https://github.com/oneofai/YGNetworking'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'oneofai' => 'holaux@gmail.com' }
  s.source           = { :git => 'https://github.com/oneofai/YGNetworking.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'YGNetworking/Classes/**/*'
  
  s.dependency 'AFNetworking', '~> 4.0'
end
