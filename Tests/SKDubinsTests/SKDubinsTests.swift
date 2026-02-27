import XCTest
import CoreGraphics
import CGExtKit

@testable import SKDubins

final class SKDubinsTests: XCTestCase {
    
    static var turning_radius: CGFloat = 0.0
    static var wheel_base: CGFloat = WHEELBASE
    static var q0: AgentState = AgentState()
    static var q1: AgentState = AgentState()
    
    //    init() {
    //        Setup()
    //    }
    //
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
        SKDubinsTests.q0 = AgentState()
        SKDubinsTests.q0.pos = CGPointZero
        SKDubinsTests.q0.theta = a
        
        SKDubinsTests.q1.pos = CGPoint(x: d, y: 0.0)
        SKDubinsTests.q1.theta = b
    }
    
    func testShortestPath() throws {
        // find the shortest path
        var path: DubinsTrajectory = Dubins.DubinsShortestPath(minTurnRadius: &SKDubinsTests.turning_radius, wheelbase: &SKDubinsTests.wheel_base, start: &SKDubinsTests.q0, goal: &SKDubinsTests.q1)
        
        XCTAssertFalse(path.controls.isEmpty)
        //    ASSERT_EQ(err, EDUBOK)
    }
    
    func testInvalidTurningRadius() throws {
        var negativeTurnRadius: CGFloat = -1.0
        
        // find the shortest path
        var path: DubinsTrajectory = Dubins.DubinsShortestPath(minTurnRadius: &negativeTurnRadius, wheelbase: &SKDubinsTests.wheel_base, start: &SKDubinsTests.q0, goal: &SKDubinsTests.q1)
        
        XCTAssertTrue(path.controls.isEmpty)
        //    ASSERT_EQ(err, EDUBBADRHO)
    }
    
    //    func noPath() throws {
    //        configure_inputs(a: 0.0, b: 0.0, d: 10.0)
    //
    //        // find the shortest path
    //        var path: DubinsTrajectory = Dubins.DubinsShortestPath(minTurnRadius: &SKDubinsTests.turning_radius, wheelbase: &SKDubinsTests.wheel_base, start: &SKDubinsTests.q0, goal: &SKDubinsTests.q1)
    //
    //        int err = dubins_path(&path, q0, q1, turning_radius, LRL);
    //
    //        XCTAssertTrue(path.controls.isEmpty)
    //
    //        ASSERT_EQ(err, EDUBNOPATH);
    //    }
    
    //    func pathLength() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the shortest path
    //        DubinsPath path;
    //        dubins_shortest_path(&path, q0, q1, turning_radius);
    //        double res = dubins_path_length(&path);
    //        ASSERT_DOUBLE_EQ(res, 4.0);
    //    }
    //
    //    func simplePath() throws
    //    {
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //    }
    //
    //    func segmentLengths() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length(&path, -1), INFINITY);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length(&path, 0), 0.0);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length(&path, 1), 4.0);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length(&path, 2), 0.0);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length(&path, 3), INFINITY);
    //
    //    }
    //
    //    func SegmentLengthNormalized() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length_normalized(&path, -1), INFINITY);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length_normalized(&path, 0), 0.0);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length_normalized(&path, 1), 4.0);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length_normalized(&path, 2), 0.0);
    //        ASSERT_DOUBLE_EQ(dubins_segment_length_normalized(&path, 3), INFINITY);
    //
    //    }
    //
    //
    //    func sample() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //
    //        double qsamp[3];
    //        err = dubins_path_sample(&path, 0.0, qsamp);
    //        ASSERT_EQ(err, EDUBOK);
    //        ASSERT_DOUBLE_EQ(qsamp[0], q0[0]);
    //        ASSERT_DOUBLE_EQ(qsamp[1], q0[1]);
    //        ASSERT_DOUBLE_EQ(qsamp[2], q0[2]);
    //
    //        err = dubins_path_sample(&path, 4.0, qsamp);
    //        ASSERT_EQ(err, EDUBOK);
    //        ASSERT_DOUBLE_EQ(qsamp[0], q1[0]);
    //        ASSERT_DOUBLE_EQ(qsamp[1], q1[1]);
    //        ASSERT_DOUBLE_EQ(qsamp[2], q1[2]);
    //    }
    //
    //    func sampleOutOfBounds() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //
    //        double qsamp[3];
    //        err = dubins_path_sample(&path, -1.0, qsamp);
    //        ASSERT_EQ(err, EDUBPARAM);
    //        err = dubins_path_sample(&path, 5.0, qsamp);
    //        ASSERT_EQ(err, EDUBPARAM);
    //    }
    //
    //    int nop_callback(double q[3], double t, void* data)
    //    {
    //        return 0;
    //    }
    //
    //    func sampleManyLSL() throws
    //    {
    //        configure_inputs(M_PI/2,-M_PI/2, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //        err = dubins_path_sample_many(&path, 1.0, &nop_callback, NULL);
    //    }
    //
    //    func sampleManyRSR() throws
    //    {
    //        configure_inputs(M_PI/2,-M_PI/2, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, RLR);
    //        ASSERT_EQ(err, EDUBOK);
    //        err = dubins_path_sample_many(&path, 1.0, &nop_callback, NULL);
    //    }
    //
    //    int out_out_early_callback(double q[3], double t, void* data)
    //    {
    //        int& value = *((int*)data);
    //        if( value > 2 ) {
    //            return 1;
    //        }
    //        value += 1;
    //        return 0;
    //    }
    //
    //    func sampleManyOptOutEarly() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //
    //        int count = 0;
    //        err = dubins_path_sample_many(&path, 1.0, &out_out_early_callback, (void*)(&count));
    //        ASSERT_EQ(err, 1);
    //        ASSERT_EQ(count, 3);
    //    }
    //
    //    func pathType() throws
    //    {
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //
    //        for(int i = 0; i < 6; i++) {
    //            DubinsPathType t = (DubinsPathType)i;
    //            int err = dubins_path(&path, q0, q1, turning_radius, t);
    //            if( err == EDUBOK ) {
    //                ASSERT_EQ(t, dubins_path_type(&path));
    //            }
    //        }
    //    }
    //
    //    func endPoint() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //
    //        double qsamp[3];
    //        err = dubins_path_endpoint(&path, qsamp);
    //        ASSERT_EQ(err, EDUBOK);
    //        ASSERT_NEAR(qsamp[0], q1[0], 1e-8);
    //        ASSERT_NEAR(qsamp[1], q1[1], 1e-8);
    //        ASSERT_NEAR(qsamp[2], q1[2], 1e-8);
    //    }
    //
    //    func extractSubpath() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //
    //        DubinsPath subpath;
    //        err = dubins_extract_subpath(&path, 2.0, &subpath);
    //        ASSERT_EQ(err, 0);
    //
    //        double qsamp[3];
    //        err = dubins_path_endpoint(&subpath, qsamp);
    //        ASSERT_EQ(err, EDUBOK);
    //        ASSERT_NEAR(qsamp[0], 2.0, 1e-8);
    //        ASSERT_NEAR(qsamp[1], 0.0, 1e-8);
    //        ASSERT_NEAR(qsamp[2], 0.0, 1e-8);
    //    }
    //
    //    func extractInvalidSubpath() throws
    //    {
    //        configure_inputs(0.0, 0.0, 4.0);
    //
    //        // find the parameters for a single Dubin's word
    //        DubinsPath path;
    //        int err = dubins_path(&path, q0, q1, turning_radius, LSL);
    //        ASSERT_EQ(err, EDUBOK);
    //
    //        DubinsPath subpath;
    //        err = dubins_extract_subpath(&path, 8.0, &subpath);
    //        ASSERT_NE(err, 0);
    //    }
}
