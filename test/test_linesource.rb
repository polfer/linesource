require 'helper'

class TestLinesource < Test::Unit::TestCase
  def setup
    @testlines = IO.readlines(__FILE__)
  end
  
  def test_single_file
    linenum = 0
    ls = LineSource.new(__FILE__)
    ls.each do |line|
      linenum += 1
      assert_equal(linenum, ls.linenum)
      assert_equal(@testlines.shift,line)
    end
  end
  
  def test_line_skip
    linenum = 4
    4.times { @testlines.shift }
    ls = LineSource.new( __FILE__, 4 )
    ls.each do |line|
      linenum += 1
      assert_equal(linenum, ls.linenum)
      assert_equal(line, @testlines.shift)
    end
  end
  
  def test_single_prefile_callback
    prefilehit = false
    progresscallback = lambda do |ls|
      assert_equal(__FILE__, ls.filename)
      prefilehit = true
    end
    ls = LineSource.new( __FILE__, 0, progresscallback )
    assert_equal( prefilehit, true )
  end

  def test_single_postfile_no_callback
    postfilehit = false
    progresscallback = lambda do |ls|
      assert_equal(__FILE__, ls.filename)
      postfilehit = true
    end
    ls = LineSource.new( __FILE__, 0, nil, progresscallback )
    assert_equal( postfilehit, false )
  end
  
  def test_single_postfile_callback
    postfilehit = false
    progresscallback = lambda do |ls|
      assert_equal(__FILE__, ls.filename)
      postfilehit = true
    end
    ls = LineSource.new( __FILE__, 0, nil, progresscallback )
    ls.each { |line| assert_equal(line, @testlines.shift) }
    assert_equal( postfilehit, true )
  end

end
