# Fastlane configuration for FlirtFrame

default_platform(:ios)

platform :ios do
  
  # Setup Firebase lane
  desc "Download GoogleService-Info.plist for Firebase"
  lane :setup_firebase do
    # Ensure GoogleService-Info.plist is present
    unless File.exist?("../GoogleService-Info.plist")
      UI.error("GoogleService-Info.plist not found! Please add it to the project root.")
    end
  end
  
  # Beta deployment lane
  desc "Deploy a new beta build to TestFlight"
  lane :beta do
    ensure_git_status_clean
    setup_firebase
    
    # Increment build number
    increment_build_number(xcodeproj: "FlirtFrame.xcodeproj")
    
    # Build the app
    build_app(
      scheme: "FlirtFrame",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.flirtframe.app" => "FlirtFrame Distribution"
        }
      }
    )
    
    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      apple_id: "1234567890"
    )
    
    # Commit version bump
    commit_version_bump(
      message: "Version bump for beta build #{get_build_number}",
      xcodeproj: "FlirtFrame.xcodeproj"
    )
    
    # Push to remote
    push_to_git_remote
    
    # Notify team
    slack(
      message: "New beta build #{get_version_number} (#{get_build_number}) uploaded to TestFlight! 🚀",
      slack_url: ENV["SLACK_WEBHOOK_URL"]
    )
  end
  
  # App Store release lane
  desc "Deploy a new version to the App Store"
  lane :release do
    ensure_git_status_clean
    
    # Run tests
    run_tests(scheme: "FlirtFrame")
    
    # Screenshots
    capture_screenshots
    
    # Build the app
    build_app(
      scheme: "FlirtFrame",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.flirtframe.app" => "FlirtFrame Distribution"
        }
      }
    )
    
    # Upload to App Store
    upload_to_app_store(
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: true,
      automatic_release: false,
      force: true,
      precheck_include_in_app_purchases: false,
      submission_information: {
        add_id_info_uses_idfa: false,
        export_compliance_uses_encryption: false
      }
    )
    
    # Create git tag
    add_git_tag(
      tag: "v#{get_version_number}"
    )
    
    # Push everything
    push_to_git_remote(
      remote_branch: "main",
      tags: true
    )
    
    # Notify team
    slack(
      message: "FlirtFrame #{get_version_number} submitted to App Store! 🎉",
      slack_url: ENV["SLACK_WEBHOOK_URL"]
    )
  end
  
  # Test lane
  desc "Run all tests"
  lane :test do
    run_tests(
      scheme: "FlirtFrame",
      devices: ["iPhone 14", "iPhone 15 Pro"],
      clean: true,
      code_coverage: true
    )
  end
  
  # Screenshot lane
  desc "Generate new screenshots"
  lane :screenshots do
    capture_screenshots(
      workspace: "FlirtFrame.xcworkspace",
      scheme: "FlirtFrame",
      clear_previous_screenshots: true,
      devices: [
        "iPhone 15 Pro",
        "iPhone 15 Pro Max",
        "iPhone SE (3rd generation)",
        "iPad Pro (12.9-inch) (6th generation)"
      ]
    )
    
    frame_screenshots(
      path: "./fastlane/screenshots",
      use_platform: "IOS"
    )
  end
  
  # Certificates lane
  desc "Sync certificates and provisioning profiles"
  lane :certs do
    match(
      type: "development",
      app_identifier: "com.flirtframe.app",
      readonly: true
    )
    
    match(
      type: "appstore",
      app_identifier: "com.flirtframe.app",
      readonly: true
    )
  end
  
  # Clean lane
  desc "Clean build artifacts"
  lane :clean do
    clean_build_artifacts
    clear_derived_data
  end
  
  # Version bump lane
  desc "Bump version"
  lane :bump do |options|
    bump_type = options[:type] || "patch"
    
    increment_version_number(
      bump_type: bump_type,
      xcodeproj: "FlirtFrame.xcodeproj"
    )
    
    commit_version_bump(
      message: "Version bump to #{get_version_number}",
      xcodeproj: "FlirtFrame.xcodeproj"
    )
  end
  
  # Error handling
  error do |lane, exception|
    slack(
      message: "Error in lane #{lane}: #{exception.message}",
      slack_url: ENV["SLACK_WEBHOOK_URL"],
      success: false
    )
  end
  
end