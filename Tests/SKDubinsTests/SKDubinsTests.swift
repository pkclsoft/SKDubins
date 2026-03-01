import XCTest
import CoreGraphics
import CGExtKit

@testable import SKDubins

final class SKDubinsTests: XCTestCase {
    
    static var turning_radius: CGFloat = 0.0
    static var q0: Configuration = Configuration()
    static var q1: Configuration = Configuration()
    
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest
        
        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    
    override func setUpWithError() throws {
        SKDubinsTests.turning_radius = 1.0
        configure_inputs(a: 0.0, b: 0.0, d: 1.0)
    }
    
    func configure_inputs(a: CGFloat, b: CGFloat, d: CGFloat) {
        SKDubinsTests.q0 = Configuration(withPos: CGPointZero, andTheta: a)
        SKDubinsTests.q1 = Configuration(withPos: CGPoint(x: d, y: 0.0), andTheta: b)
    }
    
    func testShortestPath() throws {
        // find the shortest path
        let path: DubinsPath = DubinsPath()
        
        let result: DubinsResult = Dubins.shortest(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius)
        
        XCTAssertEqual(result, .EDUBOK)
    }
    
    func testInvalidTurningRadius() throws {
        let negativeTurnRadius: CGFloat = -1.0
        let path: DubinsPath = DubinsPath()

        // find the shortest path
        let result: DubinsResult = Dubins.shortest(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: negativeTurnRadius)
        
        XCTAssertEqual(result, .EDUBBADRHO)
    }
    
    func testNoPath() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 10.0)
        let path: DubinsPath = DubinsPath()
        
        // find the shortest path
        let result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LRL)
        
        XCTAssertEqual(result, .EDUBNOPATH)
    }
    
    func testPathLength() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the shortest path
        let path: DubinsPath = DubinsPath()
        let result: DubinsResult = Dubins.shortest(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius)

        XCTAssertEqual(result, .EDUBOK)

        let res = path.length()
        XCTAssertEqual(res, 4.0)
    }
    
    func testSimplePath() throws {
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        let result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
    }
    
    func testSegmentLengths() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        let result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        XCTAssertEqual(path.length(ofSegment: -1), CGFloat.infinity)
        XCTAssertEqual(path.length(ofSegment: 0), 0.0)
        XCTAssertEqual(path.length(ofSegment: 1), 4.0)
        XCTAssertEqual(path.length(ofSegment: 2), 0.0)
        XCTAssertEqual(path.length(ofSegment: 3), CGFloat.infinity)
        
    }
    
    func testSegmentLengthNormalized() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        let result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)

        
        XCTAssertEqual(result, .EDUBOK)
        
        XCTAssertEqual(path.normalizedSegmentLength(ofSegment: -1), CGFloat.infinity)
        XCTAssertEqual(path.normalizedSegmentLength(ofSegment: 0), 0.0)
        XCTAssertEqual(path.normalizedSegmentLength(ofSegment: 1), 4.0)
        XCTAssertEqual(path.normalizedSegmentLength(ofSegment: 2), 0.0)
        XCTAssertEqual(path.normalizedSegmentLength(ofSegment: 3), CGFloat.infinity)
    }
    
    
    func testSample() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        let qsamp: Configuration = Configuration()
        result = Dubins.sample(path: path, t: 0.0, q: qsamp)
        
        XCTAssertEqual(result, .EDUBOK)
        
        XCTAssertTrue(qsamp == SKDubinsTests.q0)
        
        result = Dubins.sample(path: path, t: 4.0, q: qsamp)
        
        XCTAssertEqual(result, .EDUBOK)
        
        XCTAssertTrue(qsamp == SKDubinsTests.q1)
    }
    
    func testSampleOutOfBounds() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        let qsamp: Configuration = Configuration()
        
        result = Dubins.sample(path: path, t: -1.0, q: qsamp)
        XCTAssertEqual(result, .EDUBPARAM)
        result = Dubins.sample(path: path, t: 5.0, q: qsamp)
        XCTAssertEqual(result, .EDUBPARAM)
    }

    func nop_callback(q: Configuration, t: CGFloat, data: inout Int?) -> DubinsResult {
        return .EDUBOK
    }
    
    func testSampleManyLSL() throws {
        configure_inputs(a: CGFloat.pi/2,b: -CGFloat.pi/2, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        var noData: Int? = nil
        
        result = Dubins.sampleEntirePath(path: path, stepSize: 1.0, cb: nop_callback, user_data: &noData)
        
        XCTAssertEqual(result, .EDUBOK)
    }
    
    func testSampleManyRSR() throws {
        configure_inputs(a: CGFloat.pi/2,b: -CGFloat.pi/2, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .RLR)
        
        XCTAssertEqual(result, .EDUBOK)
        
        var noData: Int? = nil

        result = Dubins.sampleEntirePath(path: path, stepSize: 1.0, cb: nop_callback, user_data: &noData)
        
        XCTAssertEqual(result, .EDUBOK)
    }
    
    func out_out_early_callback(q: Configuration, t: CGFloat, data: inout Int?) -> DubinsResult {
        
        if data != nil {
            if data! > 2 {
                return .EDUBABORT
            }
            
            data! += 1
            
            return .EDUBOK
        } else {
            return .EDUBOK
        }
    }
    
    func testSampleManyOptOutEarly() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        var count: Int? = 0
        
        result = Dubins.sampleEntirePath(path: path, stepSize: 1.0, cb: out_out_early_callback, user_data: &count)
        
        XCTAssertEqual(result, .EDUBABORT)
        XCTAssertEqual(count, 3)
    }
    
    func testPathType() throws {
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        
        DubinsPathType.allCases.forEach { pathType in
            let result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: pathType)
            
            if result == .EDUBOK {
                XCTAssertEqual(pathType, path.type)
            }
        }
    }
    
    func testEndPoint() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        let qsamp: Configuration = Configuration()
        
        result = Dubins.endPoint(path: path, q: qsamp)
        XCTAssertEqual(result, .EDUBOK)
        
        XCTAssertTrue(qsamp == SKDubinsTests.q1)
    }
    
    func testExtractSubpath() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        let subpath: DubinsPath = DubinsPath()
        result = Dubins.subPath(path: path, t: 2.0, newPath: subpath)
        
        XCTAssertEqual(result, .EDUBOK)
        
        let qsamp: Configuration = Configuration()
        
        result = Dubins.endPoint(path: subpath, q: qsamp)
        XCTAssertEqual(result, .EDUBOK)
        
        XCTAssertTrue(qsamp == Configuration(withPos: CGPoint(x: 2.0, y: 0.0), andTheta: 0.0))
    }
    
    func testExtractInvalidSubpath() throws {
        configure_inputs(a: 0.0, b: 0.0, d: 4.0)
        
        // find the parameters for a single Dubin's word
        let path: DubinsPath = DubinsPath()
        var result: DubinsResult = Dubins.path(path: path, q0: SKDubinsTests.q0, q1: SKDubinsTests.q1, rho: SKDubinsTests.turning_radius, pathType: .LSL)
        
        XCTAssertEqual(result, .EDUBOK)
        
        let subpath: DubinsPath = DubinsPath()
        result = Dubins.subPath(path: path, t: 8.0, newPath: subpath)
        
        XCTAssertNotEqual(result, .EDUBOK)
    }
}
