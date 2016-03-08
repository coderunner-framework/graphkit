require 'helper'

class TestGraphkit < Minitest::Unit::TestCase

  def setup
    FileUtils.makedirs('test/test_output')
  end

  def teardown
    FileUtils.rm_r('test/test_output')
  end

  def test_sparse_tensor_new
    t = SparseTensor.new(3)
    assert_equal(t.shape, [0,0,0])
    assert_equal(t.rank, 3)
  end

  def test_multiplot
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

    multiplot = GraphKit::MultiWindow.new
    multiplot.push a
    multiplot.push b

    multiplot2 = GraphKit::MultiKit.new([GraphKit.quick_create([[0,3], [2,4]])])
    multiplot.merge(multiplot2)

    assert_equal(GraphKit::MultiKit, eval(multiplot.inspect).class )

    multiplot.gnuplot_write('test/test_output/multiplot.ps', multiplot: 'layout 2,2')
  end

end
