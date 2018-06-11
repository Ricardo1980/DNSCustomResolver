//
//  ViewController.swift
//  DNSCustomReponder
//
//  Created by Ricardo on 07/06/2018.
//  Copyright © 2018 Ricardo. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    let manager = NETunnelProviderManager.shared()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange(notification:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        
        self.statusLabel.text = self.manager.connection.status.description
        
        self.manager.loadFromPreferences { error in
            
            if let error = error {
                print("Error loading configuration: \(error.localizedDescription)")
            }
            
            let providerProtocol = NETunnelProviderProtocol()
            providerProtocol.providerBundleIdentifier = "com.ricardoruizlopez.tunnel.app.extension"
            // the server address does not matter
            //providerProtocol.serverAddress = "192.168.1.1"
            providerProtocol.serverAddress = "8.8.8.8"
            self.manager.protocolConfiguration = providerProtocol

            // apply this rule to all domains
            let evaluationRule = NEEvaluateConnectionRule(matchDomains: ["*.com"], andAction: NEEvaluateConnectionRuleAction.connectIfNeeded)
            //let evaluationRule = NEEvaluateConnectionRule(matchDomains: [], andAction: NEEvaluateConnectionRuleAction.connectIfNeeded)
            evaluationRule.useDNSServers = ["192.168.1.1"]
            let onDemandRule = NEOnDemandRuleEvaluateConnection()
            onDemandRule.connectionRules = [evaluationRule]
            onDemandRule.interfaceTypeMatch = NEOnDemandRuleInterfaceType.any
            self.manager.onDemandRules = [onDemandRule]

            self.manager.localizedDescription = "DNS Resolver"
            self.manager.isEnabled = true
            self.manager.isOnDemandEnabled = true

            self.manager.saveToPreferences { error in
                if let error = error {
                    print("Error saving the configuration: \(error.localizedDescription)")
                } else {
                    print("Success saving the configuration")
                }
            }
        }
    }
    
    @objc func statusDidChange(notification: NSNotification) {
        self.statusLabel.text = self.manager.connection.status.description
    }

    @IBAction func onConnectButtonPressed(_ sender: Any) {
        print("trying to connect")
        do {
            switch manager.connection.status {
            case .disconnected:
                print("connecting")
                try (manager.connection as! NETunnelProviderSession).startTunnel()
            default:
                print("we have to be in disconnected state to connect")
                break
            }
        } catch let error {
            print("Error connecting: \(error.localizedDescription)")
        }
    }
    
    @IBAction func onDisconnectButtonPressed(_ sender: Any) {
        print("trying to disconnect")
        switch self.manager.connection.status {
        case .connected, .connecting:
            print("disconnecting")
            (manager.connection as! NETunnelProviderSession).stopTunnel()
        default:
            print("we have to be in connected or connecting state to disconnect")
            break
        }
    }

}

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid:
            return "Invalid"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reasserting:
            return "Reasserting"
        case .disconnecting:
            return "Disconnecting"
        }
    }
}
