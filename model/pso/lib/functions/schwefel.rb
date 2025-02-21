# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../function'
require_relative '../zero_vector'

module Pso
  #
  # Schwefel Objective Function
  #
  class Schwefel < Pso::Function
    def f(vector, **_options)
      alpha = 418.982887
      vector.map { |n| -n * Math.sin(Math.sqrt(n.to_f.abs)) }.sum + (alpha * vector.size)
    end
  end
end
