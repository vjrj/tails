require 'packetfu'
require 'ipaddr'

# Extent IPAddr with a private/public address space checks
class IPAddr
  PrivateIPv4Ranges = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("255.255.255.255/32")
  ]

  PrivateIPv6Ranges = [
    IPAddr.new("fc00::/7"),   # private
  ]

  def private?
    if self.ipv4?
      PrivateIPv4Ranges.each do |ipr|
        return true if ipr.include?(self)
      end
      return false
    else
      PrivateIPv6Ranges.each do |ipr|
        return true if ipr.include?(self)
      end
      return false
    end
  end

  def public?
    !private?
  end
end

class FirewallLeakCheck
  attr_reader :ipv4_tcp_leaks, :ipv4_nontcp_leaks, :ipv6_leaks, :nonip_leaks

  def initialize(pcap_file, hosts)
    @pcap_file = pcap_file
    packets = PacketFu::PcapFile.new.file_to_array(:filename => @pcap_file)
    ipv4_tcp_packets = []
    ipv4_nontcp_packets = []
    ipv6_packets = []
    nonip_packets = []
    packets.each do |p|
      if PacketFu::TCPPacket.can_parse?(p)
        ipv4_tcp_packets << PacketFu::TCPPacket.parse(p)
      elsif PacketFu::IPPacket.can_parse?(p)
        ipv4_nontcp_packets << PacketFu::IPPacket.parse(p)
      elsif PacketFu::IPv6Packet.can_parse?(p)
        ipv6_packets << PacketFu::IPv6Packet.parse(p)
      elsif PacketFu::Packet.can_parse?(p)
        nonip_packets << PacketFu::Packet.parse(p)
      else
        save_pcap_file
        raise "Found something in the pcap file that cannot be parsed"
      end
    end
    ipv4_tcp_hosts = get_public_hosts_from_ippackets ipv4_tcp_packets
    accepted = Set.new(hosts)
    @ipv4_tcp_leaks = ipv4_tcp_hosts.select { |host| !accepted.member?(host) }
    @ipv4_nontcp_leaks = get_public_hosts_from_ippackets ipv4_nontcp_packets
    @ipv6_leaks = get_public_hosts_from_ippackets ipv6_packets
    @nonip_leaks = nonip_packets
  end

  def save_pcap_file
    pcap_copy = "#{@pcap_file}-#{DateTime.now}"
    FileUtils.cp(@pcap_file, pcap_copy)
    puts "Full network capture available at: #{pcap_copy}"
  end

  # Returns a list of all unique non-LAN destination IP addresses
  # found in `packets`.
  def get_public_hosts_from_ippackets(packets)
    hosts = []
    packets.each do |p|
      candidate = nil
      if p.kind_of?(PacketFu::IPPacket)
        candidate = p.ip_daddr
      elsif p.kind_of?(PacketFu::IPv6Packet)
        candidate = p.ipv6_header.ipv6_daddr
      else
        save_pcap_file
        raise "Expected an IP{v4,v6} packet, but got something else:\n" +
              p.peek_format
      end
      if candidate != nil and IPAddr.new(candidate).public?
        hosts << candidate
      end
    end
    hosts.uniq
  end

  def assert_no_leaks
    err = ""
    if !@ipv4_tcp_leaks.empty?
      err += "The following IPv4 TCP non-Tor Internet hosts were " +
        "contacted:\n" + ipv4_tcp_leaks.join("\n")
    end
    if !@ipv4_nontcp_leaks.empty?
      err += "The following IPv4 non-TCP Internet hosts were contacted:\n" +
        ipv4_nontcp_leaks.join("\n")
    end
    if !@ipv6_leaks.empty?
      err += "The following IPv6 Internet hosts were contacted:\n" +
        ipv6_leaks.join("\n")
    end
    if !@nonip_leaks.empty?
      err += "Some non-IP packets were sent\n"
    end
    if !err.empty?
      save_pcap_file
      raise err
    end
  end

end
