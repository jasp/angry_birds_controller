require 'serialport'
require 'pp'

ports = Dir.glob('/dev/ttyACM*')
SerialPort.open(ports.first, 9600) do |sp|
  begin
    while true
      data = sp.getc
      print("%02x " % data.bytes[0]) if data
    end
  rescue => e
    pp e
  end
end
