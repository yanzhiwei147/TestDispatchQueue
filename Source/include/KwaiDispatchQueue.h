//
//  KwaiDispatchQueue.h
//  TestDispatchQueue
//
//  Created by arida on 2021/10/22.
//  Copyright © 2021 arida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 封装并发队列管理机制
@interface KwaiDispatchQueue : NSObject

// todo：这里整个使用上还不完善；还需要做一些 convenience 改造。比如外部还需要自己创建 queue，创建的 queue 可能还有错误（如我们需要并发队列，而外部创建了串行队列等），可以提供默认全局并发的队列，而不是一个业务都自行创建一个；多团队各自创建，也失去了这个库的目的；

/// 一个数值，指示队列并发数量
@property (nonatomic, assign, readonly) NSUInteger concurrentCount;

// 创建一个新的队列
// @info 等价于 ``[instance initWithQueue:dispatch_queue_create("com.kwai.queue.reserve", DISPATCH_QUEUE_CONCURRENT)]``
- (instancetype)init;

/// 使用指定的队列初始化一个新的队列
/// @param queue 任务执行的并发队列
/// @info 等价于 ``[instance initWithQueue:queue              concurrentCount:4]``
- (nullable instancetype)initWithQueue:(dispatch_queue_t)queue;

/// 使用指定的队列与对应并发数量初始化一个新的队列
/// @param queue 任务指定的并发队列
/// @param concurrentCount 队列并发数量，必须 > 1
- (nullable instancetype)initWithQueue:(dispatch_queue_t)queue
                       concurrentCount:(NSUInteger)concurrentCount NS_DESIGNATED_INITIALIZER;

/// 同步执行一个任务
/// @param block 同步任务块
- (void)sync:(dispatch_block_t)block;

/// 异步执行一个任务
/// @param block 异步任务块
- (void)async:(dispatch_block_t)block;
@end

NS_ASSUME_NONNULL_END
