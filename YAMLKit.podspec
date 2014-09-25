Pod::Spec.new do |s|
  s.name         = "YAMLKit"
  s.version      = "0.1"
  s.summary      = "YAMLKit is an Objective-C library wrapping the LibYAML library."

  s.description  = <<-DESC
                   YAMLKit is an Objective-C library wrapping the LibYAML library.
                   It is written by Patrick Thomson and licensed under the MIT License.
                   At this point it is quite mature, having been used in commercial projects on Mac and iOS.
                   DESC

  s.homepage     = "https://github.com/andy128k/yamlkit"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors      = { "Patrick Thomson" => "patrick.william.thomson@gmail.com",
                     "Andrey Kutejko" => "andrey.kutejko@anahoret.com" }

  s.source       = { :git => "https://github.com/andy128k/yamlkit.git", :tag => '0.1' }
  s.requires_arc = false

  s.source_files = "src/*.{h,m}"
  s.public_header_files = "src/*.h"

  s.dependency 'LibYAML'
end
