# LTMSwift

[中文文档](README.zh-CN.md)

## Installation

```ruby
pod 'LTMSwift'
```

Use subspecs if you only need part of the library:

```ruby
pod 'LTMSwift/Extension'
pod 'LTMSwift/Extension/UIExtension'
pod 'LTMSwift/Extension/BaseExtension'
pod 'LTMSwift/Network'
```

## Network Module (Detailed)

The Network module is organized by responsibilities:

```text
Network/
  Config/
    LTMNetworkConfig.swift
    LTMNetworkResponseConfig.swift
    LTMNetworkCallbackConfig.swift
    LTMNetworkObserverConfig.swift
    LTMNetworkTokenRefresh.swift
    LTMNetworkDuplicateRequest.swift
    LTMNetworkLogConfig.swift
  Core/
    LTMNetworkDeal.swift
    LTMNetworkProtocol.swift
    LTMNetworkEvent.swift
  Plugin/
    LTMLogPlugin.swift
  Runtime/
    LTMDuplicateRequestGuard.swift
    LTMTokenRefreshCoordinator.swift
```

### 1) One-time global setup

```swift
import LTMSwift
import Moya

final class NetworkManager: LTMNetworkDeal {
    static let shared = NetworkManager()

    private lazy var logPlugin = makeLogPlugin()
    private lazy var userProvider = MoyaProvider<UserApi>(plugins: [logPlugin])

    private override init() {
        super.init()

        applyConfig { config in
            // Response parsing
            config.response.codeKey = "code"
            config.response.codeSuccess = "200"
            config.response.dataKey = "data"
            config.response.successStatusCodes = Set(200...299)

            // Callback dispatch
            config.callback.onMainThread = true

            // Observability
            config.observer.eventHandler = { event in
                print("network event:", event)
            }

            // Auto token refresh + retry
            config.tokenRefresh.isEnabled = true
            config.tokenRefresh.maxRetryCount = 1
            config.tokenRefresh.timeout = 8
            config.tokenRefresh.pathFilter = { method, path in
                !(method == "POST" && path.contains("/order/submit"))
            }
            config.tokenRefresh.expiredMatcher = { raw in
                guard let dict = raw as? [String: Any] else { return false }
                return (dict["code"] as? String) == "403"
            }
            config.tokenRefresh.refreshAction = { done in
                done(true)
            }
            config.tokenRefresh.onRefreshFailed = { raw in
                print("refresh failed:", raw ?? "nil")
            }

            // Duplicate request protection
            config.duplicateRequest.isEnabled = true
            config.duplicateRequest.minimumInterval = 0.5
            config.duplicateRequest.recordTTL = 120
            config.duplicateRequest.maxRecordCount = 2000
            config.duplicateRequest.keyProvider = { method, path, defaultKey in
                "\(method)|\(path)|\(defaultKey)"
            }
            config.duplicateRequest.failureBuilder = { method, path in
                [
                    "error": "duplicate-request",
                    "method": method,
                    "path": path,
                    "message": "Request is too frequent"
                ]
            }

            // Logging
            config.log.isEnabled = true
            config.log.logHeaders = true
            config.log.logBody = false
            config.log.maxBodyLogLength = 4000
            config.log.redactedKeys.formUnion(["set-cookie", "authorization"])
            config.log.logger = { message in
                print(message)
            }
        }
    }
}
```

### 2) Request usage

```swift
extension NetworkManager {
    func profile(
        model: ProfileModel,
        success: ((ProfileModel?) -> Void)?,
        failure: ((Any?) -> Void)?
    ) {
        request(
            provider: userProvider,
            target: .profile,
            model: model,
            successBlock: success,
            failureBlock: failure
        )
    }
}

NetworkManager.shared.profile(model: ProfileModel()) { profile in
    print("success:", profile as Any)
} failure: { error in
    print("failed:", error as Any)
}
```

### 3) Observability events

`config.observer.eventHandler` receives:

- `autoRetrySkipped(reason:method:path:retryCount:)`
- `tokenRefreshStarted(method:path:retryCount:)`
- `tokenRefreshFinished(success:method:path:)`
- `requestRetried(method:path:retryCount:)`
- `duplicateRequestBlocked(reason:method:path:)`

### 4) Unified error mapping

```swift
final class AppNetworkManager: LTMNetworkDeal {
    override func failureHandle(data: Any) -> Any? {
        return data
    }
}
```

### 5) Duplicate-request memory behavior

- `inFlight` only keeps active request keys and clears them when request finishes.
- Completed records are capped by `recordTTL` and `maxRecordCount`.
- Defaults (`recordTTL = 120`, `maxRecordCount = 2000`) prevent unbounded growth.

### 6) Migration mapping (old -> new)

| Old key | New key |
| --- | --- |
| `config.successStatusCodes` | `config.response.successStatusCodes` |
| `config.codeKey` | `config.response.codeKey` |
| `config.codeSuccess` | `config.response.codeSuccess` |
| `config.dataKey` | `config.response.dataKey` |
| `config.callbackOnMainThread` | `config.callback.onMainThread` |
| `config.networkEventHandler` | `config.observer.eventHandler` |
| `config.enableAutoTokenRefresh` | `config.tokenRefresh.isEnabled` |
| `config.maxAutoRetryCount` | `config.tokenRefresh.maxRetryCount` |
| `config.tokenRefreshTimeout` | `config.tokenRefresh.timeout` |
| `config.autoRetryPathFilter` | `config.tokenRefresh.pathFilter` |
| `config.tokenExpiredMatcher` | `config.tokenRefresh.expiredMatcher` |
| `config.tokenRefreshAction` | `config.tokenRefresh.refreshAction` |
| `config.onTokenRefreshFailed` | `config.tokenRefresh.onRefreshFailed` |
