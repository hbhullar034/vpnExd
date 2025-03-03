import NetworkExtension
import OpenVPNAdapter
import os.log // Import os.log for structured logging

extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}

class PacketTunnelProvider: NEPacketTunnelProvider {

    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()

    let vpnReachability = OpenVPNReachability()
    var providerManager: NETunnelProviderManager!

    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    var groupIdentifier: String?

    static var connectionIndex = 0
    static var timeOutEnabled = true

    func loadProviderManager(completion: @escaping (_ error: Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if error == nil {
                self.providerManager = managers?.first ?? NETunnelProviderManager()
                completion(nil)
            } else {
                os_log(.error, "Error loading provider manager: %@", String(describing: error))
                completion(error)
            }
        }
    }

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log(.info, "Starting VPN Tunnel...") // Log VPN start attempt

        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
        else {
            let error = NSError(domain: "VPNExtensionErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Protocol configuration is invalid."])
            os_log(.error, "Error starting tunnel: Invalid protocol configuration")
            completionHandler(error)
            return
        }

        guard let ovpnFileContent: Data = providerConfiguration["config"] as? Data else {
            let error = NSError(domain: "VPNExtensionErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid OpenVPN configuration data."])
            os_log(.error, "Error starting tunnel: Missing OVPN config")
            completionHandler(error)
            return
        }

        guard let groupIdentifierData: Data = providerConfiguration["groupIdentifier"] as? Data else {
            let error = NSError(domain: "VPNExtensionErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid group identifier data."])
            os_log(.error, "Error starting tunnel: Missing Group Identifier")
            completionHandler(error)
            return
        }

        guard let decodedGroupId = String(data: groupIdentifierData, encoding: .utf8) else {
            let error = NSError(domain: "VPNExtensionErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode group identifier."])
            os_log(.error, "Error starting tunnel: Group Identifier decoding failed")
            completionHandler(error)
            return
        }
        self.groupIdentifier = decodedGroupId
        os_log(.info, "Group Identifier: %@", self.groupIdentifier ?? "Unknown")

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent
        configuration.tunPersist = false

        // Apply OpenVPN configuration.
        let properties: OpenVPNConfigurationEvaluation
        do {
            properties = try vpnAdapter.apply(configuration: configuration)
            os_log(.info, "OpenVPN Configuration Applied Successfully")
        } catch {
            os_log(.error, "Error applying OpenVPN configuration: %@", String(describing: error))
            completionHandler(error)
            return
        }

        if !properties.autologin {
            guard let username = options?["username"] as? String, let password = options?["password"] as? String else {
                let error = NSError(domain: "VPNExtensionErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing username or password for VPN authentication."])
                os_log(.error, "Error starting tunnel: Missing VPN credentials")
                completionHandler(error)
                return
            }
            let credentials = OpenVPNCredentials()
            credentials.username = username
            credentials.password = password
            do {
                try vpnAdapter.provide(credentials: credentials)
                os_log(.info, "VPN Credentials Provided Successfully")
            } catch {
                os_log(.error, "Error providing VPN credentials: %@", String(describing: error))
                completionHandler(error)
                return
            }
        }

        vpnReachability.startTracking { [weak self] status in
            guard status == .reachableViaWiFi else {
                os_log(.info, "VPN Reachability: Network is not reachable via WiFi")
                return
            }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
            os_log(.info, "VPN Reachability: Network reachable via WiFi, attempting reconnect")
        }
        startHandler = completionHandler
        vpnAdapter.connect(using: packetFlow)
        os_log(.info, "VPN Connect command sent to adapter")
    }

    @objc func stopVPN() {
        loadProviderManager { (err: Error?) in
            if err == nil {
                self.providerManager.connection.stopVPNTunnel()
                os_log(.info, "VPN Tunnel stopped via stopVPNTunnel()")
            } else {
                os_log(.error, "Error loading provider manager during stopVPN: %@", String(describing: err))
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log(.info, "Stopping VPN Tunnel with reason: %d", reason.rawValue)
        stopHandler = completionHandler
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
            os_log(.info, "VPN Reachability tracking stopped")
        }
        vpnAdapter.disconnect()
        os_log(.info, "VPN Adapter disconnect command sent")
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        if String(data: messageData, encoding: .utf8) == "OPENVPN_STATS" {
            var toSave = ""
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            toSave += UserDefaults.init(suiteName: groupIdentifier)?.string(forKey: "connected_on") ?? ""
            toSave += "_"
            toSave += String(vpnAdapter.interfaceStatistics.packetsIn)
            toSave += "_"
            toSave += String(vpnAdapter.interfaceStatistics.packetsOut)
            toSave += "_"
            toSave += String(vpnAdapter.interfaceStatistics.bytesIn)
            toSave += "_"
            toSave += String(vpnAdapter.interfaceStatistics.bytesOut)
            UserDefaults.init(suiteName: groupIdentifier)?.setValue(toSave, forKey: "connectionUpdate")
            os_log(.debug, "Updated VPN stats in UserDefaults: %@", toSave)
        }
    }
}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (Error?) -> Void) {
        networkSettings?.dnsSettings?.matchDomains = [""]
        setTunnelNetworkSettings(networkSettings, completionHandler: completionHandler)
        os_log(.info, "Tunnel Network Settings configured")
    }

    func _updateEvent(_ event: OpenVPNAdapterEvent, openVPNAdapter: OpenVPNAdapter) {
        var toSave = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        switch event {
        case .connected:
            toSave = "CONNECTED"
            UserDefaults.init(suiteName: groupIdentifier)?.setValue(formatter.string(from: Date.now), forKey: "connected_on")
        case .disconnected:
            toSave = "DISCONNECTED"
        case .connecting:
            toSave = "CONNECTING"
        case .reconnecting:
            toSave = "RECONNECTING"
        case .info:
            toSave = "INFO"
        default:
            UserDefaults.init(suiteName: groupIdentifier)?.removeObject(forKey: "connected_on")
            toSave = "INVALID"
        }
        UserDefaults.init(suiteName: groupIdentifier)?.setValue(toSave, forKey: "vpnStage")
        os_log(.debug, "VPN Stage updated in UserDefaults: Event: %@, Stage: %@", String(describing: event), toSave)
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        PacketTunnelProvider.timeOutEnabled = true
        _updateEvent(event, openVPNAdapter: openVPNAdapter)
        os_log(.info, "OpenVPN Event: %@, Message: %@", String(describing: event), message ?? "No Message")
        switch event {
        case .connected:
            PacketTunnelProvider.timeOutEnabled = false
            if reasserting {
                reasserting = false
            }
            guard let startHandler = startHandler else { return }
            startHandler(nil)
            self.startHandler = nil
            os_log(.info, "VPN Connected Event handled, startHandler called")
        case .disconnected:
            PacketTunnelProvider.timeOutEnabled = false
            guard let stopHandler = stopHandler else { return }
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            stopHandler()
            self.stopHandler = nil
            os_log(.info, "VPN Disconnected Event handled, stopHandler called")
        case .reconnecting:
            reasserting = true
            os_log(.info, "VPN Reconnecting Event")
        default:
            break
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        os_log(.error, "OpenVPN Adapter Error: %@", String(describing: error))
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
            os_log(.info, "VPN Reachability tracking stopped due to error")
        }
        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
            os_log(.error, "Fatal error handled via startHandler")
        } else {
            cancelTunnelWithError(error)
            os_log(.error, "Fatal error handled via cancelTunnelWithError")
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        os_log(.default, "OpenVPN Log: %@", logMessage) // Implement logging of OpenVPN messages
    }
}