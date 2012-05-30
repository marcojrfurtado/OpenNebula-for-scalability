#!/usr/bin/ruby


class LinearRegression
  attr_accessor :slope, :offset

  def initialize file_dx, dy=nil

    dx = []
    # Check whether a data file was passed or an array.
    if file_dx.is_a? String
        begin
            fp = File.open(file_dx,"r")
        rescue Exception => e
            OpenDC.log_error "Couldn't open data file for Linear Regression: " + e.message
            raise e
        end
        dy = []
        fp.each_line { |line|
            point= line.split
            dx <<  point[0].to_f
            dy << point[1].to_f
        }
    else
        dx = file_dx
    end

    @size = dx.size
    dy,dx = dx,axis() unless dy  # make 2D if given 1D
    raise "arguments not same length!" unless @size == dy.size
    sxx = sxy = sx = sy = 0
    dx.zip(dy).each do |x,y|
      sxy += x*y
      sxx += x*x
      sx  += x
      sy  += y
    end
    @slope = ( @size * sxy - sx*sy ) / ( @size * sxx - sx * sx )
    @offset = (sy - @slope*sx) / @size
  end

  def fit
    return axis.map{|data| predict(data) }
  end

  def predict( x )
    y = @slope * x + @offset
  end

  def axis
    (0...@size).to_a
  end
end


