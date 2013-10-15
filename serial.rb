require 'serialport'
require 'pp'

ports = Dir.glob('/dev/ttyACM*')
sp = SerialPort.new(ports.first, 115200)
pp sp.modem_params
angle = 3900
force = 0

starting_x = 555
starting_y = 659
min_force = 400
last_force = 0
mouse_move = false

system "xdotool mousemove --sync #{starting_x} #{starting_y}" if mouse_move
#Thread.new do
  #while true
    #sleep 0.1
    #sp.print('a')
  #end
#end

sleep 4
sp.print('a')
data = ""
last_try = Time.now.to_i - 4

begin
  while true
    data << (sp.getc || "")
    if data[-1] == "\n"
      File.open('store.txt', 'a+') do |out|
        out.puts "#{Time.now.to_i}|#{data}"
      end
      #puts "#{Time.now.to_i}|#{data}"
      if Time.now.to_i > last_try + 4
        a, force = data.split('|').map {|v| v.to_i }
        angle = a if a > 3900 and a < 6100

        if last_force - force > 200
          force = 0
          # Let go of mouse
          system "xdotool mouseup 1 mousemove --sync #{starting_x} #{starting_y}" if mouse_move
          last_try = Time.now.to_i
        end

        if force > min_force
          if last_force < min_force
            # Push mouse button down
            system "xdotool mousedown 1"
          end
        end

        unless force < min_force
          #puts "#{force}|#{angle}"
          a = Math::PI/2 * (1.0 - ((angle - 3900.0) / 1100.0))
          f = force / 5
          dx = Math.cos(a) * f
          dy = Math.sin(a) * f
          system "xdotool mousemove --sync #{starting_x - dx.to_i} #{starting_y - dy.to_i}" if mouse_move
        end

        last_force = force if force
      end
      data = ""
      #sleep 0.1
      sp.print('a')
    end
  end
rescue Exception => e
  puts e.message
  puts e.backtrace
end

sp.close
