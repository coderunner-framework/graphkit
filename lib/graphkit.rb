script_folder = File.dirname(File.expand_path(__FILE__))

require 'pp'
require 'rubyhacks'
#require script_folder + '/box_of_tricks.rb'
#require script_folder + '/gnuplot.rb'

class Matrix
	def shape
		return[row_size, column_size]
	end
end

class Hash
	def modify(hash, excludes=[])
		hash.each do |key, value|
# 			p key
# 			ep key, value if value #if option == :xrange

			begin
				self[key] = value.dup unless excludes.include? key
			rescue TypeError #immediate values cannot be dup'd
				self[key] = value unless excludes.include? key
			end
		end
		self
	end
	alias :absorb :modify
end

# class Array
# 	def to_sparse_tensor_key
# 		return SparseTensor::Key.new)
# 	end
# end


# A simple sparse tensor

class SparseTensor < Hash
	class RankError < StandardError
	end
	
# 	class Key < Array
# 		def ==
# 			
# 	end
	
	
	attr_reader :rank, :shape
	#attr_accessor :default_val
	
	# Create a new tensor.
	
	def initialize(rank = 2)
		@rank = rank
		@shape = [0]*rank
		super()
	end
	
	# Create a new diagonal tensor from an array. E.g. if rank was 2, then 
	# 	tensor[0,0] = array[0]
	# 	tensor[1,1] = array[1]
	# Etc.
	
	def self.diagonal(rank, array)
		tensor = new(rank)
		for index in 0...array.size
			tensor[[index] * rank] = array[index]
		end
		tensor
	end
	
	# Access an element of the tensor. E.g. for a rank 2 tensor
	#
	# 	a = tensor[1,3]
	
	def [](*args)
		args = args[0] if args.size == 1 and not args.size == @rank and args[0].size == @rank
# 		p args

		raise RankError.new("Rank is #@rank, not #{args.size}") unless args.size == @rank
		return nil unless keys.include? args
		#if self.keys.include?(args) or @default_val == nil
			#eputs args.pretty_inspect
			#eputs self.pretty_inspect
			#eputs self.class, self.class.ancestors
			super(args)
		#else
			#return @default_val
		#end

	end
	
	# Set an element of the tensor. E.g. for a rank 2 tensor
	#
	# 	tensor[1,3] = a_variable
	
	def []=(*args)
		value = args.pop
		args = args[0] if args.size == 1 and args[0].size == @rank
		raise RankError.new("Rank is #@rank, not #{args.size}") unless args.size == @rank
		args.each_with_index do |arg, index|
			@shape[index] = [@shape[index], arg + 1].max
		end
		super(args, value)
	end
	
	# Perform some action involving all the elements of this tensor and another.
	# 
	# E.g.
	# 	tensor_1.scalar_binary(tensor_2) do |element_1, element_2|
	# 		element_1 + element_2
	# 	end
	#
	# will add every element of tensor_1 to every corresponding element of tensor_2.
			
	
	
	def scalar_binary(other, &block)
		raise ArgumentError unless other.class == self.class
		raise RankError.new("Different ranks: #@rank, #{other.rank}") unless other.rank == @rank

		new = self.class.new(@rank)
		self.keys.each do |key|
			if other[key]
				new[key] = yield(self[key], other[key])
			else
				new[key] = self[key]
			end
		end
		(other.keys - self.keys).each{|key| new[key] = other[key]}
		new
	end
	def +(other)
		scalar_binary(other){|a, b| a + b}
	end
	def -(other)
		scalar_binary(other){|a, b| a - b}
	end
	
	# Find the maximum element of the tensor. See Enumerable#max.
	
	def max(&block)
		return self.values.max(&block)
	end
	
	# Find the minimum element of the tensor. See Enumerable#max.
	
	def min(&block)
		return self.values.min(&block)
	end


	
	def alter!(&block)
		self.keys.each do |k|
			self[k] = yield(self[k])
		end
	end
	def self.from_hash(hash)
		st = new(hash.keys[0].size)
		hash.each{|k,v| st[k] = v}
		st
	end
	def inspect
		"SparseTensor.from_hash(#{super})"
	end


end

	
	

# To be mixed in to a Hash. Basically allows access the elements of a hash via method names rather than brackets.


module Kit
	
	class IntegrityError < StandardError
	end
	
	def method_missing(method, *args)
# 		p method, args
		m = method.to_s
		if m =~ /=$/
			name = m.chop.to_s
			self.class.send(:define_method, method){|arg| self[name.to_sym] = arg}
			return send(method, args[0])
		else
			self.class.send(:define_method, method){self[method]}
			return send(method)
		end
	end
	
	def check(*values, &block)
		values.each do |arr|
			case arr.size 
			when 2
				expression, test_data = arr
				if block
					raise IntegrityError.new("#{expression} failed argument correctness test (value given was '#{self[expression].inspect}')") unless yield(instance_eval(expression), test_data)
				else
					is_array = test_data.class == Array
					raise IntegrityError.new("#{expression} was  #{instance_eval(expression)} instead of #{test_data.inspect}") unless (is_array ? test_data.include?(instance_eval(expression)) : instance_eval(expression) == test_data)
				end
			when 3
				string, value, test_data = arr
				if block
					raise IntegrityError.new("#{string} failed argument correctness test (value given was '#{value.inspect}')") unless yield(value, test_data)
				else
					is_array = test_data.class == Array
					raise IntegrityError.new("#{string} was #{value.inspect} instead of #{test_data.inspect}") unless (is_array ? test_data.include?(value) : value == test_data)
				end
			else
				raise "Bad value checking data: #{arr.inspect}"
			end
		end
	end
	
	
	

	
end

# See Kit

class KitHash < Hash
	include Kit
	aliold :inspect
	def inspect
		return (%[#{self.class}.from_hash(#{old_inspect})])
	end
	def self.from_hash(hash)
		kit = new
		hash.each do |key, val|
			kit[key] = val
		end
		kit
	end
end

# A GraphKit is 'a complete kit of things needed to make a graph'. By graph, a 1d, 2d, 3d, or 4d (3 + colouring/shading) visualisation is meant. The first thee axes are given the traditional labels :x, :y, :z, and the fourth :f, meaning fill, or function.
#
# Time variation can be can be achieved by an array of GraphKits each at a different time.
#
# A GraphKit is a hash where some of the keys must be specific things, and it provides a method, check_integrity, to ensure that the keys are assigned correctly. This method also checks that dimensions and ranks of all the data are consistent, allowing a graph to be plotted.
#
# GraphKit also allows you access any property, e.g. title, as
#
#	graphkit.title
#	
#	graphkit.title = 
#
# as well as the hash form:
#
#	graphkit[:title]
#	graphkit[:title] =
# 
# GraphKits have methods which allow the graphs to be rendered using standard visualisation packages. At present only gnuplot is supported, but others are planned.
#
# GraphKits overload certain operators, for example <tt>+</tt>, which mean that they can be combined easily and intuitively. This makes plotting graphs from different sets of results on the same page as easy as adding 2+2!
# 
# GraphKits define a minimum set of keys which are guaranteed to be meaningful and work on all platforms. If you stick to using just these properties, you'll be able to easily plot basic graphs. If you need more control and customisation, you need to look at the documentation both for the visualisation package (e.g. gnuplot) and the module which allows a GraphKit to interface with that package (e.g. GraphKit::Gnuplot).
#
# Here is the specification for the standard keys:
# 
# * title (String): the title of the graph
# * xlabel, ylabel, zlabel (String): axis labels
# * xrange, yrange, zrange, frange (Array): ranges of the three dimensions and possibly the function as well.
# * data (Array of GraphKit::DataKits): the lines of data to be plotted. 


class GraphKit < KitHash


	class MultiKit < Array

    def self.uninspect(arr, ivars)
      mkit = new(arr)
      ivars.each do |var,val|
        mkit.instance_variable_set(var,val)
      end
      mkit
    end
		def merge(other)
			size.times do |i|
			 self[i] += other[i] if other[i]
			end
			self
		end		

    def +(other)
      merge(other)
    end

    def inspect
      "GraphKit::MultiKit.uninspect(#{super}, :@gnuplot_sets=>#{@gnuplot_sets.inspect})"
    end


	end
	MultiWindow = MultiKit # Backwards compatibility

	
	
	include Kit
	include Log
	AXES = [:x, :y, :z, :f]
	DEFAULT_COLOURS = {0 => "#df0000", 1 => "#00df00", 2 => "#0000df", 3 => "#a000a0", 4 => "#0090a0", 5 => "#e59500", 7 => "#82c290", 8 => "#f76dba", 9 => "#c20f00", 10 => "#4f1099"}
	DEFAULT_COLOURS_GNUPLOT = DEFAULT_COLOURS
	DEFAULT_COLOURS_MATHEMATICA = DEFAULT_COLOURS.inject({}) do |hash, (i, coll)|
		hash[i] = coll.sub(/#/, '').scan(/.{2}/).map{|str| (eval("0x#{str}").to_f / 255.0).round(2)}
	  hash	
	end

# 	attr_reader :gnuplot_options
	
	alias :hash_key :key
	undef :key
	
	# Greate a new graphkit. Rarely used: see GraphKit.autocreate and GraphKit.quick_create
	
	def initialize(naxes=0, hash = {})
		logf :initialize
		super()
		self[:naxes] = naxes 
		self[:data] = []
		hash
# 		@gnuplot_options = GnuplotOptions.new
	end
	
# 	def gnuplot_options
# 		@gnuplot_options ||= GnuplotOptions.new
# 		@gnuplot_options
# 	end
	
# 	alias :gp :gnuplot_options
	
	class DataError < StandardError
	end
	
	# Create a new graphkit with one hash for every datakit (each datakit corresponds to a line or surface on the graph). Each hash should contain specifications for the axes of the graph (see AxisKit#autocreate).
	#
	# E.g.
	# 	kit = GraphKit.autocreate(
	# 		{
	# 			x: {data: [1,2,3], title 'x', units: 'm'}, 
	# 			y: {data: [1,4,9], title 'x^2', units: 'm^2'}
	# 		}
	# 	)
	#
	# will create a two dimensional graph that plots x^2 against x.
	
	def self.autocreate(*hashes)
		Log.logf :autocreate
		new(hashes[0].size).autocreate(*hashes)
	end
	
	
	def lx(*args) # :nodoc:
		log_axis(*args)
	end
	
	def lx=(val) # :nodoc:  (deprecated)
		self.log_axis = val
	end
	
	# Create a new graphkit without providing any labels.
	#
	# E.g.
	# 	kit = GraphKit.quick_create(
	# 		[
	# 			[1,2,3], 
	# 			[1,4,9]
	# 		]
	# 	)
	#
	# will create a two dimensional graph that plots x^2 against x.
	
	def self.quick_create(*datasets)
		hashes = datasets.map do |data|
			hash = {}
			data.each_with_index do |dat, i|
				hash[AXES[i]] = {data: dat}
			end
			hash
		end
		autocreate(*hashes)
	end
	
	
	
	def autocreate(*hashes) # :nodoc:  (see GraphKit.autocreate)
		logf :autocreate
		hashes.each{|hash| data.push DataKit.autocreate(hash)}
# 		pp data
		[:title, :label, :units, :range].each do |option| 
			data[0].axes.each do |key, axiskit|
# 			next unless AXES.include? key
				self[key + option] = axiskit[option].dup if axiskit[option]
			end
		end
		self.title = data[0].title
		check_integrity
		self
	end
		
	# Check that the graphkit conforms to specification; that the data has dimensions that make sense and that the titles and ranges have the right types.
	
	def check_integrity
		logf :check_integrity
		check(['data.class', Array], ['title.class', [String, NilClass]], ['has_legend.class', [Hash, NilClass]])
		[[:units, [String, NilClass]], [:range, [Array, NilClass]], [:label, [String, NilClass]], [:title, [String, NilClass]]].each do |prop, klass|
# 			next unless self[prop]
			AXES.each do |key|
# 				p prop, klass
# 				p instance_eval(prop.to_s + "[#{key.inspect}]"), 'ebb'
				check(["#{key + prop}.class", klass])
# 				check(["a key from #{prop}", key, AXES + [:f]])
			end	
		end
		data.each do |datakit|
			check(['class of a member of the data array', datakit.class, DataKit])
			check(['datakit.axes.size', datakit.axes.size, naxes])
			datakit.check_integrity
		end
		return true
	end
	
# 	AXES.each do |axisname|
# 		[:name, :label, :units, :range].each do |option|
# 			define_method(axisname + option){self[option][axisname]}
# 			define_method(axisname + option + '='.to_sym){|value| self[option][axisname] = value}
# 		end
# 	end
	
	@@old_gnuplot_sets = [ :dgrid3d, :title, :style, :term, :terminal, :pointsize, :log_axis, :key, :pm3d, :palette, :view, :cbrange, :contour, :nosurface, :cntrparam, :preamble, :xtics, :ytics]
	
	
# 		@@gnuplot_sets.uniq!
	
	# Duplicate the graphkit.
		
	def dup
		#logf :dup
		#self.class.new(naxes, self)
		eval(inspect)
	end
	
	# Combine with another graph; titles and labels from the first graph will override the second. 

	def +(other)
		check(['other.naxes', other.naxes, self.naxes])
		new = self.class.new(naxes)
		new.modify(other, [:data])
		new.modify(self, [:data])
		new.data = self.data + other.data
		new
	end
	
	def extend_using(other, mapping = nil)
		if mapping
			mapping.each do |mine, others|
				data[mine].extend_using(other.data[others])
			end
		else
			raise TypeError.new("A graph can only be extended by a graph with the same number of datasets unless a mapping is provided: this graph has #{data.size} and the other graph has #{other.data.size}") unless data.size == other.data.size
			data.each_with_index do |dataset, index|
				dataset.extend_using(other.data[index])
			end
		end
	end
	
	def each_axiskit(*axes, &block)
		axes = AXES unless axes.size > 0
		axes.each do |axis|
			data.each do |datakit|
				yield(datakit.axes[axis])
			end
		end
	end

	def plot_area_size
		logf :plot_area_size
		shapes = data.map{|datakit| datakit.plot_area_size}.inject do |old,new|
			for i in 0...old.size
				old[i][0] = [old[i][0], new[i][0]].min
				old[i][1] = [old[i][1], new[i][1]].max
			end
			old
		end
		shapes

	end
	
	def transpose!
		data.each do |datakit|
			datakit.transpose!
		end
		self.xlabel, self.ylabel = ylabel, xlabel
		self.xrange, self.yrange = xrange, yrange
	end
	
				def convert(&block)
					#ep 'Converting graph...'
					kit = self.dup
					#p kit

					kit.data.map! do |dk|
						dk.convert(&block)
					end
					kit
				end
# end #class GraphKit


		# Convert the rank of the data from from_to[0] to from_to[1].
	  # E.g. convert a line of values of [x, y, z] with rank [1,1,2]
	  # to a matrix of values [x, y, z] with rank [1, 1, 2]
		#    convert_rank!([[1,1,1], [1,1,2]])
	
		def convert_rank!(from_to, options={})
			ep "Converting Rank"
			case from_to
			when [[1,1,1], [1,1,2]]
				dependent_dimension = options[:dd] || options[:dependent_dimension] || 2
				other_dims = [0,1,2] - [dependent_dimension]
				od0 = other_dims[0]
				od1 = other_dims[1]
				data.each do |dk|
					new_data = SparseTensor.new(2)
					od0_data = dk.axes[AXES[od0]].data.to_a.uniq.sort
					od1_data = dk.axes[AXES[od1]].data.to_a.uniq.sort

					for i in 0...dk.axes[:x].data.size
						od0_index = od0_data.index(dk.axes[AXES[od0]].data[i])
						od1_index = od1_data.index(dk.axes[AXES[od1]].data[i])
						new_data[[od0_index, od1_index]] = dk.axes[AXES[dependent_dimension]].data[i]
					end
					dk.axes[AXES[od0]].data = od0_data
					dk.axes[AXES[od1]].data = od1_data
					dk.axes[AXES[dependent_dimension]].data = new_data
				end

			else
				raise "Converting from #{from_to[0].inspect} to #{from_to[1].inspect} is not implemented yet."
			end
			eputs self.pretty_inspect
		end

class DataKit < KitHash
				def convert(&block)

						xdat = self.axes[:x].data.to_gslv
						ydat = self.axes[:y].data.to_gslv
						xnew = GSL::Vector.alloc(xdat.size)
						ynew = GSL::Vector.alloc(xdat.size)

						for i in 0...xdat.size
							xnew[i], ynew[i] = yield(xdat[i], ydat[i])
						end
						self.axes[:x].data=xnew
						self.axes[:y].data=ynew
						#p 'dk', self
						self
					
				end
	
# 	include  Kit
	include Log
	AXES = GraphKit::AXES
	AXES.each{|ax| define_method(ax){self.axes[ax]}} 
	AXES.each{|ax| define_method(ax + "=".to_sym){|val| self.axes[ax] = val}} 
	
# 	attr_accessor :labels, :ranges, :has_legend, :units, :dimensions
	

  def axes_array
		self.axes.values_at(*AXES).compact
	end
	def initialize(options = {})
		super()
		self[:axes] = {}
		absorb options
	end

	def self.autocreate(hash)
		new.autocreate(hash)
	end
	
	def autocreate(hash)
		logf :autocreate
		hash.each do |key, value|
# 			puts value.inspect
			if AXES.include? key
				self[:axes][key] = AxisKit.autocreate(value)
			else 
				raise ArgumentError.new("bad key value pair in autocreate: #{key.inspect}, #{value.inspect}")
			end
# 			puts self[key].inspect
		end
# 		pp self
		first = true
		self.title = AXES.map{|axis| axes[axis] ? axes[axis].title : nil}.compact.reverse.inject("") do |str, name|
			str + name + (first ? (first = false; ' vs ') : ', ')
		end
		self.title = self.title.sub(/, $/, '').sub(/ vs $/, '')
		check_integrity
		self
	end
	
	def check_integrity
		logf :check_integrity
		check(['title.class', [String, NilClass]], ['with.class', [String, NilClass]],  ['axes.class', Hash])
		axes.keys.each do |key|
 			check(["key #{key} from a datakit.axes", key, AXES])
			check(["self.axes[#{key.inspect}].class", AxisKit])
			self.axes[key].check_integrity
		end
# 		axes.values.map{|axiskit| axiskit.data.to_a.size}.each_with_index do |size, index|
# 			raise IntegrityError.new("Axis data sets in this datakit have different sizes than the function #{size}, #{f.shape[0]}") unless size == new_size
# 			size
# 		end
# 		puts 'checking f.class', f.class
# 		check(['f.class', CodeRunner::FunctionKit])
		
# 		shape = f.shape
		log 'checking ranks'
		rnks = ranks
		log rnks
		raise IntegrityError.new("The combination of ranks of your data cannot be plotted. Your data has a set of axes with ranks #{rnks.inspect}. (NB, rank 1 corresponds to a vector, rank 2 to a matrix and 3 to a third rank tensor). The only possible sets of types are #{allowed_ranks.inspect}") unless allowed_ranks.include? rnks
		passed = true
		case rnks
		when [1], [1,1], [1,1,1], [1,1,1,1]
			axes.values.map{|axiskit| axiskit.shape}.inject do |old, new|
# 				puts old, new
				passed = false unless new == old
				old
			end
		when [1,1,2], [1,1,2,2]
# 			passed = false unless axes[:x].shape == axes[:y].shape
			passed = false unless axes[:z].shape == [axes[:x].shape[0], axes[:y].shape[0]]
			passed = false unless axes[:z].shape == axes[:f].shape if axes[:f]
		when [1,1,1,3]
			#axes.values_at(:x, :y, :z).map{|axiskit| axiskit.shape}.inject do |old, new|
				#passed = false unless new == old
				#old
			#end
			passed = false unless axes[:f].shape == [axes[:x].shape[0], axes[:y].shape[0], axes[:z].shape[0]]
		end
		raise IntegrityError.new(%[The dimensions of this data do not match: \n#{axes.inject(""){|str, (axis, axiskit)| str + "#{axis}: #{axiskit.shape}\n"}}\nranks: #{rnks}]) unless passed 
# 		log 'finished checking ranks'
		logfc :check_integrity
# 		raise IntegrityError.new("function data must be a vector, or have the correct dimensions (or shape) for the axes: function dimensions: #{shape}; axes dimesions: #{axes_shape}") unless shape.size == 1 or axes_shape == shape
		return true
	end
	
		#ALLOWED_RANKS  = [[1], [1,1], [1,1,1], [1,1,2], [1,1,1,1], [1,1,2,2], [1,1,1,3]]
		ALLOWED_RANKS = [[1], [1,1], [1,1,1], [1,1,2], [2,2,2], [2,2,2,2], [1,1,1,1], [1,1,2,2], [1,1,1,3], [3,3,3,3]]

		def allowed_ranks 
			ALLOWED_RANKS
		end
		#def ranks_c_switch_hash
			#hash = {}
			#allowed_ranks.each_with_index do |rank,i|
				#hash[rank] = i
			#end
			#p hash
			#hash
		#end
	def shapes
		logf :shapes
		ans = axes.values_at(*AXES).compact.inject([]){|arr, axis| arr.push axis.shape}
		logfc :shapes
		return ans
	end
	
	def rank_c_switch
		#i = -1
		#puts ALLOWED_RANKS.map{|r| i+=1;"#{i} --> #{r}"}
		 switch = ALLOWED_RANKS.index(ranks)
		switch
		
	end
	def ranks
		logf :ranks
		ans = shapes.map{|shape| shape.size}
		logfc :ranks
		return ans
	end
	
	def extend_using(other)
		raise "A dataset can only be extended using another dataset with the same ranks: the ranks of this dataset are #{ranks} and the ranks of the other dataset are #{other.ranks}" unless ranks == other.ranks
		axes.each do |key, axiskit|
			axiskit.extend_using(other.axes[key])
		end
	end
	
# 	def gnuplot_ranks
# 		case axes.size
# 		when 1,2
# 			return ranks
# 		when 3
# 			return [1,1,2]
# 		when 4
# 			case ranks[2]
# 			when 1
# 				return [1,1,1,3]
# 			when 2
# 				return [1,1,2,2]
# 			end
# 		end
# 	end
# 	
# 	def gnuplot
# # 		p axes.values_at(*AXES).compact.zip(gnuplot_ranks)
# 		Gnuplot::DataSet.new(axes.values_at(*AXES).compact.zip(gnuplot_ranks).map{|axis, rank|  axis.data_for_gnuplot(rank) }) do |ds|
# 			(keys - [:axes, :outlier_tolerance, :outliers, :gnuplot_options]).each do |key|
# 				ds.set(key, self[key])
# 			end
# 			if @gnuplot_options
# 				@gnuplot_options.each do |opt, val|
# 					ds.set(opt, val)
# 				end
# 			end
# # 			ds.title = title
# # 			ds.with = [:lines, :points].inject(""){|str, opt| self[opt] ? str + opt.to_s : str }
# # 			p ds.with
# 		#	ds.with = "lines"
# 	# 					ds.linewidth = 4
# 		end
# 	end
# 
# 	def gnuplot_options
# 		@gnuplot_options ||= GnuplotPlotOptions.new
# 		@gnuplot_options
# 	end
# 	
# 	alias :gp :gnuplot_options
# 
	
	AXES.each do |axisname|
		define_method(axisname + :axis){self[:axes][axisname]}
		define_method(axisname + :axis + '='.to_sym){|value| self[:axes][axisname] = value}
	end

	def dup
# 		puts 'Datakit.dup'
		new = self.class.new(self)
		new.axes.each do |axis, value|
			new.axes[axis] = value.dup
		end
		new
	end

	def plot_area_size
		ans = []
# 		p data
		(axes.values_at(*AXES).compact).each do |axiskit|
			if range = axiskit.range
				ans.push range
				next
			else
# 				p 'hello'
# 				p data[0].axes[key]
				axdata = axiskit.data #(key == :f) ? data[0].f.data : (next unless data[0].axes[key]; data[0].axes[key].data)
				next unless axdata
				#p 'axdatamin', axdata.min
				ans.push [axdata.min, axdata.max]
			end
		end
		ans
	end

	def exclude_outliers
		raise "Can only get rid of outliers for 1D or 2D data" if axes.size > 2
# 		self.outliers = []
		if axes.size == 1
			data = axes[:x].data
			i = 0
			loop do 
				break if i > data.size - 2
				should_be = (data[i+1] + data[i-1]) / 2.0
				deviation = (should_be - data[i]).abs / data[i].abs
				if deviation > outlier_tolerance
					data.delete_at(i)
					i-=1
				end
				i+=1
			end
		else
			x_data = axes[:x].data
			data = axes[:y].data
			i = 0
			loop do 
				jump = 1
				loop do 
					break if i > data.size - 1 - jump
					break unless x_data[i+jump] == x_data[i-jump]
					jump += 1
				end
				break if i > data.size - 1 - jump
				should_be = data[i-jump] + (data[i+jump] - data[i-jump]) / (x_data[i+jump] - x_data[i-jump]) * (x_data[i] - x_data[i-jump]) #ie y1 + gradient * delta x
				deviation = (should_be - data[i]).abs / data[i].abs
				if deviation > outlier_tolerance
					data.delete_at(i)
					x_data.delete_at(i)
					i-=1
				end
				i+=1
			end
		end
# 		p self.outliers
	end
	
# 	def exclude_outliers
# 		raise "Can only get rid of outliers for 1D or 2D data" if axes.size > 2
# # 		self.outliers = []
# 		if axes.size == 1
# 			outliers.sort.reverse_each do |index|
# 				axes[:x].data.delete_at(index)
# 			end
# 		else
# 			outliers.sort.reverse_each do |index|
# 				axes[:x].data.delete_at(index)
# 				axes[:y].data.delete_at(index)
# 			end
# 
# 		end
# 		check_integrity
# 	end

		
	
end


class AxisKit < KitHash
	
# 	include  Kit
	include Log
		AXES = GraphKit::AXES

	
# 	attr_accessor :labels, :ranges, :has_legend, :units, :dimensions
	
	def initialize(hash = {})
		super()
		self.title = ""
		self.units = ""
		self.
		absorb hash
	end
	
	def check_integrity
		check(['units.class', [String]], ['scaling.class', [Float, NilClass]], ['label.class', [String, NilClass]], ['title.class', [String]])
		check(['data.to_a.class', Array])
	end
	
	def dup
# 		puts 'i was called'
		new = self.class.new(self)
		new.data = data.dup
		new
	end
	
	def self.autocreate(hash)
		new_kit = new(hash)
		new_kit.label = "#{new_kit.title} (#{new_kit.units})"
		new_kit
	end
	
	def shape
		logf :shape
		if data.methods.include? :shape
			ans = data.shape
		elsif data.methods.include? :size
			ans = [data.size]
		elsif data.methods.include? :dimensions
			ans = data.dimensions
		else
			raise 'data does not implement size or shape or dimensions methods'
		end
		logfc :shape
		return ans
	end
# 	def data_for_gnuplot(rank)
# 		case rank
# 		when 0, 1
# 			return data
# 		when Fixnum
# 			if shape.size == 1
# 				return SparseTensor.diagonal(rank, data)
# 			else
# 				return data
# 			end
# 		else
# 			raise TypeError("Bad Rank")
# 		end
# 	end
		
	def extend_using(other)
		raise TypeError.new("Can only extend axes if data have the same ranks: #{shape.size}, #{other.shape.size}") unless shape.size == other.shape.size
		raise TypeError.new("Can only extend axes if data have the same class") unless data.class == other.data.class
		case shape.size
		when 1
			desired_length = shape[0] + other.shape[0]
			if data.methods.include? :connect
				self.data = data.connect(other.data)
			elsif data.methods.include? "+".to_sym
				data += other
			else
				raise TypeError("Extending this type of data is currently not implemented.")
			end
			raise "Something went wrong: the length of the extended data #{shape[0]} is not the sum of the lengths of the two original pieces of data #{desired_length}." unless shape[0] == desired_length
		else
			raise TypeError("Extending data with this rank: #{shape.size} is currently not implemented.")
		end
	end
				
end

end # class GraphKit

require 'graphkit/gnuplot.rb'
require 'graphkit/mm.rb'
require 'graphkit/csv.rb'
require 'graphkit/vtk_legacy_ruby.rb'
# end #class CodeRunner


if $0 == __FILE__


end

	
# A graph kit is 'everything you need..
#A graph kit is, in fact, a very intelligent hash
