require 'net/http'

@virtual_machine_ip = "192.168.0.102:8080"
nodes = []
@nodes_ordered = Hash.new { |array, value| array[value] = Hash.new { |hash, key| hash[key] = [] } }
@roots = []
@list_of_blocked=Hash.new { Array.new }
@trajectory = ""
@iterations = 0

def send_post_request position, trajectory
	p trajectory
	# uri = URI("http://#{@virtual_machine_ip}/api/sector/#{position}/company/SPGE/trajectory")
	# res = Net::HTTP.post_form(uri, 'trajectory' => trajectory)
	# puts res.body
end

def trajectory element, sector, count_of_allowed_iterations
	# p "Iteration #{@iterations}, with having #{count_of_allowed_iterations} limited iterations; #{element}, #{sector}, #{@nodes_ordered[sector][element]}"
	@iterations+=1
	@nodes_ordered[sector][element].each do |node|
		@trajectory << "#{node} "
		if !@nodes_ordered[sector].has_key? node
			send_post_request sector, @trajectory
			@trajectory = ""
		else
			trajectory node, sector, count_of_allowed_iterations if @iterations <= count_of_allowed_iterations
		end
	end
end

def remove_node sector, node
	@nodes_ordered[sector][node].each do |element|
		if @roots[sector].include? element
			@nodes_ordered[sector][node].delete(element)
			remove_node sector, element
		end
	end
	if @roots[sector].include? node
		@nodes_ordered[sector].delete("#{node}")
	end
end

def clear_nodes_from_roots
	@nodes_ordered.each do |sector, val|
		@nodes_ordered[sector].each do |key, value|
			remove_node sector, key
		end
	end
end

def get_system_roots
	for i in 1..1 do
		@roots[i] = []
		j = 0
		url = URI.parse("http://#{@virtual_machine_ip}/api/sector/#{i}/roots")
		req = Net::HTTP::Get.new(url.to_s)
		res = Net::HTTP.start(url.host, url.port) { |http|
		  http.request(req)
		}
		res = res.body
		res = res.split("\n")
		res.each do |element|
			@roots[i] << element.to_i
		end
	end
end

def get_nodes
	nodes = []
	thr = []
	i=1
	loop do 

		thr[i] = Thread.new do
			url = URI.parse("http://#{@virtual_machine_ip}/api/sector/#{i}/objects")
			req = Net::HTTP::Get.new(url.to_s)
			res = Net::HTTP.start(url.host, url.port) { |http|
			  http.request(req)
			}
			nodes[i] = res.body
			nodes[i] = nodes[i].split("\n")
		end

		thr[i].join
		nodes[i].each do |el|
			el = el.split(" ")
			@nodes_ordered[i.to_i][el[0].to_i] << el[1].to_i
		end
		i-=1
		break if i == 0
	end
end

get_nodes
get_system_roots
clear_nodes_from_roots


# for i in 1..10 do
	i = 1
	@nodes_ordered[i].each do |element, value| 
		@iterations = 0
		count_of_allowed_iterations = @nodes_ordered[i][element].count
		@trajectory << "#{element} "
		trajectory element, i, count_of_allowed_iterations
	end
# end
