defApplication('app:iperf', 'iperf') do |a|

  a.path = "@bindir@/iperf"
  a.version(2, 0, 5)
  a.shortDescription = 'Iperf traffic generator and bandwidth measurement tool'
  a.description = %{
Iperf is a traffic generator and bandwidth measurement tool. It provides
generators producing various forms of packet streams and port for sending these
packets via various transports, such as TCP and UDP.
  }

  a.defProperty('interval', 'pause n seconds between periodic bandwidth reports',
		'-i', {:type => :string, :dynamic => false})
  a.defProperty('len', 'set length read/write buffer to n (default 8 KB)',
		'-l', {:type => :string, :dynamic => false})
  a.defProperty('print_mss', 'print TCP maximum segment size (MTU - TCP/IP header)',
		'-m', {:type => :boolean, :dynamic => false})
  a.defProperty('output', 'output the report or error message to this specified file',
		'-o', {:type => :string, :dynamic => false})
  a.defProperty('port', 'set server port to listen on/connect to to n (default 5001)',
		'-p', {:type => :integer, :dynamic => false})
  a.defProperty('udp', 'use UDP rather than TCP',
		'-u', {:order => 2, :type => :boolean, :dynamic => false})
  a.defProperty('window', 'TCP window size (socket buffer size)',
		'-w', {:type => :integer, :dynamic => false})
  a.defProperty('bind', 'bind to <host>, an interface or multicast address',
		'-B', {:type => :string, :dynamic => false})
  a.defProperty('compatibility', 'for use with older versions does not sent extra msgs',
		'-C', {:type => :boolean, :dynamic => false})
  a.defProperty('mss', 'set TCP maximum segment size (MTU - 40 bytes)',
		'-M', {:type => :integer, :dynamic => false})
  a.defProperty('nodelay', 'set TCP no delay, disabling Nagle\'s Algorithm',
		'-N', {:type => :boolean, :dynamic => false})
  a.defProperty('IPv6Version', 'set the domain to IPv6',
		'-V', {:type => :boolean, :dynamic => false})
  a.defProperty('reportexclude', '[CDMSV]   exclude C(connection) D(data) M(multicast) S(settings) V(server) reports',
		'-x', {:type => :string, :dynamic => false})
  a.defProperty('reportstyle', 'C or c for CSV report, O or o for OML',
		'-y', {:type => :string, :dynamic => false})

  a.defProperty('server', 'run in server mode',
		'-s', {:type => :boolean, :dynamic => false})

  a.defProperty('bandwidth', 'set target bandwidth to n bits/sec (default 1 Mbit/sec)',
		'-b', {:type => :string, :dynamic => false})
  a.defProperty('client', 'run in client mode, connecting to <host>',
		'-c', {:order => 1, :type => :string, :dynamic => false})
  a.defProperty('dualtest', 'do a bidirectional test simultaneously',
		'-d', {:type => :boolean, :dynamic => false})
  a.defProperty('num', 'number of bytes to transmit (instead of -t)', 
		'-n', {:type => :integer, :dynamic => false})
  a.defProperty('tradeoff', 'do a bidirectional test individually',
		'-r', {:type => :boolean, :dynamic => false})
  a.defProperty('time', 'time in seconds to transmit for (default 10 secs)',
		'-t', {:type => :integer, :dynamic => false})
  a.defProperty('fileinput', 'input the data to be transmitted from a file',
		'-F', {:type => :string, :dynamic => false})
  a.defProperty('stdin', 'input the data to be transmitted from stdin',
		'-I', {:type => :boolean, :dynamic => false})
  a.defProperty('listenport', 'port to recieve bidirectional tests back on',
		'-L', {:type => :integer, :dynamic => false})
  a.defProperty('parallel', 'number of parallel client threads to run',
		'-P', {:type => :integer, :dynamic => false})
  a.defProperty('ttl', 'time-to-live, for multicast (default 1)',
		'-T', {:type => :integer, :dynamic => false})
  a.defProperty('linux-congestion', 'set TCP congestion control algorithm (Linux only)',
		'-Z', {:type => :boolean, :dynamic => false})

  a.defMeasurement("application"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('version', :string, 'Iperf version')
    m.defMetric('cmdline', :string, 'Iperf invocation command line')
    m.defMetric('starttime_s', :uint32, 'Time the application was received (s)')
    m.defMetric('starttime_us', :uint32, 'Time the application was received (us)')
  }

  a.defMeasurement("settings"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('server_mode', :uint32, '1 if in server mode, 0 otherwise')
    m.defMetric('bind_address', :string, 'Address to bind')
    m.defMetric('multicast', :uint32, '1 if listening to a Multicast group')
    m.defMetric('multicast_ttl', :uint32, 'Multicast TTL if relevant')
    m.defMetric('transport_protocol', :uint32, 'Transport protocol (IANA number)')
    m.defMetric('window_size', :uint32, 'TCP window size')
    m.defMetric('buffer_size', :uint32, 'UDP buffer size')
  }

  a.defMeasurement("connection"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('connection_id', :uint32, 'Connection identifier (socket)')
    m.defMetric('local_address', :string, 'Local network address')
    m.defMetric('local_port', :uint32, 'Local port')
    m.defMetric('foreign_address', :string, 'Remote network address')
    m.defMetric('foreign_port', :uint32, 'Remote port')
  }

  a.defMeasurement("transfer"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('connection_id', :uint32, 'Connection identifier (socket)')
    m.defMetric('begin_interval', :double, 'Start of the averaging interval (Iperf timestamp)')
    m.defMetric('end_interval', :double, 'End of the averaging interval (Iperf timestamp)')
    m.defMetric('size', :uint32, 'Amount of transmitted data [Bytes]')
  }

  a.defMeasurement("losses"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('connection_id', :uint32, 'Connection identifier (socket)')
    m.defMetric('begin_interval', :double, 'Start of the averaging interval (Iperf timestamp)')
    m.defMetric('end_interval', :double, 'End of the averaging interval (Iperf timestamp)')
    m.defMetric('total_datagrams', :uint32, 'Total number of datagrams')
    m.defMetric('lost_datagrams', :uint32, 'Number of lost datagrams')
  }

  a.defMeasurement("jitter"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('connection_id', :uint32, 'Connection identifier (socket)')
    m.defMetric('begin_interval', :double, 'Start of the averaging interval (Iperf timestamp)')
    m.defMetric('end_interval', :double, 'End of the averaging interval (Iperf timestamp)')
    m.defMetric('jitter', :double, 'Average jitter [ms]')
  }

  a.defMeasurement("packets"){ |m|
    m.defMetric('pid', :uint32, 'Main process identifier')
    m.defMetric('connection_id', :uint32, 'Connection identifier (socket)')
    m.defMetric('packet_id', :uint32, 'Packet sequence number for datagram-oriented protocols')
    m.defMetric('packet_size', :uint32, 'Packet size')
    m.defMetric('packet_time_s', :uint32, 'Time the packet was processed (s)')
    m.defMetric('packet_time_us', :uint32, 'Time the packet was processed (us)')
    m.defMetric('packet_sent_time_s', :uint32, 'Time the packet was sent (s) for datagram-oriented protocols')
    m.defMetric('packet_sent_time_us', :uint32, 'Time the packet was sent (us) for datagram-oriented protocols')
  }

end

# Local Variables:
# mode:ruby
# vim: ft=ruby:sw=2
# End:
