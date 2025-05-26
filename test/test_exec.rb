# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/exec'
require_relative '../objects/user_error'

# Exec test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestExec < Minitest::Test
  def test_simple_bash_call
    assert(Exec.new('echo 123').run.start_with?("123\n"))
  end

  def test_hides_stderr
    assert(Exec.new('set +x; echo hello').run.start_with?('hello'))
  end

  def test_bash_failure
    assert_raises Exec::Error do
      Exec.new('how_are_you').run
    end
  end

  def test_failures_with_user_error
    error = assert_raises Exec::Error do
      Exec.new('exit 1').run
    end
    assert_equal(1, error.code)
  end
end
