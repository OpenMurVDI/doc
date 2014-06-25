#!/usr/bin/ruby

# Alejandro Roca Alhama
# Script to create VM for our students
# Version 0.2.
# Last modifications: 12/may/2014.

require 'optparse'

# Check command line parameters: file with the users to create and the group name.
options = {}
option_parser = OptionParser.new do |opts|
  executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Script for the batch creation of Virtual Machines

Usage: #{executable_name} [options] filename"

  opts.on('-h', '--help', 'Show how to use the command') do
    options[:help] = true
  end

  opts.on('-s', '--simulate', 'Don\'t create the users, only show the commamnds to execute') do |opts|
    options[:simulate] = true
  end

  #opts.on('-f FILE', 'File with the users to create') do |file|
  #  options[:file] = file
  #end
end

option_parser.parse!
if options[:help]
  puts option_parser.help
  exit(0)
elsif ARGV.empty?
  puts 'You must provide a filename'
  puts
  puts option_parser.help
  exit(0)
else
  filename = ARGV[0]
end

# Read the file. From the file we must generate instance name and description
id = '00'
group = 'asir1'
begin
  IO.foreach(filename) do |line|
    user = line.chomp.split(',')
    last_name = user[0]
    first_name = user[1]
    # To generate the id with zeros left padding we can use string.rjust(3, "0")
    command = 'nova boot --flavor 6 --key_name mykey --image 89a1f50c-89f6-482d-b17e-2146a074b085 --security_group default '
    command += "--meta name='#{last_name}, #{first_name}' "
    command += "#{group}-#{id}"
    if options[:simulate]
      puts command
    else
      system(command)
    end
    id = id.next
  end
rescue Errno::ENOENT
  STDERR.puts "File #{filename} doesn't exist"
end
