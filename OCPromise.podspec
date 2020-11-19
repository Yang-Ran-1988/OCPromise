#
# Be sure to run `pod lib lint OCPromise.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OCPromise'
  s.version          = '0.1.4'
  s.summary          = 'A short description of OCPromise.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Yang-Ran-1988/OCPromise'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '杨然' => 'yangran_1988@hotmail.com' }
  s.source           = { :git => 'https://github.com/Yang-Ran-1988/OCPromise.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'OCPromise/Classes/**/*'
end
