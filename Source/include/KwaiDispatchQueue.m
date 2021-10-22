//
//  KwaiDispatchQueue.m
//  TestDispatchQueue
//
//  Created by arida on 2021/10/22.
//  Copyright © 2021 arida. All rights reserved.
//

#import "KwaiDispatchQueue+Private.h"

@implementation KwaiDispatchQueue
- (instancetype)init {
    KLog(@"请使用 -[KwaiDispatchQueue initWithQueue:] 方法");
    return [self initWithQueue:dispatch_queue_create("com.kwai.queue.reserve", DISPATCH_QUEUE_CONCURRENT)];
}

#pragma mark - public
- (nullable instancetype)initWithQueue:(dispatch_queue_t)queue {
    return [self initWithQueue:queue concurrentCount:KwaiDefaultQueueConcurrentLimit];
}

- (nullable instancetype)initWithQueue:(dispatch_queue_t)queue
                       concurrentCount:(NSUInteger)concurrentCount {
    // 检查是否并发队列，如果是串行队列，则 queue 没有太大必要
    BOOL isSerialQueue = NO;
    if (isSerialQueue) {
        // 这里没有检查过，原则上通过 libdispatch 源码可以找到检查方案
        // https://opensource.apple.com/tarballs/libdispatch/
        KLog(@"队列是串行队列，无需进行并发管理");
        return nil;
    } else if (queue == dispatch_get_main_queue()) {
        KLog(@"队列是 main queue，请使用自定义队列");
        return nil;
    }
    
    // todo: 内部需要维护一份 queue 的弱引用，防止业务创建多个 KwaiDispatchQueue 来绕过
    // 命中后，直接返回 nil
    BOOL queueUsed = NO;
    if (queueUsed) {
        return nil;
    }
    
    // 检查 queue 合法性
    if (!queue) {
        queue = [[self class] newReserveQueue];
    }
    
    // 检查并发数量合法性
    if (concurrentCount <= 1 ) {
        // todo：待优化；原则上，这里内部可以分为两个子模块，串行时直接退化为原 GCD 操作即可，不用额外走内部信号量逻辑
        concurrentCount = KwaiDefaultQueueConcurrentLimit;
    } else if (concurrentCount > KwaiMaxQueueConcurrentLimit) {
        // 这里 KwaiMaxQueueConcurrentLimit 只是 magin number，只是用来质疑并发为什么要这么高，不改变原有行为
        // 当然同时从底层支持上来说，还可以写入日志，通过开发者工具提供作为后面决策的数据记录
        KLog(@"并发数量 %lu 似乎设置的过高，建议调小并发量", (unsigned long)concurrentCount);
    }
    
    self = [super init];
    if (self) {
        _queue = queue;
        _concurrentCount = concurrentCount;
        
        // 并发要求，因此资源暂不做懒加载
        _semaphore = dispatch_semaphore_create(_concurrentCount);
        NSString *label = [[NSString alloc] initWithFormat:@"com.kwai.queue.%p", self];
        _managerQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)sync:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    dispatch_sync(_managerQueue, ^{
        __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        dispatch_semaphore_wait(strongSelf.semaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_sync(strongSelf.queue, ^{
            !block ?: block();
            dispatch_semaphore_signal(strongSelf.semaphore);
        });
    });
}

- (void)async:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    
    dispatch_async(_managerQueue, ^{
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(self.queue, ^{
            !block ?: block();
            dispatch_semaphore_signal(self.semaphore);
        });
    });
}
#pragma mark - private
+ (dispatch_queue_t)newReserveQueue {
    return dispatch_queue_create("com.kwai.queue.reserve", DISPATCH_QUEUE_CONCURRENT);
}
@end
