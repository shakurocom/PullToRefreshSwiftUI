Pod::Spec.new do |s|

    s.name             = 'Shakuro.PullToRefreshSwiftUI'
    s.version          = '1.0.0'
    s.summary          = 'PullToRefreshSwiftUI'
    s.homepage         = 'https://github.com/shakurocom/PullToRefreshSwiftUI'
    s.license          = { :type => "MIT", :file => "LICENSE.md" }
    s.authors          = {'wwwpix' => 'spopov@shakuro.com'}
    s.source           = { :git => 'https://github.com/shakurocom/PullToRefreshSwiftUI.git', :tag => s.version }
    s.swift_versions   = ['5.9']
    s.source_files     = 'Sources/PullToRefreshSwiftUI/*'
    s.ios.deployment_target = '17.0'

end
