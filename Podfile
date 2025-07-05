platform :ios, '16.0'
use_frameworks!

target 'FlirtFrame' do
  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  
  # Optional: Add other dependencies here
  
  target 'FlirtFrameTests' do
    inherit! :search_paths
    # Test pods
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end