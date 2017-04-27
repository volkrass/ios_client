platform :ios, '10.0'
project 'PharmaSupplyChain.xcodeproj'

target 'PharmaSupplyChain' do
  use_frameworks!
    
  pod 'Alamofire'
  pod 'SwiftyJSON'
  pod 'Firebase/Core'
  pod 'UXCam'
  pod 'Charts'
  pod 'FoldingCell'
  pod 'ObjectMapper'
  pod 'AlamofireObjectMapper'
  pod 'Spring', :git => 'https://github.com/MengTo/Spring.git', :branch => 'swift3'
  pod 'ReachabilitySwift', '~> 3'
  pod 'AMPopTip'
  
  target 'PharmaSupplyChainTests' do
      inherit! :search_paths
      
      #'Firebase' pod modifies header search paths and test target cannot see
      # this line is fix and workaround
      pod 'Firebase'
  end
  
end
