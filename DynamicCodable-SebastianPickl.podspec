Pod::Spec.new do |s|
  s.name         = 'DynamicCodable-SebastianPickl'
  s.module_name  = 'DynamicCodable'
  s.version      = '0.1.2'
  s.summary      = 'Swift PropertyWrappers that use Codable to decode and encode types that are determined at runtime based on JSON data.'
  s.description  = <<-DESC
  Swift Property Wrappers based on Codable for decoding (and encoding) abstract types that are defined in the (JSON) data that should be decoded.
DESC
  s.homepage     = 'https://github.com/sebastianpixel/DynamicCodable'
  s.authors            = 'Sebastian Pickl'
  s.social_media_url   = 'http://twitter.com/SebastianPickl'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.swift_versions = '5.3'
  s.ios.deployment_target  = '9.0'
  s.osx.deployment_target  = '10.10'
  s.source       = { :git => 'https://github.com/sebastianpixel/DynamicCodable.git', :tag => "#{s.version}" }
  s.source_files  = 'Sources/DynamicCodable/**/*.swift'
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/DynamicCodableTests'
  end
end
