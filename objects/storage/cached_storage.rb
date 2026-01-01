# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# XML cached in a temporary file.
#
class CachedStorage
  def initialize(origin, file)
    @origin = origin
    @file = file
  end

  def load
    if File.exist?(@file)
      begin
        content = File.read(@file)
      rescue StandardError => e
        raise "Failed to read #{@file} due to #{e.cause.inspect}"
      end
      xml = Nokogiri::XML(content)
    else
      xml = @origin.load
      write(xml)
    end
    xml
  end

  def save(xml)
    FileUtils.rm_rf(@file)
    @origin.save(xml)
    write(xml.to_s)
  end

  private

  def write(xml)
    FileUtils.mkdir_p(File.dirname(@file))
    File.write(@file, xml)
  end
end
