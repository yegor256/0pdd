# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

class FakeLog
  attr_reader :tag, :title

  def exists(_)
    false
  end

  def put(tag, text)
    @title = text
    @tag = tag
  end

  def get(_tag); end

  def delete(_time, _tag); end

  def list(_since = Time.now.to_i)
    []
  end
end
