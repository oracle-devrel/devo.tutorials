#!/usr/bin/env ruby
require 'fileutils'

if ARGV.empty? || ARGV[0] =~ /^-*h(elp)?$/i
  puts "Usage: #{__FILE__} FILENAME.md"
  Process.exit 0
end

IMG_RX = /(?mi)(?<=\()(?<url>https?:\/\/(?<filename>[^ ]+\.(?:png|gif|jpe?g|pdf|webp|webm|mp4|avi|ogg)))(?<query>[^ )]+)?(?<addl>.*?)(?=\))/

ARGV.each do |f|
  file = File.expand_path(f)
  raise "Not a valid file: #{f}" unless File.exist?(file)

  Dir.chdir(File.dirname(file))
  FileUtils.mkdir_p('assets') unless File.directory?('assets')

  prefix = File.basename(file, '.md').strip.gsub(/ +/, '-')
  content = IO.read(file)

  content.gsub!(IMG_RX) do |c|
    m = Regexp.last_match
    filename = %(#{prefix}-#{File.basename(m['filename']).gsub(/ +/, '-')})
    warn "#{m['url']}#{m['query']} => #{filename}"
    `curl -SsL -o "assets/#{filename}" "#{m['url']}#{m['query']}"`
    %(assets/#{filename}#{m['addl']})
  end

  File.open(file, 'w') do |f|
    f.puts content
  end
end
