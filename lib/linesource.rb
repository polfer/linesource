require 'stringio'
require 'zlib'

# Need to add documenation
# Need to have different versions of initialize
# Need to be able to pass in multiple patterns (an array of patterns)
# Needs to be a gem

class LineSource
  
  include Enumerable
  
  attr_reader :linenum
  
  def initialize( pattern, skiplines = 0, filenew = nil, filedone = nil )
    @skiplines = skiplines
    @filenames = Dir.glob(pattern).sort!.freeze
    @filenames.each { |fn| fn.freeze }
    @index = -1
    @content = nil
    @lastline = nil
    @filenew = filenew
    @filedone = filedone
    nextfile
  end

  def setfilenew( filenew )
    @filenew = filenew
  end
  
  def setfiledone( filedone )
    @filedone = filedone
  end

  def eof?
    @content ? @content.eof? : true
  end

  def close
    if @content
      @filedone.call(self) if @filedone
      @content.close
      @content = nil
    end
    @lastline = nil
    @index = -1
    @linenum = -1    
  end

  def nextfile
      begin
        if @content
          @filedone.call(self) if @filedone
          @content.close
          @content = nil
        end

        @linenum = @skiplines
        @index += 1 if @index < @filenames.length 
        if @filenames[@index] =~ /\.gz$/
          @content = Zlib::GzipReader.open(@filenames[@index])
        else
          @content = File.open(@filenames[@index],"r")
        end
        @skiplines.times do
          @content.gets
        end

        @filenew.call(self) if @filenew
      rescue
        if @index < @filenames.length
          puts "\nERROR! Could not open #{@filenames[@index]}... skipping file!"
          retry
        end
        nil
      else
        @filenames[@index]
      end
  end

  def gets
    @lastline = nil
    if @content
      while (!(@lastline = @content.gets) && nextfile) do
      end
      if @lastline
        @linenum += 1
        @lastline.freeze
      end
    end
    @lastline
  end
  
  def lastline
    @lastline
  end

  def filename
    @index >= 0 ? @filenames[@index] : nil
  end
  
  def filesize
    (@index >= 0 && @filenames[@index]) ? File.stat(@filenames[@index]).size : -1
  end
  
  def each
    while gets
      yield @lastline
    end
  end
  
end
