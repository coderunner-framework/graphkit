class GraphKit
	# Convert graphkit into a string which can be used by Mathematica
	def to_mathematica
		str = ""
		case data[0].ranks
		when [1], [1, 1]
			str = "ListPlot[{#{data.map{|dk| dk.to_mathematica}.join(',')}}"


		end
		pas = plot_area_size
		if (xrange or yrange or zrange)
			str << ", PlotRange -> "
			str << "{#{((0...naxes).to_a.map do |nax| 
				ax = AXES[nax]
				specified_range = (send(ax + :range) or [nil, nil])
				"{#{specified_range.zip(pas[nax]).map{|spec, pasr| (spec or pasr).to_s}.join(',')}}"
			end).join(',')}}"
		end
		str << ", PlotStyle -> {#{(data.size.times.map do |i|
			((data[i].mtm.plot_style) or "{}")
		end).join(',')}}"

		str << "]"

	end

	class DataKit
		class MathematicaOptions < KitHash
		end
		def mtm
			self[:mtm] ||= MathematicaOptions.new
		end
		def to_mathematica
			case ranks
			when [1], [1,1], [1, 1, 1]
				"{#{(axes.values.map{|ax| ax.data.to_a}.transpose.map do |datapoint|
						"{#{datapoint.map{|coord| coord.to_s}.join(',')}}"
				end).join(',')}}"
			end
		end
	end
end
