require 'matrix'
require 'stringio'
# Methods for writing graphkits to csv (comma separated value) files

  

class GraphKit




	

	def to_vtk_legacy_fast(options={})
		File.open(options[:file_name], 'w'){|file| file.puts to_vtk_legacy}
	end
	def to_vtk_legacy(options={})	
		check_integrity
		ep 'to_vtk_legacy'
		stringio = options[:io] || StringIO.new
    npoints = data.map{|dk| dk.vtk_legacy_size}.sum
		stringio << <<EOF
# vtk DataFile Version 3.0
vtk output
ASCII
DATASET UNSTRUCTURED_GRID
POINTS #{npoints} float
EOF
		data.each do |dk|
			dk.vtk_legacy_points(io: stringio)
			#stringio <<  "\n\n"
		end
		#ncells = data.map{|dk| dk.vtk_legacy_cells(action: :count)}.sum
		#ncell_elements = data.map{|dk| dk.vtk_legacy_cells(action: :count_elements)}.sum
		cellstring = ""
		pc = 0
		data.each do |dk|
			cellstring += dk.vtk_legacy_cells pointcount: pc
			pc += dk.vtk_legacy_size
			#stringio <<  "\n\n"
		end
		ncells = cellstring.count("\n")
		ncell_elements = cellstring.scan(/\s+/).size
		stringio << <<EOF

CELLS #{ncells} #{ncell_elements}
EOF
		stringio << cellstring
		stringio << <<EOF

CELL_TYPES #{ncells}
EOF
		data.each do |dk|
			dk.vtk_legacy_cell_types(io: stringio)
			#stringio <<  "\n\n"
		end
		stringio << <<EOF

POINT_DATA #{npoints} 
SCALARS myvals float
LOOKUP_TABLE default
EOF
		data.each do |dk|
			dk.vtk_legacy_point_data(io: stringio)
			#stringio <<  "\n\n"
		end
		return stringio.string unless options[:io]
	end
	

	class DataKit

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
		def vtk_legacy_size
			axs = self.axes.values_at(*AXES).compact
			return axs[-1].shape.product
		end
		def vtk_legacy_points(options={})
			io = options[:io] || StringIO.new
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
			when [1]
				dl.times do |n| 
					next unless dat[-1][n]
					dat.times.each{|idx| io << "0 " << idx << " #{dat[0][n]}"}
					io << "\n"
				end
			when [1,1]
				dl.times do |n| 
					next unless dat[-1][n]
					io << "0 " << dat[0][n] << ' ' << dat[1][n]
					#io << " " << edat.map{|e| e[n].to_s}.join(" ") if self.errors
					io << "\n"
				end
			when [1,1,1],[1,1,1,1]
				dl.times do |n| 
					next unless dat[-1][n]
					io << dat[0][n] << ' ' << dat[1][n] << ' ' << dat[2][n]
					io << "\n"
				end
			when [1,1,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[2][i,j]
						d = [dat[0][i], dat[1][j], dat[2][i,j]]
						io << d[0] << " " << d[1] << " " << d[2] << "\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [2,2,2], [2,2,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[2][i,j]
						d = [dat[0][i,j], dat[1][i,j], dat[2][i,j]]
						io << d[0] << " " << d[1] << " " << d[2] << "\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[3][i,j]
						d = [dat[0][i], dat[1][j], dat[2][i,j], dat[3][i,j]]
						io << d[0] << " " << d[1] << " " << d[2] << "\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,1,3]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						sh[-1][2].times do |k|
							next unless dat[3][i,j,k]

							d = [dat[0][i], dat[1][j], dat[2][k], dat[3][i,j,k]]
							io << d[0] << " " << d[1] << " " << d[2] << "\n"
						end
					end
				end
			#when [2,2,2,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[3][i,j]
						##d = [dat[0][i,j], dat[1][i,j], dat[2][i,j], dat[3][i,j]]
							#io << "#{dat[0][i,j]} #{dat[1][i,j]} #{dat[2][i,j]}\n"
						##d.each{|dt| io << dt << " "}
						##io << "\n"
					#end
				#end
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
							io << "#{dat[0][i,j,k]} #{dat[1][i,j,k]} #{dat[2][i,j,k]}\n"
							#d.each{|dt| io << dt << " "}
							#io << "\n"
						end
					end
				end
			end

		return io.string unless options[:io]
		end
		def vtk_legacy_point_data(options={})
			io = options[:io] || StringIO.new
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
					next unless dat[-1][n]
					#dat.each{|d| io << d[n] << " "}
					#io << " " << edat.map{|e| e[n].to_s}.join(" ") if self.errors
					io << "#{dat[3] ? dat[3][n] : 0}\n"
				end
			#when [1,1,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[2][i,j]
						#d = [dat[0][i], dat[1][j], dat[2][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
					#end
					##io << "\n" unless sh[-1][1] == 1
				#end
			when [1,1,2], [2,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[2][i,j]
						#d = [dat[0][i,j], dat[1][i,j], dat[2][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
						io << "0\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[3][i,j]
						#d = [dat[0][i], dat[1][j], dat[2][i,j], dat[3][i,j]]
						io <<  dat[3][i,j] << "\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,1,3]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						sh[-1][2].times do |k|
							next unless dat[3][i,j,k]

							#d = [dat[0][i], dat[1][j], dat[2][k], dat[3][i,j,k]]
							io <<  dat[3][i,j,k] << "\n"
						end
						#io << "\n" unless sh[-1][2] == 1
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [2,2,2,2]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[3][i,j]
							io << "#{dat[3][i,j]}\n"
					end
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
							io << "#{dat[3][i,j,k]}\n"
							#d.each{|dt| io << dt << " "}
							#io << "\n"
						end
						#io << "\n" unless sh[-1][2] == 1
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			end

		return io.string unless options[:io]
		end
		def vtk_legacy_cells(options={})
			pointcount = options[:pointcount]
			io = options[:io] || StringIO.new
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
				(dl-1).times do |n| 
					#dat.each{|d| io << d[n] << " "}
					#io << " " << edat.map{|e| e[n].to_s}.join(" ") if self.errors
					next unless dat[-1][n]
					io << "2 #{n + pointcount} #{n + pointcount + 1}" 
					io << "\n"
				end
			#when [1,1,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[2][i,j]
						#d = [dat[0][i], dat[1][j], dat[2][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			#when [2,2,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[2][i,j]
						#d = [dat[0][i,j], dat[1][i,j], dat[2][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			#when [1,1,2,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[3][i,j]
						#d = [dat[0][i], dat[1][j], dat[2][i,j], dat[3][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << ", " << d[3] << "\n"
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			#when [1,1,1,3]
				#ni, nj, nk = sh[-1]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#sh[-1][2].times do |k|
							#next unless dat[3][i,j,k]

							#d = [dat[0][i], dat[1][j], dat[2][k], dat[3][i,j,k]]
							#io << d[0] << ", " << d[1] << ", " << d[2] << ", " << d[3] << "\n"
						#end
						#io << "\n" unless sh[-1][2] == 1
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			when [1,1,2], [2,2,2], [1,1,2,2], [2,2,2,2]
				ni, nj = sh[-1]
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
							next unless (ni==1 or (i+1) < ni) and (nj==1 or (j+1) < nj)
							cell = [
								i*(nj) + j , 
								nj > 1 ? i*(nj) + (j+1) : nil, 
								ni > 1 ? (i+1)*(nj) + j : nil, 
								ni > 1 && nj > 1 ? (i+1)*(nj) + (j+1) : nil, 
							].compact.map{|pnt| pnt+pointcount}
							cell = [cell[0],cell[1],cell[3],cell[2]] if cell.size == 4
							io << cell.size << " " << cell.join(" ") << "\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,1,3],[3,3,3,3]
							#pp dat
							#pp dat
							#pp sh
				ni, nj, nk = sh[-1]
				#ep ni, nj, nk; gets
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						sh[-1][2].times do |k|
							next unless dat[3][i,j,k]
							#p [i,j,k]

							#d = [dat[0][i,j,k], dat[1][i,j,k], dat[2][i,j,k], dat[3][i,j,k]]
							#io << "#{dat[0][i,j,k]} #{dat[1][i,j,k]} #{dat[2][i,j,k]} #{dat[3][i,j,k]}\n"
							
							next unless (ni==1 or (i+1) < ni) and (nj==1 or (j+1) < nj) and (nk==1 or (k+1) < nk)
							cell = [
								i*(nj*nk) + j*nk + k, 
								nk > 1 ? i*(nj*nk) + j*nk + (k+1) : nil, 
								nj > 1 ? i*(nj*nk) + (j+1)*nk + (k) : nil, 
								nj > 1  && nk > 1 ? i*(nj*nk) + (j+1)*nk + (k+1) : nil, 
								ni > 1 ? (i+1)*(nj*nk) + j*nk + k : nil, 
								ni > 1 && nk > 1 ? (i+1)*(nj*nk) + j*nk + (k+1) : nil, 
								ni > 1 && nj > 1 ? (i+1)*(nj*nk) + (j+1)*nk + (k) : nil, 
								ni > 1 && nj > 1  && nk > 1 ? (i+1)*(nj*nk) + (j+1)*nk + (k+1) : nil, 
							].compact.map{|pnt| pnt+pointcount}
							cell = [cell[0],cell[1],cell[3],cell[2]] if cell.size == 4
							io << cell.size << " " << cell.join(" ") << "\n"
							 	
							#d.each{|dt| io << dt << " "}
							#io << "\n"
						end
						#io << "\n" unless sh[-1][2] == 1
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			end

		return io.string unless options[:io]
		end
		def vtk_legacy_cell_types(options={})
			pointcount = options[:pointcount]
			io = options[:io] || StringIO.new
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
				(dl-1).times do |n| 
					io << "3" # Lines
					io << "\n"
				end
			#when [1,1,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[2][i,j]
						#d = [dat[0][i], dat[1][j], dat[2][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			#when [2,2,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[2][i,j]
						#d = [dat[0][i,j], dat[1][i,j], dat[2][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			#when [1,1,2,2]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#next unless dat[3][i,j]
						#d = [dat[0][i], dat[1][j], dat[2][i,j], dat[3][i,j]]
						#io << d[0] << ", " << d[1] << ", " << d[2] << ", " << d[3] << "\n"
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			#when [1,1,1,3]
				#sh[-1][0].times do |i|
					#sh[-1][1].times do |j|
						#sh[-1][2].times do |k|
							#next unless dat[3][i,j,k]

							#d = [dat[0][i], dat[1][j], dat[2][k], dat[3][i,j,k]]
							#io << d[0] << ", " << d[1] << ", " << d[2] << ", " << d[3] << "\n"
						#end
						#io << "\n" unless sh[-1][2] == 1
					#end
					#io << "\n" unless sh[-1][1] == 1
				#end
			when [1,1,2], [2,2,2], [1,1,2,2], [2,2,2,2]
				ni, nj = sh[-1]
				type = case [ni > 1 ? 1 : nil, nj > 1 ? 1 : nil].compact.size
							 when 2
								 7 # Polygons see www.vtk.org/VTK/img/file-formats.pdf
							 when 1
								 3 # Lines
							 when 0
								 1 # Verteces
							 end
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						next unless dat[3][i,j]
							next unless (ni==1 or (i+1) < ni) and (nj==1 or (j+1) < nj)
							io << type << "\n"
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			when [1,1,1,3],[3,3,3,3]
							#pp dat
							#pp dat
							#pp sh
				ni, nj, nk = sh[-1]
				type = case [ni > 1 ? 1 : nil, nj > 1 ? 1 : nil, nk > 1 ? 1 : nil].compact.size
							 when 3
								 11 # 3D cells, see www.vtk.org/VTK/img/file-formats.pdf
							 when 2
								 7 # Polygons
							 when 1
								 3 # Lines
							 when 0
								 1 # Verteces
							 end

				#ep ni, nj, nk; gets
				sh[-1][0].times do |i|
					sh[-1][1].times do |j|
						sh[-1][2].times do |k|
							next unless dat[3][i,j,k]
							#p [i,j,k]

							#d = [dat[0][i,j,k], dat[1][i,j,k], dat[2][i,j,k], dat[3][i,j,k]]
							#io << "#{dat[0][i,j,k]} #{dat[1][i,j,k]} #{dat[2][i,j,k]} #{dat[3][i,j,k]}\n"
							
							next unless (ni==1 or (i+1) < ni) and (nj==1 or (j+1) < nj) and (nk==1 or (k+1) < nk)
							io << type << "\n"
							 	
							#d.each{|dt| io << dt << " "}
							#io << "\n"
						end
						#io << "\n" unless sh[-1][2] == 1
					end
					#io << "\n" unless sh[-1][1] == 1
				end
			end

		return io.string unless options[:io]
		end
	end

	end
				
