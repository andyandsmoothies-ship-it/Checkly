namespace Checkly.Api.Common.Auth;

/// <summary>
/// Configuration options for <see cref="PbacCacheListenerService"/>.
/// Bind from appsettings under the "Pbac" section.
/// </summary>
public class PbacListenerOptions
{
    /// <summary>
    /// The window (in milliseconds) the debounce Consumer waits after receiving the first
    /// signal before executing a cache reload. During this window, all subsequent signals
    /// are collapsed into one. Default: 1000ms.
    /// Set to a low value (e.g. 50ms) in integration test configuration to avoid slow tests.
    /// </summary>
    public int DebounceWindowMs { get; set; } = 1000;
}
