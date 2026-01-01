# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'matrix'

module Pso
  #
  # General Objective Function Interface
  #
  class Function
    def f(vector, **_options)
      vector.magnitude
    end
  end
end
