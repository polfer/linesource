require 'stringio'
require 'zlib'

# The LineSource class is initialized with a pattern for files that
# need to be read and processed line by line.  For example, you could
# pass a pattern to all the log files in a date hierarchy ('**/*.log').
# Every line in every file will be read and the transition from file
# to file is handled automatically (with callbacks if desired).
class LineSource
  
  include Enumerable
  
  # Linenum represents the line number of the current file (1 based).
  attr_reader :linenum
  
  # Constructor can take a number of different options including
  # the pattern of files to be read (Dir.glob style).  The files can
  # be regular text files or gzipped files (detected through a .gz)
  # extension.  The skiplines parameter can be used to specify a certain
  # number of lines at the head of each file that should be skipped
  # (usually header files, for example on a csv file). The filenew
  # and filedone params represent a callback that can be fired at the
  # start or end of processing for each of the files that match pattern.
  # TODO: We should be able to pass multiple pattenrs to initialize.
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

  # Allows the prefile callback to be set after LineSource creation.
  def setfilenew( filenew )
    @filenew = filenew
  end
  
  # Allows the postfile callback to be set after LineSource creation.
  def setfiledone( filedone )
    @filedone = filedone
  end

  # Tests if the end of _all_ files in the original pattern are processed.
  def eof?
    @content ? @content.eof? : true
  end

  # Closes all files held open on the current LineSource.
  # Effectively ends the use of this LineSource.
  # TODO: We could make it so that a close is like a "reset".
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

  # Skips the current file being processed and sets to the next.
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

  # Returns an individual line from the LineSource.
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
  
  # Re-returns the last line fetched from a LineSource.
  def lastline
    @lastline
  end

  # Returns the name of the file currently being processed.
  def filename
    @index >= 0 ? @filenames[@index] : nil
  end
  
  # Returns the size of the file currently being processed.  Note
  # that in the case of a GZipped file this will be the compressed size.
  def filesize
    (@index >= 0 && @filenames[@index]) ? File.stat(@filenames[@index]).size : -1
  end
  
  # Calls a block of code for each line from the LineSource.
  def each
    while gets
      yield @lastline
    end
  end
  
end
