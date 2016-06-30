require 'rubygems'
require 'phidgets-ffi'
require "net/http"


puts ARGV.size 
if ARGV.size < 1 
  STDERR.puts "Usage: ruby #{$0} race_id "
  exit(1) 
end 

@race_id = ARGV[0]

puts @race_id

puts "Library Version: #{Phidgets::FFI.library_version}"

puts "Wait for PhidgetInterfaceKit to attach..."

MIN_LATENCY = 4.0
MIN_RESET_TIME = 4.0 #s
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
	last_time = Time.now.utc
	last_reset = Time.now.utc - MIN_RESET_TIME - 10

	puts "Linked to Race Manager at: " + BASE_URL
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
		ifkit.ratiometric = false
		ifkit.sensors[0].data_rate = 64
		ifkit.sensors[0].sensitivity = 15

		puts "Sensivity: #{ifkit.sensors[0].sensitivity}"
		puts "Data rate: #{ifkit.sensors[0].data_rate}"
		puts "Data rate max: #{ifkit.sensors[0].data_rate_max}"
		puts "Data rate min: #{ifkit.sensors[0].data_rate_min}"
		puts "Sensor value[0]: #{ifkit.sensors[4].to_i}"
		puts "Raw sensor value[0]: #{ifkit.sensors[4].raw_value}"

		ifkit.outputs[0].state = true
		sleep 1 #allow time for digital output 0's state to be set
		puts "Is digital output 0's state on? ... #{ifkit.outputs[0].on?}"
	end

	ifkit.sensors.each_with_index do |s,i|
		puts "Sensor " + i.to_s + ": " + s.value.to_s
	end

	ifkit.on_detach  do |device, obj|
		puts "#{device.attributes.inspect} detached"
	end

	ifkit.on_error do |device, obj, code, description|
		puts "Error #{code}: #{description}"
	end

	ifkit.on_input_change do |device, input, state, obj|
		puts "Input #{input.index}'s state has changed to #{state}"
	end

	ifkit.on_output_change do |device, output, state, obj|
		puts "Output #{output.index}'s state has changed to #{state}"
	end

	ifkit.on_sensor_change do |device, input, value, obj|
		if value == 1000
			last_reset = Time.now.utc
		end
		time_stamp = Time.now.utc
		stability = time_stamp - last_reset
		puts "Sensor #{input.index}'s value has changed to #{value}"
		puts "last #{last_value}"
		puts "latency: #{Time.now.utc - last_time}"
		puts "stability: #{stability}"
		stablility = time_stamp - last_reset	
		if value < 1000 and last_value == 1000 and stability > MIN_RESET_TIME
			puts "Hit"
			last_value = value
			if time_stamp - last_time > MIN_LATENCY
				puts "Launching thread to post"
Thread.new {
				time_stamp = Time.now.utc
				ts = format_timestamp(time_stamp)
				puts ts
    #uri = URI.parse("http://localhost:3000/races/" + @race_id + "/runs/hardware_time")
    uri = URI.parse(BASE_URL + @race_id + "/runs/hardware_time")
    response = Net::HTTP.post_form(uri, {"timestamp" => ts})
    puts response.msg
    puts response.body
}
			end
		else 
			if 
				value == 1000 and last_value < 1000
				last_time = Time.now.utc
			end
		end
		last_value = value
	end
	while true do
		sleep(1)
	end
	#sleep 10
end
rescue Phidgets::Error::Timeout => e
  puts "Exception caught: #{e.message}"
end
