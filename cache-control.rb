require 'csv'
require 'typhoeus'

def top100
	filename = 'top-100.csv'
	CSV.read filename
end

# Use Typhoeus for parallel downloads
hydra = Typhoeus::Hydra.hydra
results = []

top100.each do |rank, url|
	req = Typhoeus::Request.new(url, timeout: 10, followlocation: true)
	hydra.queue(req)

	req.on_complete do |response|
		if response.timed_out?
			msg = "TIMED OUT"
		else
			msg = response.headers["Cache-Control"]
			puts "#{url} - #{msg}"
		end
		results << [rank, url, msg]
	end
end

hydra.run

# Write results to a csv file
CSV.open('top-100-cache.csv', 'w') do |output|
	results.sort_by!{|a| a.first.to_i}.each do |res|
		output << res
	end
end
