/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import DatadogInternal

/// A type providing core context and writer for writing span events.
internal protocol SpanWriteContext {
    /// Requests core context and writer for writing span events.
    /// - Parameter block: The block to execute; it is called on the core's context queue.
    func spanWriteContext(_ block: @escaping (DatadogContext, Writer) -> Void)
}

/// A `SpanWriteContext` that captures core context at the moment of initialization and provides it
/// later when the actual span event is constructed.
///
/// It ensures that spans are constructed with the context valid at the moment of span creation (_start span_)
/// instead of completion (_finish span_). This enables the proper linking of attributes from other products, like
/// associating started span with the current RUM information.
internal final class LazySpanWriteContext: SpanWriteContext {
    private weak var core: DatadogCoreProtocol?

    /// The core context valid at the moment of creating `LazySpanWriteContext`.
    /// It doesn't require synchronization as it is accessed only from the core context queue.
    private var context: DatadogContext?

    init(core: DatadogCoreProtocol) {
        self.core = core

        // Capture the core context valid at the moment of initialization:
        core.scope(for: TraceFeature.name)?.context { [weak self] context in
            self?.context = context
        }
    }

    func spanWriteContext(_ block: @escaping (DatadogContext, Writer) -> Void) {
        guard let scope = core?.scope(for: TraceFeature.name) else {
            return
        }

        // Ignore the current context and use the one captured at initialization:
        scope.eventWriteContext(bypassConsent: false, forceNewBatch: false) { _, writer in
            guard let context = self.context else {
                return // unexpected
            }
            block(context, writer)
        }
    }
}
