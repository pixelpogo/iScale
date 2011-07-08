#!/usr/bin/ruby

require 'rubygems'
require 'rest-client'
require 'json'
require 'yaml'

API_URL = 'https://manage.scalarium.com/api/clouds'

### BEGIN Scalarium API handling

def api(uri = '')
  JSON.parse(RestClient.get("#{API_URL}#{uri}", headers))
end

def headers
  {'X-Scalarium-Token' => @token, 'Accept' => 'application/vnd.scalarium-v1+json'}
end

def load_cloud(name)
  @cloud ||= api().detect{|cloud| cloud['name'] == name}
end

def cloud
  @cloud
end

def applications
  @applications ||= JSON.parse(RestClient.get("https://manage.scalarium.com/api/applications", headers))
end

def roles
  @roles ||= api("/#{cloud['id']}/roles")
end

def instances
  @instances ||= api("/#{cloud['id']}/instances").select{|instance| instance['status'] == 'online'}
end

def role_of_instance(instance)
  roles.detect { |r| instance['role_ids'].include? r['id']}
end

def instances_of_role(role)
  instances.select { |i| i['role_ids'].include? role['id'] }.sort{|i1, i2| i1['nickname'] <=> i2['nickname']}
end

def filtered_roles(filter)
  if filter == 'all'
    roles
  else
    roles.select { |role| role['shortname'] == filter }.sort{|r1, r2| r1['shortname'] <=> r2['shortname']}
  end
end

def filtered_instance(filter)
  instances.detect { |i| i['nickname'] == filter }
end
### END Scalarium API handling


### BEGIN base methods

def parse_command_line
  if ARGV.count == 2 && ['roles', 'refresh'].include?(ARGV[1])
    return cloud_name(ARGV[0]), ARGV[1], nil
  elsif ARGV[0] == 'deploy'
    return deploy_application(ARGV[1])
  elsif ARGV.count >= 3 && ['load', 'open', 'cpu', 'execute'].include?(ARGV[1])
    return cloud_name(ARGV[0]), ARGV[1], ARGV[2..-1]
  else
    abort "Usage: #{file_name} <cloud> <command>\n" +
          "  cloud :=   Scalarium cloud name or shortcut defined in .iScale\n" +
          "  command := roles | \n" +
          "             load { <roles> | all } |\n" +
          "             cpu { <roles> | all } |\n" +
          "             open <roles_or_instances>"
  end
end

def cloud_name(shortcut)
  @shortcuts[shortcut] || shortcut
end

def load_config
  config = YAML.load_file "#{ENV['HOME']}/.iScale"
  @username = config['username']
  @token = config['token']
  @shortcuts = config['shortcuts']
  config
end

def abort(message)
  puts message
  exit
end

def home_dir
  File.expand_path(File.dirname(__FILE__))
end

def file_name
  File.basename(__FILE__)
end

def collect(role)
  workers = []
  results = {}
  instances_of_role(role).each do |instance|
    workers << Thread.new do
      results[instance['nickname']] = yield instance
    end
  end
  collectors = []
  workers.each { |w| collectors << Thread.new { w.join(5) } }
  collectors.each { |c| c.join }
  results
end

### END base methods


### BEGIN commands

def list_roles
  roles.sort{|r1, r2| r1['shortname'] <=> r2['shortname']}.each do |role|
    puts "#{role['shortname']}: #{instances_of_role(role).count} instances"
  end
end

def load_for_hosts_of_role(role)
  t = []
  result = {}
  puts role['shortname']
  instances_of_role(role).each do |instance|
    host = instance['nickname']
    result[host] = {}
    result[host][:address] = instance['dns_name']
    t << Thread.new do
      result[host][:output] = `ssh #{@username}@#{instance['dns_name']} \"uptime | sed 's/.*load/load/'\"`
      from = 'load average: '.length
      til = -2
      result[host][:load_1m], result[host][:load_5m], result[host][:load_15m] = result[host][:output][from..til].split(', ').map{|load| load.to_f} rescue puts "Error while getting load for #{host}"
    end
  end
  t.each {|thread| thread.join(5) } # wait max. 5 seconds for all threads to finish
  load_total = {}
  load_count = 0
  result.keys.sort.each do |host|
    server = 'ssh -A ' + @username + '@' + result[host][:address] + ' =>'
    puts "#{(host + ':').ljust(14)} #{server.ljust(67)} #{result[host][:output]}" rescue puts("Error while printing #{host}")
    load_count += 1
    [:load_1m, :load_5m, :load_15m].each do |load|
      load_total[load] ||= 0
      if result[host][load]
        load_total[load] += result[host][load]
      end
    end
  end
  puts "#{'total load average:'.rjust(96)} %1.2f, %1.2f, %1.2f" % [load_total[:load_1m] / load_count, load_total[:load_5m] / load_count, load_total[:load_15m] / load_count]
  puts "#{'total load:'.rjust(96)} %1.2f, %1.2f, %1.2f" % [load_total[:load_1m], load_total[:load_5m], load_total[:load_15m]]
end

def cpu_for_hosts_of_role(role)
  t = []
  result = {}
  puts "#{role['shortname'].ljust(69)} cpu average:  %user   %nice %system %iowait  %steal   %idle"
  instances_of_role(role).each do |instance|
    host = instance['nickname']
    result[host] = {}
    result[host][:address] = instance['dns_name']
    t << Thread.new do
      result[host][:output] = `ssh #{@username}@#{instance['dns_name']} \"iostat 3 2 | grep avg-cpu -C1 | tail -1\"`
      from = 'avg-cpu: '.length
      til = -1
      result[host][:result] = result[host][:output][from..til].split(' ').delete_if{|t| t == ''}.map{|n| n.to_f} rescue puts("Error while getting load for #{host}")
    end
  end
  t.each {|thread| thread.join(5) } # wait max. 5 seconds for all threads to finish
  load_total = []
  load_count = 0
  result.keys.sort.each do |host|
    server = 'ssh -A ' + @username + '@' + result[host][:address] + ' =>'
    puts "#{(host + ':').ljust(14)} #{server.ljust(67)} %6.2f, %6.2f, %6.2f, %6.2f, %6.2f, %6.2f" % \
      [result[host][:result][0], result[host][:result][1], result[host][:result][2], result[host][:result][3], result[host][:result][4], result[host][:result][5]] rescue(puts "Error while printing #{host}")
    load_count += 1
    (0..5).each do |i|
      load_total[i] ||= 0
      if result[host][:result] && result[host][:result][i]
        load_total[i] += result[host][:result][i]
      end
    end
  end
  puts "#{'total cpu average:'.rjust(82)} %6.2f, %6.2f, %6.2f, %6.2f, %6.2f, %6.2f" % \
    [load_total[0] / load_count, load_total[1] / load_count, load_total[2] / load_count, load_total[3] / load_count, load_total[4] / load_count, load_total[5] / load_count]
  puts "#{'total cpu:'.rjust(82)} %6.2f, %6.2f, %6.2f, %6.2f, %6.2f, %6.2f" % \
    [load_total[0], load_total[1], load_total[2], load_total[3], load_total[4], load_total[5]]
end


def run_commands_on_role(role, command)
  results = collect(role) { |instance| `ssh #{@username}@#{instance['dns_name']} \"#{command}\"` }
  results.each do |instance, result|
    puts " #{instance} ".center(78, '#')
    puts result
    puts
  end
end


def deploy_application(name)
  app = applications.detect{|application| application['name'] == name}
  if app
    puts RestClient.post("https://manage.scalarium.com/api/applications/#{app['id']}/deploy", JSON.dump(:command => 'deploy'), headers)
  end
end
### END commands


### BEGIN window handling

def open_tab(name, cmd_1, cmd2)
  `#{home_dir}/open_iterm_tab.sh "#{name}" "#{cmd_1}" "#{cmd2}"`
end

def open_window()
  puts "opening new window..."
  `#{home_dir}/open_iterm_window.sh`
end

def open_tabs_with_hosts_for_role(role)
  instances_of_role(role).each do |instance|
    open_tab instance['nickname'].upcase, "ssh\ -A\ #{@username}@#{instance['dns_name']}", "sudo -sEH"
  end
end
### END window handling


### BEGIN "MAIN" program

load_config
cloud_shortcut, command, details = parse_command_line
load_cloud cloud_shortcut
abort "Unknown cloud #{cloud_shortcut.inspect}, use full cloud name or specify a shortcut in .iScale config file." unless cloud

host = 'foobar'

case command
when 'roles'
  list_roles
when 'load'
  details.each do |detail|
    if !(roles = filtered_roles(detail)).empty?
      roles.each do |role|
        load_for_hosts_of_role(role)
      end
    else
      abort "Unknown role #{detail.inspect}, use command 'roles' to list all available roles."
    end
  end
when 'open'
  open_window unless details.size == 1 && filtered_roles(details.first).size == 0 # don't open new window if we want connection to a single instance
  details.each do |detail|
    if !(roles = filtered_roles(detail)).empty?
      roles.each do |role|
        open_tabs_with_hosts_for_role(role)
      end
    else
      instance = filtered_instance(detail)
      if instance
        open_tab detail.upcase, "ssh\ -A\ #{@username}@#{instance['dns_name']}", "sudo -sEH"
      else
        abort "Unknown role or host #{detail.inspect}, use command 'roles' to list all available roles."
      end
    end
  end
when 'cpu'
  details.each do |detail|
    if !(roles = filtered_roles(detail)).empty?
      roles.each do |role|
        cpu_for_hosts_of_role(role)
      end
    else
      abort "Unknown role #{detail.inspect}, use command 'roles' to list all available roles."
    end
  end
when 'execute'
  if !(roles = filtered_roles(details.first)).empty?
    run_commands_on_role(roles.first, details[1..-1].join(' '))
  else
    abort "Unknown role #{details.first.inspect}, use command 'roles' to list all available roles."
  end
else
  abort "Unknown command '#{command}'"
end
### END "MAIN" program
