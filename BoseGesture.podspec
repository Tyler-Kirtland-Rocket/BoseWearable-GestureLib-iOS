Pod::Spec.new do |s|

    s.name          = "BoseGesture"
    s.version       = "1.1.3"
    s.summary       = "Bose Gesture Library"

    s.description   = <<-DESC
    Bose Gesture Library for iOS
                      DESC

    s.homepage      = "https://developer.bose.com"

    s.author        = "Bose Corporation"
    s.source        = { :git => "https://github.com/Bose/BoseWearable-GestureLib-iOS.git", :tag => "#{s.version}" }
    s.license       = { :type => "MIT" }

    s.platform      = :ios, "12.0"
    s.swift_version = "5.1"

    s.source_files = "BoseGesture/Source/**/*.{swift,mlmodel}"

    s.dependency "BoseWearable"
    s.dependency "BLECore"
    s.dependency "BoseLogging"
    s.weak_frameworks = 'BoseWearable', 'Logging', 'BLECore'
  end
