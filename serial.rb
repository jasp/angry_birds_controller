require 'serialport'
require 'pp'

ports = Dir.glob('/dev/ttyACM*')
sp = SerialPort.new(ports.first, 115200)
pp sp.modem_params
angle = 3900
force = 0
logfile = 'store.txt'

$starting_x = 555
$starting_y = 659
min_force = 700
last_force = 500
$mouse_move = true

File.open(logfile, 'w') do |out|
  out.puts "timestamp|accelerometer|force"
end
system "xdotool mousemove --sync #{$starting_x} #{$starting_y}" if $mouse_move
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
angle_history = []
state = :startup

def control_mouse(angle, force)
  a = Math::PI/2 * (1.0 - ((angle - 3900.0) / 1100.0))
  f = force / 5
  dx = Math.cos(a) * f
  dy = Math.sin(a) * f
  system "xdotool mousemove --sync #{$starting_x - dx.to_i} #{$starting_y - dy.to_i}" if $mouse_move
end

begin
  while true
    data << (sp.getc || "")
    if data[-1] == "\n"
      File.open(logfile, 'a+') do |out|
        out.puts "#{Time.now.to_i}|#{data}"
      end
      #puts "#{Time.now.to_i}|#{data}"
      if Time.now.to_i > last_try + 4
        a, force = data.split('|').map {|v| v.to_i }
        angle = a if a > 3900 and a < 6100

        if last_force - force > 2000 or (angle_history.any? and (angle_history[-1] - angle).abs > 300)
          control_mouse(angle_history[3], force)
          force = 0
          # Let go of mouse
          system "xdotool mouseup 1 mousemove --sync #{$starting_x} #{$starting_y}" if $mouse_move
          last_try = Time.now.to_i
          state = :startup
        end

        if state == :startup and force > min_force
          if last_force < min_force
            # Push mouse button down
            system "xdotool mousemove --sync #{$starting_x} #{$starting_y} mousedown 1" if $mouse_move
            state = :holding_bird
          end
        end

        if state == :holding_bird
          #puts "#{force}|#{angle}"
          control_mouse(angle, force)
        end

        last_force = force if force
        angle_history.push angle
        angle_history.shift while angle_history.length > 5
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
