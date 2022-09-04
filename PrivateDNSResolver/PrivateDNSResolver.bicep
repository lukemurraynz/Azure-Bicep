 param dnsResolvers_PrivateDNSResolver_name string = 'PrivateDNSResolver'
  param virtualNetworks_vnettest_externalid string = '/subscriptions/57627713-eff2-44fa-a546-a2c8fde3c6e3/resourceGroups/pointtositetest/providers/Microsoft.Network/virtualNetworks/vnettest'

  resource dnsResolvers_PrivateDNSResolver_name_resource 'Microsoft.Network/dnsResolvers@2020-04-01-preview' = {
  name: dnsResolvers_PrivateDNSResolver_name
  location: 'australiaeast'
  properties: {
  virtualNetwork: {
    id: virtualNetworks_vnettest_externalid
  }
}
  }
          resource dnsResolvers_PrivateDNSResolver_name_InboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview' = {
parent: dnsResolvers_PrivateDNSResolver_name_resource
name: 'InboundEndpoint'
location: 'australiaeast'
    }
  ]
}
  }
