//  Created by Kenichi Ueno on 2017/03/04.

import Foundation

// StateDataExtractable: You might want a simple data model object conform to this
protocol StateDataExtractable {}

// StateInput: Just a phantom protocol
protocol StateInput {}

// StackState: Common part of State. It does not have associatedtype
protocol StateStackable{
    var previousState: StateStackable? { get }
    
    func extractData() -> StateDataExtractable
    func nextState(_ input: StateInput) -> StateStackable?
}

// State: Represents a state which should only accept its associated InputType
protocol State: StateStackable {
    associatedtype InputType: StateInput
    associatedtype DataType: StateDataExtractable
    var data: DataType { get }
    
    func handle(_ input: InputType) -> StateStackable
}

extension State {
    func nextState(_ input: StateInput) -> StateStackable? {
        if let input = input as? InputType {
            return self.handle(input)
        } else if let previousState = self.previousState {
            return previousState.nextState(input)
        }
        return nil
    }
    
    func extractData() -> StateDataExtractable {
        return self.data
    }
}
