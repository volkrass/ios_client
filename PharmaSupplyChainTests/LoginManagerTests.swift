//
//  LoginManagerTests.swift
//  PharmaSupplyChain
//
//  Created by Yury Belevskiy on 26.04.17.
//  Copyright © 2017 Modum. All rights reserved.
//

import XCTest
@testable import PharmaSupplyChain

class LoginManagerTests : XCTestCase {
    
    override func tearDown() {
        LoginManager.shared.clear()
        
        super.tearDown()
    }
    
    func testStoreUserUsernameAndPassword() {
        /* store data*/
        LoginManager.shared.storeUser(username: "test", password: "test", response: nil, rememberMe: true)
        
        /* test*/
        XCTAssertNotNil(LoginManager.shared.getUsername())
        XCTAssert(LoginManager.shared.getUsername() == "test")
        XCTAssertNotNil(LoginManager.shared.getPassword())
        XCTAssert(LoginManager.shared.getPassword() == "test")
        XCTAssertNil(LoginManager.shared.getAuthToken())
        XCTAssertNil(LoginManager.shared.getAuthTokenExpiry())
        XCTAssertNil(LoginManager.shared.getCompanyName())
    }
    
    func testStoreUserLoginObject() {
        /* setup data */
        let loginObject = LoginObject()
        let expireDate = Date()
        loginObject.expire = expireDate
        loginObject.token = "test_token"
        let user = User()
        let company = Company()
        company.name = "Test Company"
        user.company = company
        loginObject.user = user
        
        /* store data */
        LoginManager.shared.storeUser(username: "test", password: "test", response: loginObject, rememberMe: true)
        
        /* test */
        XCTAssertNotNil(LoginManager.shared.getUsername())
        XCTAssert(LoginManager.shared.getUsername() == "test")
        XCTAssertNotNil(LoginManager.shared.getPassword())
        XCTAssert(LoginManager.shared.getPassword() == "test")
        XCTAssertNotNil(LoginManager.shared.getAuthToken())
        XCTAssert(LoginManager.shared.getAuthToken() == "test_token")
        XCTAssertNotNil(LoginManager.shared.getAuthTokenExpiry())
        XCTAssert(LoginManager.shared.getAuthTokenExpiry()?.compare(expireDate) == .orderedSame)
        XCTAssertNotNil(LoginManager.shared.getCompanyName())
        XCTAssert(LoginManager.shared.getCompanyName() == "Test Company")
    }
    
    func testStoreUserRememberMe() {
        /* store data*/
        LoginManager.shared.storeUser(username: "test", password: "test_password", response: nil, rememberMe: false)
        
        /* test */
        XCTAssertNotNil(LoginManager.shared.getUsername())
        XCTAssert(LoginManager.shared.getUsername() == "test")
        XCTAssertNil(LoginManager.shared.getPassword())
        XCTAssertNil(LoginManager.shared.getAuthToken())
        XCTAssertNil(LoginManager.shared.getAuthTokenExpiry())
        XCTAssertNil(LoginManager.shared.getCompanyName())
    }
    
    func testClear() {
        /* setup data */
        let loginObject = LoginObject()
        let expireDate = Date()
        loginObject.expire = expireDate
        loginObject.token = "test_token"
        let user = User()
        let company = Company()
        company.name = "Test Company"
        user.company = company
        loginObject.user = user
        
        /* store data */
        LoginManager.shared.storeUser(username: "test", password: "test_password", response: loginObject, rememberMe: true)
        LoginManager.shared.clear()
        
        /* test */
        XCTAssertNil(LoginManager.shared.getUsername())
        XCTAssertNil(LoginManager.shared.getPassword())
        XCTAssertNil(LoginManager.shared.getAuthToken())
        XCTAssertNil(LoginManager.shared.getAuthTokenExpiry())
        XCTAssertNil(LoginManager.shared.getCompanyName())
    }
}
