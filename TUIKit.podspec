

Pod::Spec.new do |s|


  s.name         = "TUIKit"

  s.version      = "0.0.1"

  s.summary      = "iOS TUIKit TUIKit"

  s.description  = <<-DESC
  					能优化和严格的内存控制让其运行更加的流畅和稳健。
                   DESC

  s.homepage     = "https://github.com/Miles-Matheson"

  s.license      = "MIT"

  s.author       = { "John" => "liyida188@163.com" }

  s.platform     = :ios, "10.0"

  s.source       = { :git => "https://github.com/Miles-Matheson/TUIKit.git", :tag => "0.0.1" }

  s.requires_arc = true

  s.default_subspec = "Core"

  s.subspec "Core" do |core|
    core.source_files   = "TUIKit/**/*.{h,m}"
    core.resources      = "TUIKit/Resources/*.{png,bundle}"
    core.dependency 'TXIMSDK_Plus_iOS'
  end


end
