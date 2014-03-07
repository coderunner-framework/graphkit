require 'matrix'
# Methods and variables for interacting with the gnuplot process.  Most of
# these methods are for sending data to a gnuplot process, not for reading from
# it.  Most of the methods are implemented as added methods to the built in 
# classes.

module Gnuplot

  # Trivial implementation of the which command that uses the PATH environment
  # variable to attempt to find the given application.  The application must
  # be executable and reside in one of the directories in the PATH environment
  # to be found.  The first match that is found will be returned.
  # 
  # bin [String] The name of the executable to search for.
  # 
  # Return the full path to the first match or nil if no match is found.
  # 
  def Gnuplot.which ( bin )
    return bin if File::executable? bin

    path = ENV['PATH'] # || ENV['WHAT_EVER_WINDOWS_PATH_VAR_IS']
    path.split(File::PATH_SEPARATOR).each do |dir|
      candidate = File::join dir, bin.strip
      return candidate if File::executable? candidate
    end

    # This is an implementation that works when the which command is
    # available.
    # 
    # IO.popen("which #{bin}") { |io| return io.readline.chomp }

    return nil
  end 

  # Find the path to the gnuplot executable.  The name of the executable can
  # be specified using the RB_GNUPLOT environment variable but will default to
  # the command 'gnuplot'.  
  # 
  # persist [bool] Add the persist flag to the gnuplot executable
  # 
  # Return the path to the gnuplot executable or nil if one cannot be found.
  def Gnuplot.gnuplot( persist = true )
    cmd = which( ENV['RB_GNUPLOT'] || 'gnuplot' )
		#cmd = "gnuplot"
    cmd += " -background white" 
    cmd += " -persist" if persist
    cmd
  end
    
  # Open a gnuplot process that exists in the current PATH.  If the persist
  # flag is true then the -persist flag is added to the command line.  The
  # path to the gnuplot executable is determined using the 'which' command. 
  #
  # See the gnuplot documentation for information on the persist flag.
  #
  # <b>todo</b> Add a method to pass the gnuplot path to the function.
  
  def Gnuplot.open( persist=true )
    cmd = Gnuplot.gnuplot( persist ) or raise 'gnuplot not found'
		#File.open(".gptemp#{Process.pid}", 'w'){|f| yield f}
		#system "#{cmd} .gptemp#{Process.pid}"
		#FileUtils.rm  ".gptemp#{Process.pid}"


		if $debug_gnuplot
			#raise "HEELOOE"
	  	yield(STDOUT)
		else
    	IO::popen( cmd, "w") { |io| yield io }
		end
  end 
    
  

end
  

class GraphKit

	GNUPLOT_DEFAULT_TERM=ENV['GRAPHKIT_TERM'] || "x11"
	GNUPLOT_DEFAULT_COLOURS = {0 => "#df0000", 1 => "#00df00", 2 => "#0000df", 3 => "#a000a0", 4 => "#0090a0", 5 => "#e59500", 6 => "#82c290", 7 => "#f76dba", 8 => "#c20f00", 9 => "#4f1099"}

	class GnuplotVariables < KitHash
		def apply(io)
			self.each do |var,val|
				ion << "#{var} = #{val}\n" if val
			end
		end
	end
class GnuplotSetOptions < KitHash
	alias :hash_key :key
	undef :key
    QUOTED = [ "title", "output", "xlabel", "ylabel", "zlabel", "x2label", "y2label", "z2label"  ]
	GNUPLOT_SETS = %w[    dgrid3d
		angles            arrow             autoscale         bars
    bmargin           border            boxwidth          cbdata
    cbdtics           cblabel           cbmtics           cbrange
    cbtics            clabel            clip              cntrparam
    colorbox          contour           data              datafile 
    date_specifiers   decimalsign                  dummy    
    encoding          fit               fontpath          format
    function          grid              hidden3d          historysize
    isosamples        key               label             lmargin
    loadpath          locale            log               logscale
    macros            mapping           margin            missing
    mouse             multiplot         mx2tics           mxtics
    my2tics           mytics            mztics            object
		nosurface
    offsets           origin            output            palette
    parametric        pm3d              pointsize         polar
    print             rmargin           rrange            samples
    size              style             surface           table
    term              terminal          termoption        tics
    ticscale          ticslevel         time_specifiers   timefmt
    timestamp         title             tmargin           trange
    urange            view              vrange            x2data
    x2dtics           x2label           x2mtics           x2range
    x2tics            x2zeroaxis        xdata             xdtics
    xlabel            xmtics            xrange            xtics
    xyplane           xzeroaxis         y2data            y2dtics
    y2label           y2mtics           y2range           y2tics
    y2zeroaxis        ydata             ydtics            ylabel
    ymtics            yrange            ytics             yzeroaxis
    zdata             zdtics            zero              zeroaxis
    zlabel            zmtics            zrange            ztics].map{|s| s.to_sym}
# 		p instance_methods.sort
		GNUPLOT_SETS.each do |opt|
			define_method(opt + "=".to_sym) do |str|
				check(["Class of #{str} supplied to #{opt}", str.class, [Array, String, FalseClass, NilClass]])
				self[opt] = str
			end
			define_method(opt) do
				self[opt]
			end
		end
			
		
		def []=(opt, val)
			raise "#{opt} is not a valid gnuplot set option" unless GNUPLOT_SETS.include? opt
			super
		end

		def apply(io)
			self.each do |var,val|
				next unless val
				if val == "unset"
 					#eputs "Unsetting #{var}"
					io << "unset #{var}\n"
					next
				end
	      if var.to_s == 'log_axis'
		      var = 'log'
	      end
				if val.kind_of? Array
					val.each do |vall|
           io << "set #{var} #{vall}\n" 
					end
				elsif QUOTED.include? var.to_s and not val =~ /^\s*'.*'/
					#ep "quoting #{var}: #{val}"
					io << "set #{var} '#{val}'\n" 
				else
					io << "set #{var} #{val}\n" 
				end
      end
			io << "set term #{GNUPLOT_DEFAULT_TERM}\n" unless self[:term]
		end
		

end



class GnuplotPlotOptions < KitHash
	QUOTED = ["title"]
	GNUPLOT_SETS = %w[ function using axes title with ].map{|s| s.to_sym}

#%w[    
		#acsplines         axes              bezier            binary
    #csplines          cumulative        datafile          errorbars
    #errorlines        every             example           frequency
    #index             iteration         kdensity          matrix
    #parametric        ranges            sbezier           smooth
    #special-filenames style             thru              title
    #unique            using             with].map{|s| s.to_sym}
# 		p instance_methods.sort
		GNUPLOT_SETS.each do |opt|
			define_method(opt + "=".to_sym) do |str|
				check(["Class of #{str} supplied to #{opt}", str.class, [Array, String, FalseClass, NilClass]])
				self[opt] = str
			end
			define_method(opt) do
				self[opt]
			end
		end
			
		
		def []=(opt, val)
			raise "#{opt} is not a valid gnuplot set option" unless GNUPLOT_SETS.include? opt
			super
		end
		def apply(io)
				self[:function] ||= "'-'"
				GNUPLOT_SETS.each do |var|
					val = send(var)
					next unless val
					case var
					when :function
						io << " #{val} "
					when :title
						io << "#{var} '#{val}'"
					else
						if QUOTED.include? var.to_s and not val =~ Regexp.quoted_string
							io << "#{var} '#{val}' "
						else
							io << "#{var} #{val} "
						end
					end
				end

		end
end

	
	def gnuplot_sets
		# gnuplot_options included for back. comp
		self[:gnuplot_sets] ||= @gnuplot_options || GnuplotSetOptions.new
		self[:gnuplot_sets]
	end
	alias :gp :gnuplot_sets

	def gnuplot_variables
		@gnuplot_variables ||= GnuplotVariables.new
	end
	alias :gv :gnuplot_variables

	# Modify the graphkit according to the options hash

	def apply_gnuplot_options(options)
		options = options.dup # No reason to modify the original hash
		logf :gnuplot
		processes = %x[ps | grep 'gnuplot'].scan(/^\s*\d+/).map{|match| match.to_i}
		if options[:outlier_tolerance]
			raise "Can only get rid of outliers for 1D or 2D data" if naxes > 2
			data.each do |datakit|
				datakit.outlier_tolerance = options[:outlier_tolerance]
# 				datakit.calculate_outliers
				datakit.exclude_outliers
			end
			options.delete(:outlier_tolerance)
		end
		self.live = options[:live]
		options.delete(:live) if live
		if (self.view =~ /map/ or self.pm3d =~ /map/) and naxes < 4
			self.cbrange ||= self.zrange
			options[:cbrange] ||= options[:zrange] if options[:zrange]
		end
		if options[:eval]
			eval(options[:eval])
			options.delete(:eval)
		end
		options.each   do |k,v|
# 						ep option, val if option == :xrange

					# 					ep k, v
					set(k, v)
		end
	end

	def apply_graphkit_standard_options_to_gnuplot
		[:label, :range].each do |property|
			(AXES - [:f]).each do |axis|
				option = axis + property
				val = self.send(option)		
				if val
					if property == :range
						val = "[#{val[0]}:#{val[1]}]"
					end
					gp.set(option, val) 
				end
			end
		end
		[:title].each do |option|
				val = send(option)
				gp.set(option, val) if val
		end
	end

	private :apply_graphkit_standard_options_to_gnuplot

	def gnuplot(options={})	
		apply_gnuplot_options(options)
		apply_graphkit_standard_options_to_gnuplot
		check_integrity
		Gnuplot.open(true) do |io|
				self.pid = io.pid
				gnuplot_sets.apply(io)
				gnuplot_variables.apply(io)
				case naxes
				when 1,2
					io << "plot "
				when 3,4
					io << "splot "
				end
				imax = data.size - 1
				data.each_with_index do |dk,i|
					next if i>0 and compress_datakits
					dk.gnuplot_plot_options.with ||= dk.with #b.c.
					dk.gnuplot_plot_options.title ||= dk.title #b.c.
					dk.gnuplot_plot_options.apply(io)
					#p 'imax', imax, i, i == imax
					next if compress_datakits
					io << ", " unless i == imax
				end
				io << "\n"
				data.each_with_index do |dk,i|
					dk.gnuplot(io)
					 unless compress_datakits and i<imax
						io << "e\n\n"
					 else
						 io << "\n\n"
					 end
				end
				(STDIN.gets) if live
		end
	end
	
	def close
		logf :close
		begin
			Process.kill('TERM', pid) if pid
		rescue => err
			puts err
		end
		self.pid = nil
	end


	class DataKit
		def gnuplot_plot_options
			self[:gnuplot_plot_options] ||= GnuplotPlotOptions.new
		end
		alias :gp :gnuplot_plot_options

		class TensorArray 
			def initialize(arr)
				@arr=arr
			end
			def [](*args)
				args.reverse.inject(@arr) do |arr,idx|
					arr[idx]
				end
			end
		end
		def gnuplot(io)
			axs = self.axes.values_at(*AXES).compact
			#ep 'axs', axs
			dl = data_length = axs[-1].shape.product
			dat = axs.map{|ax| ax.data}
			sh = shapes
			cml_sh = sh.map do |sh|
				cml = 1
				sh.reverse.map{|dim| cml *= dim; cml}.reverse
			end
			dat = dat.map do |d|
			 d.kind_of?(Array) ? TensorArray.new(d) : d
			end
					
			if self.errors
				raise "Errors can only be plotted for 1D or 2D data" unless ranks == [1] or ranks == [1,1]
				edat = self.errors.values_at(:x, :xmin, :xmax, :y, :ymin, :ymax).compact
				#ep 'edat', edat
			end
			case ranks
			when [1], [1,1], [1,1,1], [1,1,1,1]
				dl.times do |n| 
					dat.each{|d| io << d[n] << " "}
					io << " " << edat.map{|e| e[n].to_s}.join(" ") if self.errors
					io << "\n"
				end
			when [1,1,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[2][i,j]
						d = [dat[0][i], dat[1][j], dat[2][i,j]]
						d.each{|dt| io << dt << " "}
						io << "\n"
					end
					io << "\n" unless sh[-1][1] == 1
				end
			when [2,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[2][i,j]
						d = [dat[0][i,j], dat[1][i,j], dat[2][i,j]]
						d.each{|dt| io << dt << " "}
						io << "\n"
					end
					io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[3][i,j]
						d = [dat[0][i], dat[1][j], dat[2][i,j], dat[3][i,j]]
						d.each{|dt| io << dt << " "}
						io << "\n"
					end
					io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,1,3]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						sh[-1][2].times do |k|
							next unless dat[3][i,j,k]

							d = [dat[0][i], dat[1][j], dat[2][k], dat[3][i,j,k]]
							d.each{|dt| io << dt << " "}
							io << "\n"
						end
						io << "\n" unless sh[-1][2] == 1
					end
					io << "\n" unless sh[-1][1] == 1
				end
			when [2,2,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[3][i,j]
						d = [dat[0][i,j], dat[1][i,j], dat[2][i,j], dat[3][i,j]]
						d.each{|dt| io << dt << " "}
						io << "\n"
					end
					io << "\n" unless sh[-1][1] == 1
				end
			when [3,3,3,3]
							#pp dat
							#pp dat
							#pp sh
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						sh[-1][2].times do |k|
							next unless dat[3][i,j,k]
							#p [i,j,k]

							#d = [dat[0][i,j,k], dat[1][i,j,k], dat[2][i,j,k], dat[3][i,j,k]]
							io << "#{dat[0][i,j,k]} #{dat[1][i,j,k]} #{dat[2][i,j,k]} #{dat[3][i,j,k]} \n"
							#d.each{|dt| io << dt << " "}
							#io << "\n"
						end
						io << "\n" unless sh[-1][2] == 1
					end
					io << "\n" unless sh[-1][1] == 1
				end
			end

		end
	end
										

									 		
	def gnuplot_write(file_name, options={})
		logf :gnuplot_write
		if file_name
			gp.output = file_name
			unless gp.term or options[:terminal]
				case File.extname(file_name)
				when '.pdf'
					gp.term = 'pdf size 20cm,15cm'
				when '.ps'
					gp.term = 'post color'
				when '.eps'
					unless options[:latex]
						gp.term = %[post eps color enhanced size  #{options[:size] or "3.5in,2.33in"}]
					else
						gp.term ||= "epslatex color dashed size #{options[:size] or "3.5in,#{options[:height] or "2.0in"}"} colortext standalone 8"
						(gp.term += " header '#{options[:preamble].inspect.gsub(/\\\n/, "\\\\\\n")}'"; options.delete(:preamble)) if options[:preamble]
					end
				when '.jpg'
					gp.term = "jpeg size  #{options[:size] or "3.5in,2.33in"}"
				when '.png'
					gp.term = "png size  #{options[:size] or "640,480"}"
				when '.gif'
					gp.term = "gif size  #{options[:size] or "640,480"}"
				
				end
			end
		end
		
		gp.output = file_name.sub(/\.eps/, '.tex') if options[:latex]
		options.delete(:size)
		gnuplot(options)
		if options[:latex]
				name = file_name.sub(/\.eps$/, '')
				raise "No file output by gnuplot" unless FileTest.exist? name + '.tex'
				raise 'latex failed' unless system "latex #{name}.tex --interaction nonstopmode --halt-on-error -q"
				raise 'dvips failed' unless system "dvips #{name}.dvi"
				FileUtils.rm "#{name}.eps" if FileTest.exist? "#{name}.eps"
				raise 'ps2eps failed' unless system "ps2eps #{name}.ps"
		end
# 		ep file_name
		return File.basename(file_name, File.extname(file_name))
	end
	
	def self.latex_multiplot(name, options={})
		name = name.sub(/\.eps$/, '')
		figure_preamble = options[:preamble] || <<EOF
\\documentclass[graphicx,reprint,twocolumn]{revtex4}
%\documentclass[aip,reprint]{revtex4-1}
\\usepackage{graphics,bm,overpic,color}
\\usepackage[tight]{subfigure}

\\pagestyle{empty}
\\begin{document}
\\begin{figure}
EOF

		figure_postamble = options[:postamble] || <<EOF
\\end{figure}
\\end{document}
EOF
		text = <<EOF
#{figure_preamble}
#{yield}
#{figure_postamble}
EOF
			File.open("#{name}.tex", 'w'){|f| f.puts text}
		raise 'latex failed'  unless system "latex #{name}.tex"
		raise 'dvips failed' unless system "dvips #{name}.dvi"
		FileUtils.rm "#{name}.eps" if FileTest.exist? "#{name}.eps"
		raise 'ps2eps failed' unless system "ps2eps #{name}.ps"
	end





	end
				
