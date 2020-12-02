
Pod::Spec.new do |s|
    s.name         = "SHShortVideo"
    s.version      = "1.0.2"
    s.summary      = "仿微信录制小视频"
    s.license      = "MIT"
    s.authors      = { "CSH" => "624089195@qq.com" }
    s.platform     = :ios, "7.0"
    s.homepage     = "https://github.com/CCSH/SHShortVideo"
    s.source       = { :git => "https://github.com/CCSH/SHShortVideo.git", :tag => s.version }
    s.source_files = "SHShortVideo/*.{h,m}"
    s.resource     = "SHShortVideo/SHShortVideo.bundle"
    s.requires_arc = true
end
