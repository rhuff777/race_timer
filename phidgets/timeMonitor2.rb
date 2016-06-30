require 'rubygems'
require 'phidgets-ffi'
require "net/http"
require 'io/console'
require 'logger'

logger = Logger.new("log.log")
logger.info("Program Started")

@timeStamps = []
@last_ts_count = 0

args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
if args.key?('h')
  STDERR.puts "Usage: ruby #{$0} --race_id=222 --bib=true"
  exit(1) 
end
@race_id = nil
@bib = true
@upload = false
if args.key?('race_id')
	@race_id = args['race_id']
end
if args.key?('bib')
	@bib = args['bib']
end
if args.key?('upload')
	@upload = args['upload']
end

puts "race_id: #{@race_id}"
puts "bib: #{@bib}"

puts "Library Version: #{Phidgets::FFI.library_version}"

gps = Phidgets::GPS.new

puts "Wait for PhidgetGPS to attached..."

#The following method runs when the PhidgetGPS is attached to the system
gps.on_attach  do |device, obj|
  puts "Device attributes: #{device.attributes} attached"
  puts "Class: #{device.device_class}"
	puts "Id: #{device.id}"
	puts "Serial number: #{device.serial_number}"
	puts "Version: #{device.version}"

	puts "Waiting for position fix status to be acquired"
end

gps.on_detach  do |device, obj|
	puts "#{device.attributes.inspect} detached"
end

gps.on_error do |device, obj, code, description|
	puts "Error #{code}: #{description}"
end

gps.on_position_fix_status_change do |device, fix_status, obj|
	puts "Position fix status changed to: #{fix_status}"
end

gps.on_position_change do |device, lat, long, alt, obj|
	#puts "Latitude: #{lat} degrees, longitude: #{long} degrees, altitude: #{alt} m"
end


puts "Wait for PhidgetInterfaceKit to attach..."

MIN_RESET_TIME = 1.0 #s
BASE_URL = "http://rm.local/races/"
#BASE_URL = "http://race-manager.geosugar.com/races/"

def format_timestamp(ts)
  frac = ts.to_f - ts.to_i
  ff = (frac*100).round

  snow = ts.strftime('%Y-%m-%d %H:%M:%S.')+ff.to_s
end



begin


Phidgets::InterfaceKit.new do |ifkit|

	last_value = 1000
	last_time = Time.now.getlocal('-06:00')

	puts "Linked to Race Manager at: #{BASE_URL}#{@race_id}" 
	puts "Device attributes: #{ifkit.attributes} attached"
	puts "Class: #{ifkit.device_class}"
	puts "Id: #{ifkit.id}"
	puts "Serial number: #{ifkit.serial_number}"
	puts "Version: #{ifkit.version}"
	puts "# Digital inputs: #{ifkit.inputs.size}"
	puts "# Digital outputs: #{ifkit.outputs.size}"
	puts "# Analog inputs: #{ifkit.sensors.size}"

	sleep 1

	if(ifkit.sensors.size > 0)
		ifkit.sensors.each_with_index do |s,i|
			#s.ratiometric = false
			#s.data_rate = 256
			#s.sensitivity = 2
		end
		#puts "Sensivity: #{ifkit.sensors[0].sensitivity}"
		#puts "Data rate: #{ifkit.sensors[0].data_rate}"
		#puts "Data rate max: #{ifkit.sensors[0].data_rate_max}"
		#puts "Data rate min: #{ifkit.sensors[0].data_rate_min}"
		#puts "Sensor value[0]: #{ifkit.sensors[4].to_i}"
		#puts "Raw sensor value[0]: #{ifkit.sensors[4].raw_value}"

		#ifkit.outputs[0].state = true
		#sleep 1 #allow time for digital output 0's state to be set
		#puts "Is digital output 0's state on? ... #{ifkit.outputs[0].on?}"
	end

	ifkit.sensors.each_with_index do |s,i|
		puts "Sensor " + i.to_s + ": " + s.value.to_s
		puts "dr: #{s.data_rate} #{s.sensitivity}"
	end

	ifkit.on_detach  do |device, obj|
		puts "#{device.attributes.inspect} detached"
	end

	ifkit.on_error do |device, obj, code, description|
		unless code == 36866 or 36867 
			puts "Error #{code}: #{description}"
		else
			if code == 36867 #packet loss
				print "*"
			end
			if code == 36866
				print "!" #buffer over run
			end
		end
	end

	ifkit.on_input_change do |device, input, state, obj|
		puts "Input #{input.index}'s state has changed to #{state}"
	end

	ifkit.on_output_change do |device, output, state, obj|
		puts "Output #{output.index}'s state has changed to #{state}"
	end

	ifkit.on_sensor_change do |device, input, value, obj|
		#puts "Sensor: #{input.index}"
		case input.index
		when 4
			if value < 990 and last_value > 990 and input.index == 4

				puts "#{value}::#{last_value}"
				h = gps.time[:hours]
				m = gps.time[:minutes]
				s = gps.time[:seconds]
        ms = gps.time[:milliseconds].to_s[0]
				h -= 6
				if h < 0
					h += 24
				end
				gps_time = "#{h}:#{m}:#{s}.#{ms}"
				#gps_time = "#{gps.time[:hours]}:#{gps.time[:minutes]}:#{gps.time[:seconds]}.#{gps.time[:milliseconds].to_s[0]}"
				time_stamp = Time.now.getlocal('-06:00')
				if time_stamp - last_time > MIN_RESET_TIME
					ts = time_stamp.strftime('%Y-%m-%d ') + gps_time
					#puts "Sensor #{input.index}'s value has changed to #{value} at " + ts
					last_time = time_stamp
					@timeStamps.push(ts)
					#puts "#{@timeStamps.count}"
				else
				end
			else
				#puts "#{value}::#{last_value}" 
			end
			last_value = value
		end
	end
		
	Thread.new {
		count = 1
		while true do
			if @timeStamps.count > 0
				ts = @timeStamps.shift
				puts 
				puts 
				puts "************ #{ts}"
				print "\a"
				if @race_id != nil
					if @bib == true
						print "Enter Bib #(enter to skip) --------> "
						$stdout.flush
						bib = $stdin.gets.chomp
					else
						bib = format('%02d', count)
						count += 1
					end
					if bib != ''
						logger.info("Bib: #{bib} Finish: #{ts}")
						uri = URI.parse("#{BASE_URL}#{@race_id}/finish_run")
						response = Net::HTTP.post_form(uri, {:"run[bib]" => bib, :"run[finish]" => ts})
						puts "sent #{bib}"
					else
						puts "skipped"
					end
				else
					puts ""
				end
			end
			print ".#{last_value}."
			sleep(0.5)
		end
			
	}

	while true do
		sleep(0.1)
	end
end
rescue Phidgets::Error::Timeout => e
  puts "Exception caught: #{e.message}"
end
