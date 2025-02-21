# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

SimpleCov.formatter = if Gem.win_platform?
  SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter
  ]
else
  SimpleCov::Formatter::MultiFormatter.new(
    SimpleCov::Formatter::HTMLFormatter
  )
end

SimpleCov.start do
  add_filter '/test/'
  add_filter '/test-assets/'
  add_filter '/features/'
  add_filter '/assets/'
  add_filter '/dynamodb-local/'
  add_filter '/public/'
  minimum_coverage 34
end
