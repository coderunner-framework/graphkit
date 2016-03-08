require 'helper'

class TestGraphkit < Minitest::Unit::TestCase

  def setup
    FileUtils.makedirs('test/test_output')
  end

  def test_basic
    a = GraphKit.autocreate({x: {data: [2, 5, 11, 22],
                                 units: 'years',
                                 title: 'Age'},
                             y: {data: [1,3,5,6],
                                 units: 'feet',
                                 title: 'Height'}})

    b = GraphKit.autocreate({x: {data: [2, 5, 11, 22],
                                 units: 'years',
                                 title: 'Age'},
                             y: {data: [1,3,5,6],
                                 units: 'feet',
                                 title: 'Height'},
                             z: {data: [2,4,8,12],
                                 units: 'stone',
                                 title: 'Weight'}})
    b.data[0].modify({with: 'lp'})

    b.close
    b.gnuplot_write('test/test_output/heights.ps')

    c = SparseTensor.new(3)
    c[1,3,9]= 4
    c[3,3,34] = 4.346
    c[23, 234, 293] = 9.234

    d = SparseTensor.new(3)
    d[1,3,9]= 4
    d[3,3,34] = 4.346
    d[23, 234, 294] = 9.234

    multiplot = GraphKit::MultiWindow.new
    multiplot.push a
    multiplot.push b

    multiplot2 = GraphKit::MultiKit.new([GraphKit.quick_create([[0,3], [2,4]])])
    multiplot.merge(multiplot2)

    assert_equal(GraphKit::MultiKit, eval(multiplot.inspect).class )

    multiplot.gnuplot_write('test/test_output/multiplot.ps', multiplot: 'layout 2,2')
  end

  def teardown
    FileUtils.rm_r('test/test_output')
  end
end
