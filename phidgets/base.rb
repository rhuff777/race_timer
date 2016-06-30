#!/usr/bin/ruby
require 'rubygems'
require 'phidgets-ffi'
require "net/http"
require 'io/console'
require 'logger'

logger = Logger.new("log.log")
logger.info("Program Started")

puts ARGV.size 
if ARGV.size < 1 
  STDERR.puts "Usage: ruby #{$0} race_id "
  exit(1) 
end 

@race_id = ARGV[0]

puts @race_id

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
	last_time = Time.now.utc

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
		if value < 1000 and last_value == 1000
			gps_time = "#{gps.time[:hours]}:#{gps.time[:minutes]}:#{gps.time[:seconds]}.#{gps.time[:milliseconds].to_s[0]}"
			time_stamp = Time.now.utc
			if time_stamp - last_time > MIN_RESET_TIME
				ts = time_stamp.strftime('%Y-%m-%d ') + gps_time
				puts "Sensor #{input.index}'s value has changed to #{value} at " + ts
				last_time = time_stamp
			else
			end
		else 
		end
		last_value = value
	end
	while true do
		sleep(0.1)
	end
end
rescue Phidgets::Error::Timeout => e
  puts "Exception caught: #{e.message}"
end
