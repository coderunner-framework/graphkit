require 'matrix'
# Methods for writing graphkits to csv (comma separated value) files

class GraphKit
  def to_csv(options={})	
    check_integrity
    ep 'to_csv'
    stringio = options[:io] || StringIO.new
    data.each do |dk|
      dk.to_csv(options)
      stringio <<  "\n\n"
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
    def to_csv(options={})
      io = options[:io] || StringIO.new
      header = options[:header].to_s
      csv_file = File.open(io, 'w')
      if header
        csv_file.write(header + "\n")
      end

      axs = self.axes.values_at(*AXES).compact
      #ep 'axs', axs
      dl = axs[-1].shape.product
      dat = axs.map{|ax| ax.data}
      sh = shapes
      #cml_sh = sh.map do |sh1|
      #  cml = 1
      #  sh1.reverse.map{|dim| cml *= dim; cml}.reverse
      #end
      dat = dat.map do |d|
        d.kind_of?(Array) ? TensorArray.new(d) : d
      end

      if self.errors
        raise "Errors can only be plotted for 1D or 2D data" unless ranks == [1] or ranks == [1,1]
        edat = self.errors.values_at(:x, :xmin, :xmax, :y, :ymin, :ymax).compact
        #ep 'edat', edat
      end

      io = ''
      case ranks
      when [1], [1,1], [1,1,1], [1,1,1,1]
        dl.times do |n| 
          dat.each{|d| io << d[n].to_s << ","}
          io << " " << edat.map{|e| e[n].to_s}.join(", ") if self.errors
          io << "\n"
        end
      when [1,1,2]
        sh[-1][0].times do |i|
          sh[-1][1].times do |j|
            next unless dat[2][i,j]
            d = [dat[0][i], dat[1][j], dat[2][i,j]]
            io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
          end
          io << "\n" unless sh[-1][1] == 1
        end
      when [2,2,2]
        sh[-1][0].times do |i|
          sh[-1][1].times do |j|
            next unless dat[2][i,j]
            d = [dat[0][i,j], dat[1][i,j], dat[2][i,j]]
            io << d[0] << ", " << d[1] << ", " << d[2] << "\n"
          end
          io << "\n" unless sh[-1][1] == 1
        end
      when [1,1,2,2]
        sh[-1][0].times do |i|
          sh[-1][1].times do |j|
            next unless dat[3][i,j]
            d = [dat[0][i], dat[1][j], dat[2][i,j], dat[3][i,j]]
            io << d[0] << ", " << d[1] << ", " << d[2] << ", " << d[3] << "\n"
          end
          io << "\n" unless sh[-1][1] == 1
        end
      when [1,1,1,3]
        sh[-1][0].times do |i|
          sh[-1][1].times do |j|
            sh[-1][2].times do |k|
              next unless dat[3][i,j,k]

              d = [dat[0][i], dat[1][j], dat[2][k], dat[3][i,j,k]]
              io << d[0] << ", " << d[1] << ", " << d[2] << ", " << d[3] << "\n"
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
              io << "#{dat[0][i,j,k]},#{dat[1][i,j,k]},#{dat[2][i,j,k]},#{dat[3][i,j,k]}\n"
              #d.each{|dt| io << dt << " "}
              #io << "\n"
            end
            io << "\n" unless sh[-1][2] == 1
          end
          io << "\n" unless sh[-1][1] == 1
        end
      end

      return stringio.string unless options[:io]
      
      csv_file.write(io)
      csv_file.close()
    end
  end
end
