//
//  PacketTunnelProvider.swift
//  DNSCustomReponderExtension
//
//  Created by Ricardo on 07/06/2018.
//  Copyright © 2018 Ricardo. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        NSLog("------- starting tunnel")
        // Add code here to start the process of connecting the tunnel.
        
        // the remote address does not matter
        let tunnelNetworkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        
        // create a TUN interface using a private address and take only traffic that goes to that private address, in our case, DNS requests
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.1"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route(destinationAddress: "192.168.1.1", subnetMask: "255.255.255.0")]
        tunnelNetworkSettings.ipv4Settings = ipv4Settings
        
        self.setTunnelNetworkSettings(tunnelNetworkSettings) { error in
            completionHandler(error)
        }

        // A NEPacketTunnelFlow object which is used to receive IP packets routed to the tunnel’s virtual interface and inject IP packets into the networking stack via the tunnel’s virtual interface.
        // We only receive DNS requests. Intercept them and parse them
        // http://www.firewall.cx/networking-topics/protocols/domain-name-system-dns/160-protocols-dns-query.html
        // Parse it using this code to extract the domain
        // https://github.com/zhuhaow/NEKit/blob/master/src/IPStack/DNS/DNSMessage.swift
        
        self.tunToUDP()
    }
    
    func tunToUDP() {
        self.packetFlow.readPackets { (packets: [Data], protocols: [NSNumber]) in
            for packet in packets {
                // This is where encrypt() should reside
                // A comprehensive encryption is not easy and not the point for this demo
                // I just omit it
                
                NSLog("-----packet received. Size %d", packet.count)
            
//                self.session?.writeDatagram(packet, completionHandler: { (error: Error?) in
//                    if let error = error {
//                        print(error)
//                        self.setupUDPSession()
//                        return
//                    }
//                })
            }
            // Recursive to keep reading
            self.tunToUDP()
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        NSLog("------- stopping tunnel")
        completionHandler()
    }
    
    // Used by the app to send data to the extension. Not used in our scenerio
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        
        // reply with some statistics or an error or nothing
        if let completionHandler = completionHandler {
            completionHandler(nil)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}
