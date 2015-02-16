//
//  Data.swift
//  AutoMCServer
//
//  Created by Tristen Miller on 2/11/15.
//  Copyright (c) 2015 Tristen Miller. All rights reserved.
//

class Data {
    private struct SubStruct { static var serveroptions: ServerOptions! }
    
    class var options: ServerOptions {
        get { return SubStruct.serveroptions }
        set { SubStruct.serveroptions = newValue }
    }
}
