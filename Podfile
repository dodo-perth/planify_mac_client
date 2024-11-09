platform :macos, '11.0'

target 'planify_mac_client' do
  use_frameworks!
  
  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Calendar', '~> 3.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end 