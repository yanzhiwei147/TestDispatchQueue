//
//  KwaiDispatchQueue+Private.h
//  TestDispatchQueue
//
//  Created by arida on 2021/10/22.
//  Copyright © 2021 arida. All rights reserved.
//

#import "KwaiDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

// 默认队列并发数量
FOUNDATION_EXTERN const NSUInteger KwaiDefaultQueueConcurrentLimit;
// 最大队列并发数量警告阈值
FOUNDATION_EXTERN const NSUInteger KwaiMaxQueueConcurrentLimit;

#ifdef DEBUG
#define KLog(...)  NSLog(__VA_ARGS__)
#else
#define Klog(...)
#endif

@interface KwaiDispatchQueue ()
/// 内部创建/外部传入的并发队列
@property (nonatomic, strong) dispatch_queue_t queue;

/// 一个数值，指示队列并发数量
@property (nonatomic, assign, readwrite) NSUInteger concurrentCount;

/// 信号量，用来控制并发量（偷懒，用了信号量的数值加减机制，不过能达到目的）
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
/// 管理队列，用该队列与信号量配合完成。即，利用信号的机制来控制 target block 进入时机；
@property (nonatomic, strong) dispatch_queue_t managerQueue;
@end

NS_ASSUME_NONNULL_END
