Pod::Spec.new do |s|

  s.name = 'RokyinfoBLE'
  s.version = '0.1'
  s.license = 'MIT'
  s.summary = 'ble library on ios'
  s.description = <<-DESCRIPTION
                  runloop+queue 
                  DESCRIPTION
  # s.screenshots  = "http://images.jumppo.com/uploads/BabyBluetooth_logo.png", ""

  s.homepage = 'https://github.com/yuanzj/RokyinfoBLE'
  s.author = { 'jswxyzj' => 'jswxyzj@qq.com' } 

  s.source = {
    :git => 'https://github.com/yuanzj/RokyinfoBLE.git',
    :tag => '0.1'
  }
  s.platform = :ios, '8.0'
  s.source_files = 'Classes/*.{h,m}'
  s.requires_arc = true

  # s.dependency 'BabyBluetooth','~> 0.5.0'
  s.dependency 'CocoaLumberjack'

end
