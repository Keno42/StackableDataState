//
//  StackableStateTest.swift
//  StackableDataState
//
//  Created by Kenichi Ueno on 2017/03/05.
//
//

import XCTest

// Use it as a convenience singleton
class StateManager {
    static var currentState: StateStackable = InitialState.init()
    
    static var session: RegistrationSession? {
        return currentState.extractData() as? RegistrationSession
    }
    
    static func resetState() {
        currentState = InitialState.init()
    }
    
    static func moveToNextState(_ input: StateInput) {
        if let nextState = currentState.nextState(input) {
            currentState = nextState
            currentState.enterState()
        }
    }
}

struct RegistrationSession: StateDataExtractable {
    let email: String?
    let name: String?
    let isLogin: Bool?
    
    static func empty() -> RegistrationSession {
        return RegistrationSession.init(email: nil, name: nil, isLogin: nil)
    }
    
    func update(email: String? = nil, name: String? = nil, isLogin: Bool? = nil) -> RegistrationSession {
        return RegistrationSession.init(email: email ?? self.email,
                                        name: name ?? self.name,
                                        isLogin: isLogin ?? self.isLogin)
    }
}

extension StateStackable {
    func enterState() {
        print("entered \(self)")
    }
}

struct InitialState: State {
    typealias DataType = RegistrationSession
    let previousState: StateStackable? = nil
    let data: RegistrationSession = RegistrationSession.empty()
    
    enum Input: StateInput {
        case signUp
        case login
    }
    func handle(_ input: Input) -> StateStackable {
        switch input {
        case .signUp:
            return SignUpState(previousState: self, data: data)
        case .login:
            return FinishState(previousState: self, data: data.update(isLogin: true))
        }
    }
}


struct SignUpState: State {
    let previousState: StateStackable?
    let data: RegistrationSession
    
    enum Input: StateInput {
        case signUp(email: String, name: String)
        case signUpFailed
    }
    func handle(_ input: Input) -> StateStackable {
        switch input {
        case .signUp(let email, let name):
            return FinishState(previousState: self, data: data.update(email: email, name: name, isLogin: true))
        case .signUpFailed:
            return ErrorState(previousState: self, data: data.update(isLogin: false))
        }
    }
}

struct FinishState: State {
    let previousState: StateStackable?
    let data: RegistrationSession
    
    enum Input: StateInput {}
    func handle(_ input: Input) -> StateStackable {
        return ErrorState(previousState: self, data: data)
    }
}

struct ErrorState: State {
    let previousState: StateStackable?
    let data: RegistrationSession
    
    enum Input: StateInput {}
    func handle(_ input: Input) -> StateStackable {
        return ErrorState(previousState: self, data: data)
    }
}

class StackableStateTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        StateManager.resetState()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLogin() {
        StateManager.moveToNextState(InitialState.Input.login) // Initial -> Login
        XCTAssert(StateManager.session?.email == nil)
        XCTAssert(StateManager.session?.name == nil)
        XCTAssert(StateManager.session?.isLogin == true)
    }
    
    func testSignUp() {
        StateManager.moveToNextState(InitialState.Input.signUp) // Initial -> SignUp
        StateManager.moveToNextState(SignUpState.Input.signUp(email: "test@example.com", name: "Haniko"))
        XCTAssert(StateManager.session?.email == "test@example.com")
        XCTAssert(StateManager.session?.name == "Haniko")
        XCTAssert(StateManager.session?.isLogin == true)
    }

    func testSignUpFailure() {
        StateManager.moveToNextState(InitialState.Input.signUp) // Initial -> SignUp
        StateManager.moveToNextState(SignUpState.Input.signUpFailed)
        XCTAssert(StateManager.session?.email == nil)
        XCTAssert(StateManager.session?.name == nil)
        XCTAssert(StateManager.session?.isLogin == false)
    }
    
    func testCancelSignUpThenLogin() {
        StateManager.moveToNextState(InitialState.Input.signUp) // Initial -> SignUp
        StateManager.moveToNextState(InitialState.Input.login) // Initial -> Login
        XCTAssert(StateManager.session?.email == nil)
        XCTAssert(StateManager.session?.name == nil)
        XCTAssert(StateManager.session?.isLogin == true)
    }
}
