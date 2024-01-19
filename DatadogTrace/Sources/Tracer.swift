/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation
import DatadogInternal
import OpenTelemetryApi

/// Datadog - specific span tags to be used with `Tracer.shared().startSpan(operationName:references:tags:startTime:)`
/// and `span.setTag(key:value:)`.
public enum SpanTags {
    /// A Datadog-specific span tag, which sets the value appearing in the "RESOURCE" column
    /// in traces explorer on [app.datadoghq.com](https://app.datadoghq.com/)
    /// Can be used to customize the resource names grouped under the same operation name.
    ///
    /// Expects `String` value set for a tag.
    public static let resource = "resource.name"
    /// Internal tag. `Integer` value. Measures elapsed time at app's foreground state in nanoseconds.
    /// (duration - foregroundDuration) gives you the elapsed time while the app wasn't active (probably at background)
    internal static let foregroundDuration = "foreground_duration"
    /// Internal tag. `Bool` value.
    /// `true` if span was started or ended while the app was not active, `false` otherwise.
    internal static let isBackground = "is_background"

    /// Those keys used to encode information received from the user through `OpenTracingLogFields`, `OpenTracingTagKeys` or custom fields.
    /// Supported by Datadog platform.
    internal static let errorType    = "error.type"
    internal static let errorMessage = "error.msg"
    internal static let errorStack   = "error.stack"
}

/// A class for manual interaction with the Trace feature. It records spans that are sent to Datadog APM.
///
/// There can be only one active Tracer for certain instance of Datadog SDK. It gets enabled along with
/// the call to `Trace.enable(with:in:)`:
///
///     import DatadogTrace
///
///     // Enable Trace feature:
///     Trace.enable(with: configuration)
///
///     // Use Tracer:
///     Tracer.shared().startSpan(...)
///
public class Tracer {
    /// Obtains the Tracer for manual tracing instrumentation.
    ///
    /// It requires `Trace.enable(with:in:)` to be called first - otherwise it will return no-op implementation.
    /// - Parameter core: the instance of Datadog SDK the Trace feature was enabled in (global instance by default)
    /// - Returns: the Tracer that conforms to Open Tracing API (`OTTracer`)
    public static func shared(in core: DatadogCoreProtocol = CoreRegistry.default) -> OTTracer {
        do {
            guard !(core is NOPDatadogCore) else {
                throw ProgrammerError(
                    description: "Datadog SDK must be initialized and RUM feature must be enabled before calling `Tracer.shared(in:)`."
                )
            }
            guard let feature = core.get(feature: TraceFeature.self) else {
                throw ProgrammerError(
                    description: "Trace feature must be enabled before calling `Tracer.shared(in:)`."
                )
            }

            return feature.tracer
        } catch {
            consolePrint("\(error)")
            return DDNoopTracer()
        }
    }
}
