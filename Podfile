source "https://github.com/CocoaPods/Specs.git"

use_frameworks!

inhibit_all_warnings!

target 'LookinClient' do
    platform :osx, '10.14'
    pod 'AppCenter'
    pod 'ReactiveObjC', '3.1.0'
    pod 'Sparkle', '~> 1.0'

#    pod 'LookinShared', :git=>'https://github.com/zhangjie579/LookinServer', :branch => 'personal/samzj'

    pod 'LookinShared', :path=>'../LookinServer/'

    # pod 'LookinShared', :git=>'https://github.com/QMUI/LookinServer.git', :branch => 'release/1.1.3'
end

target 'LookinTestflight' do
    platform :osx, '10.14'
    pod 'AppCenter'
    pod 'ReactiveObjC', '3.1.0'
    pod 'Sparkle', '~> 1.0'

    pod 'LookinShared', :path=>'../LookinServer/'

    # pod 'LookinShared', :git=>'https://github.com/QMUI/LookinServer.git', :branch => 'release/1.1.3'
end
