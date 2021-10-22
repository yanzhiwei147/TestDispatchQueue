//
//  TestDispatchQueueTests.m
//  TestDispatchQueueTests
//
//  Created by arida on 2021/10/22.
//  Copyright © 2021 arida. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KwaiDispatchQueue+Private.h"
#import <libkern/OSAtomic.h>

@interface TestDispatchQueueTests : XCTestCase

@end

@implementation TestDispatchQueueTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDefaultInit {
    KwaiDispatchQueue *queue = [[KwaiDispatchQueue alloc] init];
    XCTAssertNotNil(queue);
    XCTAssertNotNil(queue.queue);
    XCTAssertEqual(queue.concurrentCount, KwaiDefaultQueueConcurrentLimit);
    XCTAssertNotNil(queue.managerQueue);
    XCTAssertNotNil(queue.semaphore);
}

- (void)testCustomInit {
    // queue 是 main gqueu
    XCTAssertNil([[KwaiDispatchQueue alloc] initWithQueue:dispatch_get_main_queue()]);
    
    // queue 为 nil
    XCTAssertNotNil([[KwaiDispatchQueue alloc] initWithQueue:nil]);
    
    // 自定义 queue
    dispatch_queue_t innerQueue = dispatch_queue_create("com.arida.queue.1", DISPATCH_QUEUE_CONCURRENT);
    KwaiDispatchQueue *queue = [[KwaiDispatchQueue alloc] initWithQueue:innerQueue];
    XCTAssertNotNil(queue);
    XCTAssertTrue(queue.queue == innerQueue);
    XCTAssertEqual(queue.concurrentCount, KwaiDefaultQueueConcurrentLimit);
    XCTAssertNotNil(queue.managerQueue);
    XCTAssertNotNil(queue.semaphore);
    
    dispatch_queue_t innerQueue2 = dispatch_queue_create("com.arida.queue.2", DISPATCH_QUEUE_CONCURRENT);
    KwaiDispatchQueue *queue2 = [[KwaiDispatchQueue alloc] initWithQueue:innerQueue2];
    XCTAssertTrue(queue2.queue == innerQueue2);
    
    // 并发数为 0/1
    KwaiDispatchQueue *tmp0 = [[KwaiDispatchQueue alloc] initWithQueue:innerQueue concurrentCount:0];
    KwaiDispatchQueue *tmp1 = [[KwaiDispatchQueue alloc] initWithQueue:innerQueue concurrentCount:1];
    XCTAssertEqual(tmp0.concurrentCount, KwaiDefaultQueueConcurrentLimit);
    XCTAssertEqual(tmp1.concurrentCount, KwaiDefaultQueueConcurrentLimit);
    
    // 并发数超过 10
    KwaiDispatchQueue *tmp11 = [[KwaiDispatchQueue alloc] initWithQueue:innerQueue concurrentCount:11];
    XCTAssertEqual(tmp11.concurrentCount, 11);
}

- (void)testSync {
    KwaiDispatchQueue *queue = [[KwaiDispatchQueue alloc] init];
    for (int i = 0; i < 50; i++) {
        [queue sync:^{
            NSLog(@"🎬 ====> 同步任务(%d)执行开始；当前线程信息：%@", i, [NSThread currentThread].name);
            sleep(1);
            NSLog(@"🏁 ====> 同步任务(%d)执行结束；当前线程信息：%@", i, [NSThread currentThread].name);
        }];
    }
}

- (void)testAsync {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async test"];

    __block volatile int32_t resultCount = 0;
    NSUInteger count = 32;
    KwaiDispatchQueue *queue = [[KwaiDispatchQueue alloc] init];
    for (int i = 0; i < count; i++) {
        [queue async:^{
            NSLog(@"🎬 ====> 异步任务(%d)执行开始；当前线程信息：%@", i, [NSThread currentThread]);
            sleep(1);
            NSLog(@"🏁 ====> 异步任务(%d)执行结束；当前线程信息：%@", i, [NSThread currentThread]);
            OSAtomicIncrement32(&resultCount);
            if (resultCount == count) {
                [expectation fulfill];
            }
        }];
    }
    
    [self waitForExpectationsWithTimeout:999 handler:nil];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
