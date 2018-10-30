# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Dank Ranks Revisited' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Dank Ranks Revisited
  pod 'Eureka'
  pod 'Combinatorics'
  pod 'ImagePicker'
  pod 'Lightbox'
  pod 'SwiftyStoreKit'
  pod 'IQKeyboardManagerSwift'
  pod 'EVCloudKitDao'
  pod 'KRProgressHUD'
  pod 'LGButton'
  pod 'Disk'
  pod 'NVActivityIndicatorView'
  pod 'SwiftMessages'
  pod 'DHSmartScreenshot'
  pod 'ReachabilityLib'

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end

end
