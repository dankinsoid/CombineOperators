import Foundation
import Combine

extension Publisher {
	
    /**
     Trait that represents observable sequence with following properties:

     - it delivers events on `MainScheduler.instance`
     - `share(replay: 1)` sharing strategy
     
     Additional explanation:
     - all observers share sequence computation resources
     - it's stateful, upon subscription (calling subscribe) last element is immediately replayed if it was produced
     - computation of elements is reference counted with respect to the number of observers
     - if there are no subscribers, it will release sequence computation resources
     */
	public func asDriver() -> some Publisher<Output, Failure> {
        share(replay: 1).receive(on: MainScheduler.instance)
	}
}
