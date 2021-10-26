#!/usr/bin/env ruby
require 'yaml'

Dir.glob(File.join('**', '*.md')).each do |post|
  begin
    next if File.basename(post, '.md') =~ /(README|index)/
    parts = IO.read(post).split(/---/)
    next unless parts.count > 2

    header = parts[1]

    content = parts[2..-1].join('---')

    data = YAML.load(header)

    next if data.empty? || data['series']

    data['redirect_from'] = "/collections/tutorials/#{File.basename(post, '.md')}/"

    out = [YAML.dump(data),content].join('---')

    File.open(post, 'w') do |f|
      f.puts out
    end
  rescue
    # Read failed
  end
end
