#/usr/bin/env ruby

# This script will take your existing config.yml file (up to and including version 0.4)
# and convert it into the 0.5 format, which allows for multiple webapps to be run using the same Liverpie instance.
#

require 'yaml'

old_yml_file = 'liverpie.yml'

unless File.exist?(old_yml_file)
  puts "Could not find liverpie.yml. Please run this converter from the config directory"
  exit
end

old_yml = YAML.load_file old_yml_file

puts "Converting your configuration file. The new file will have an application named 'my_webapp' with your existing application data. Please change that as you wish."

config = old_yml['configuration']
new_yml_hash = {
  'configuration' => {
    'bind_ip'   => config['bind_ip'],
    'bind_port' => config['bind_port']
  },
  'webapps' => {
    'my_webapp' => {
      'ip'                => config['webapp_ip'],
      'port'              => config['webapp_port'],
      'state_machine_uri' => config['webapp_uri'],
      'reset_uri'         => config['webapp_reset_uri'],
      'dtmf_uri'          => config['webapp_dtmf_uri']
    }
  }
}

puts 'Renaming your configuration file into liverpie.yml.obsolete...'

File.rename old_yml_file, 'liverpie.yml.obsolete'

puts 'Saving converted configuration file...'

File.open('liverpie.yml', 'w') do |out|
  YAML.dump new_yml_hash, out
end

puts 'Done. Thank you!'
