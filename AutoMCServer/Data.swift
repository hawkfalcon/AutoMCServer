//
//  Data.swift
//  AutoMCServer
//
//  Created by Tristen Miller on 2/11/15.
//  Copyright (c) 2015 Tristen Miller. All rights reserved.
//

class Data {
    private struct OptionsStruct { static var serveroptions: ServerOptions! }
    private struct PropertiesStruct { static var properties: ServerProperties! }
    
    class var options: ServerOptions {
        get { return OptionsStruct.serveroptions }
        set { OptionsStruct.serveroptions = newValue }
    }
    
    class var properties: ServerProperties {
        get { return PropertiesStruct.properties }
        set { PropertiesStruct.properties = newValue }
    }
}
