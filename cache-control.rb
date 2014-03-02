# grab list of top 100 websites

require 'open-uri'
require 'open_uri_redirections'
require 'csv'
require 'httpclient'
require 'curb'
require 'typhoeus'

def cache_control(url)
	get_header(url, "cache-control")
end

def get_header(url, header)
	get_header_typhoeus(url, header)
end

def get_header_open(url, header)
end

def get_header_typhoeus(url, header)
	res = Typhoeus::Request.new(url, followlocation: true)
	res.on_complete do |response|
		response.headers
	end
	res.run
	nil
end

def get_header_httpclient(url, header)
	http = HTTPClient.new
	http.receive_timeout = 2
	retries = 0
	begin
		res = http.get(url, follow_redirect: true)
		res.header[header].first
	rescue
		retry if (retries += 1) > 3
		"TIMEOUT"
	end
end

def get_header_curb(url, header)
	http = Curl::Easy.new
	http.follow_location = true
	http.url = url
	http.perform
	p http.header_str
	http.headers[header]
end

def top100
	filename = 'top-100.csv'
	CSV.read filename
end

sites = %w(
	http://google.com
	http://twitter.com
	http://yahoo.com
	)

hydra = Typhoeus::Hydra.hydra
res = []

results = top100.first(100).map do |a,b|
# results = sites.map do |a,b|
	req = Typhoeus::Request.new(b, timeout: 2, followlocation: true)
	hydra.queue req
	req.on_complete do |response|
		# p response.headers
		if response.timed_out?
			res << [a,b,"TIMED OUT"]
		else
			c = response.headers["Cache-Control"]
			puts "#{b} - #{c}"
			res << [a, b, c]
		end
	end
	# cache_settings = cache_control('http://' + b)
	# puts "#{cache_settings}"
	# [a,b,cache_settings]
end

hydra.run

p res

CSV.open('top-100-cache.csv', 'w') do |writer|
	res.sort_by!{|a| a.first.to_i}.each do |c|
		writer << c
	end
end

# sites.each do |site|
# 	p cache_control(site)
# end

# p top100