require 'helper'

class TestGraphkit < Test::Unit::TestCase

	def test_basic
	a = GraphKit.autocreate({x: {data: [1,3,5,6], units: 'feet', title: 'Height'}})
	#a.gnuplot
	#gets
	a.close
	a = GraphKit.autocreate({x: {data: [2, 5, 11, 22], units: 'years', title: 'Age'}, y: {data: [1,3,5,6], units: 'feet', title: 'Height'}})
	
	puts a.pretty_inspect
	
	p a.title
	p a.label
	p a.chox
	p a.xlabel
	p a.yunits
	
# 	a.gnuplot
# 	gets
# 	a.close 
	a.data[0].with = 'lp'
	datakit = a.data[0].dup
	datakit.axes[:y].data.map!{|value| value * 0.85}
	datakit.title += ' of women'
	a.data.push datakit
	a.data[0].title += ' of men'
	pp a
	#a.gnuplot
	#gets
	a.close
# 	Gnuplot.open{a.to_gnuplot}
	
	b = GraphKit.autocreate({x: {data: [2, 5, 11, 22], units: 'years', title: 'Age'}, y: {data: [1,3,5,6], units: 'feet', title: 'Height'}, z: {data: [2,4,8,12], units: 'stone', title: 'Weight'}})
	b.data[0].modify({with: 'lp'})
	pp b
# 	d = b.data[0].f.data_for_gnuplot(2)
# 	p d
# 	p d[0,1]
# 	d.delete([0,0])
# 	p d
# 	p d[1,1]
# 	p d[1,2]
# 	d = SparseTensor.new(3)
# 	p d
# 	p d[0,1,4]
# 	p d[3, 4,6]
# 
	#b.gnuplot	
	#gets
	b.close
	b.gnuplot_write('heights.ps')
	
	p b.data[0].plot_area_size
	
	c = SparseTensor.new(3)
	c[1,3,9]= 4
	c[3,3,34] = 4.346
	c[23, 234, 293] = 9.234
	
	p c
	
	d = SparseTensor.new(3)
	d[1,3,9]= 4
	d[3,3,34] = 4.346
	d[23, 234, 294] = 9.234
	
	p c + d

	multiplot = GraphKit::MultiWindow.new
	multiplot.push a
	multiplot.push b
	 

	pp multiplot

	#multiplot.gnuplot
	multiplot.gnuplot_write('multiplot.ps')
	end

end
