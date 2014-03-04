require 'csv'
require 'typhoeus'

class CacheChecker
	def initialize
		@results = []
		@hydra = Typhoeus::Hydra.hydra
	end

	def run!
		check_sites
		write_csv
	end

	def domains(filename = 'top-100.csv')
		CSV.read filename
	end


	def check_sites
		domains.each do |rank, url|
			req = Typhoeus::Request.new(url, timeout: 10, followlocation: true)
			@hydra.queue(req)

			req.on_complete do |response|
				if response.timed_out?
					msg = "TIMED OUT"
				else
					msg = response.headers["Cache-Control"]
					puts "#{url} - #{msg}"
				end
				@results << [rank, url, msg]
			end
		end

		@hydra.run
	end

  def write_csv(filename = 'top-100-cache.csv')
		CSV.open(filename, 'w') do |output|
			@results.sort_by!{|a| a.first.to_i}.each do |res|
				output << res
			end
		end
	end
end

c = CacheChecker.new
c.run!
