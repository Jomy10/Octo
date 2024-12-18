//
//  RWLock.swift
//
//  MIT License
//
//  Copyright (c) 2023 Jonas Everaert
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Jonas Everaert on 29/05/2023.
//

import Foundation

/// A read-write lock
///
/// RWLocks ensures that multiple threads can read a value at the same time,
/// but only one thread can write to a value.
public final class RWLock<T> {
    private var lock: pthread_rwlock_t
    private var value: T

    /// Errors thrown from `RWLock` correspond to their C-equivalents.
    /// The error codes can be checked using the error codes present in Foundation (e.g. `EDEADLK`)
    struct Error: Swift.Error {
        let code: Int32
        var message: String {
            switch self.code {
            // init
            case EAGAIN:
                return "The system lacked the necessary resources (other than memory) to initialize another read-write lock, or the read lock could not be acquired because the maximum number of read locks for rwlock has been exceeded." // init / rdlock
            case ENOMEM:
                return "Insufficient memory exists to initialize the read-write lock."
            case EPERM:
                return "The caller does not have the privilege to perform the operation."
            // write / read
            case EBUSY:
                return "The read-write lock could not be acquired for writing because it was already locked for reading or writing."
            case EDEADLK:
                return "A deadlock condition was detected or the current thread already owns the read-write lock for writing or reading."
            default:
                return "Error with code \(self.code)"
            }
        }

        /// Returned by `tryWrite` and `tryRead` when the lock could not be acquired
        var lockCouldNotBeAcquired: Self { Error(code: EBUSY) }
    }

    /// Initialize a new `RWLock` holding the specified value.
    ///
    /// - Throws:
    ///     - If the system lacks the necessary resources (other than memeroy) to initialize another `RWLock`: `EAGAIN`
    ///     - If insufficient memory exists to initialize the `RWLock`: `ENOMEM`
    ///     - The caller does not have the privilage to perform the operation: `EPERM`
    public init(_ value: T) throws {
        self.value = value
        self.lock = pthread_rwlock_t()
        let errCode = pthread_rwlock_init(&self.lock, nil)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
    }

    /// Applies a read lock to the `RWLock` and releases it when the function finishes executing
    ///
    /// The calling thread acquires the read lock if a writer does not hold the lock and there are no writers blocked on the lock.
    /// A thread may hold multiple concurrent read locks on `RWLock`.
    ///
    ///  - Throws:
    ///     - If the maximum number number of read locks for `RWLock` has been exceeded (implementation-specific): `EAGAIN`
    ///     - If a deadlock condition was detected or the current thread already owns the `RWLock` for writing: `EDEADLK`
    public func read<ReturnType>(_ reader: (T) throws -> (ReturnType)) throws -> ReturnType {
        var errCode = pthread_rwlock_rdlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
        let retVal: ReturnType
        do {
            retVal = try reader(self.value)
        } catch {
            pthread_rwlock_unlock(&self.lock)
            throw error
        }
        errCode = pthread_rwlock_unlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }

        return retVal
    }

    /// Apply a read lock for the current thread, but throw an error if the equivalent `RWLock.read` call
    /// would have blocked the calling thread (i.e. there is already a write lock present for the read-write lock).
    ///
    /// This function will never block; it either acquires the lock or fails and returns immediately.
    ///
    /// - Throws:
    ///     - If the read-write lock could not be acquired for reading because a writer holds the
    ///     lock or a writer with the appropriate priority was blocked on it: `EBUSY`
    ///     - The read lock could not be acquired because the maximum number of read locks
    ///     for the `RWLock` has been exceeded (implementation-specific: `EAGAIN`
    public func tryRead<ReturnType>(_ reader: (T) throws -> (ReturnType)) throws -> ReturnType {
        var errCode = pthread_rwlock_tryrdlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
        let retVal: ReturnType
        do {
            retVal = try reader(self.value)
        } catch {
            pthread_rwlock_unlock(&self.lock)
            throw error
        }
        errCode = pthread_rwlock_unlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
        return retVal
    }

    /// Applies a write lock to the `RWLock` and releases it when the function finishes executing.
    ///
    /// The calling thread will acquire the write lock if no thread (reader or writer) holds the `RWLock`.
    /// Otherwise, if another thread holds the `RWLock`, the calling thread will block until it can acquire the lock.
    /// If a deadlock condition occurs, or the caling thread already owns the `RWLock` for writing or reading,
    /// the call will either deadlock or return error code `EDEADLK`
    ///
    /// - Throws:
    ///     - If a deadlock condition was detected or the current thread already owns the `RWLock` for writing or reading: `EDEADLK`
    public func write(_ writer: (inout T) throws -> ()) throws {
        var errCode = pthread_rwlock_wrlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
        do {
            try writer(&self.value)
        } catch {
            pthread_rwlock_unlock(&self.lock)
            throw error
        }
        errCode = pthread_rwlock_unlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
    }

    /// The current thread will try to get a read lock, but will fail if any thread currently holds a lock for reading or writing
    ///
    /// - Throws:
    ///     - If the read-write lock could not be acquired for writing because it was already locked for reading or writing: `EBUSY`
    public func tryWrite(_ writer: (inout T) throws -> ()) throws {
        var errCode = pthread_rwlock_trywrlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
        do {
            try writer(&self.value)
        } catch {
            pthread_rwlock_unlock(&self.lock)
            throw error
        }
        errCode = pthread_rwlock_unlock(&self.lock)
        if errCode != 0 {
            throw Self.Error(code: errCode)
        }
    }

    deinit {
        pthread_rwlock_destroy(&self.lock)
    }
}
