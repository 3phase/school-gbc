require 'net/http'

@virtual_machine_ip = "172.16.18.154:8080" #"home_public_ip:8080" #"192.168.0.102:8080"
nodes = []
@nodes_ordered = Hash.new { |array, value| array[value] = Hash.new { |hash, key| hash[key] = [] } }
@roots = Array.new { Array.new }
@roots2= Array.new { Array.new } 
@list_of_blocked=Hash.new { Array.new }
@trajectory = ""
@delete_trajectory = ""
@parent = 0

# def generate_trajectory sector, element
# 	@nodes_ordered[sector][element].each do |children|
# 		@trajectory << "#{@parent} #{children} "
# 		p "#{@trajectory}"
# 		send_post_request sector, @trajectory
# 		@trajectory = ""
# 		# generate_trajectory sector, children
# 	end
# end

def create_trajectory sector, element
	if !@roots[sector].include? element
		@nodes_ordered[sector].each do |key, value|
			if @roots[sector].include? key
				next
			else
				@trajectory = ""
				@trajectory << "#{element} #{key}"
				send_post_request sector, @trajectory
			end
		end
	end
end


def delete_system_roots_structure sector, element
	

	# parent
	# find all children
	# delete parent
	# interpret children as parent
	# parent

	
	
	

	# @nodes_ordered[sector][element].map do |key, value|
	# 	children << key
	# 	@nodes_ordered[sector].delete("#{element}")
	# end
	# children.each do |element_from_child|
	# 	delete_system_roots_structure sector, element_from_child if @nodes_ordered[sector][element_from_child].count > 0
	# 	@nodes_ordered[sector].delete("#{element_from_child}") if @nodes_ordered[sector][element_from_child].count == 0
	# end

	# 	xy = @nodes_ordered[sector][element].delete_if {|x| @nodes_ordered[sector][x].count == 0 }
		
	# 	@nodes_ordered[sector][element].each do |child|
	# 		# @nodes_ordered[sector].delete("#{element}")
	# 		p child
	# 		@nodes_ordered[sector].delete(child)
	# 	end
	# else
	# 	# p "#{element}"
	# end
	# children.each do |parent|

	# end
end

def find_whether_structure_contains_system_root sector, element
	if @roots[sector].include? element
		[@roots[sector], 1]
	else
		@nodes_ordered[sector][element].each do |child|
			if @roots[sector].include? child
				[@roots[sector], 1]
			end
		end
	end
	0
end

def send_post_request position, trajectory
	p trajectory
	uri = URI("http://#{@virtual_machine_ip}/api/sector/#{position}/company/SPGE/trajectory")
	res = Net::HTTP.post_form(uri, 'trajectory' => trajectory)
	puts res.body
end

def block_all_subelements i, element
	# p element
	if @roots[i].include? element
		# @roots[i] = @roots[i] + @nodes_ordered[i][element]
		@nodes_ordered[i][element].each do |arr_el|
			@roots2 << arr_el
			block_all_subelements i, arr_el
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
for i in 1..1 do
	@nodes_ordered[i].each do |element, v|
		block_all_subelements i, element
	end
	@roots[i] += @roots2
end


# for i in 1..10 do
	i = 1
	@nodes_ordered[i].each do |element, value| 
		result = find_whether_structure_contains_system_root i, element
		if result[1]
			delete_system_roots_structure i, element
		end
		# @iterations = 0
		# count_of_allowed_iterations = @nodes_ordered[i][element].count
		# @parent = element
		# generate_trajectory i, element
	end
	@nodes_ordered[i].each do |element, value|
		create_trajectory i, element
	end
# end
