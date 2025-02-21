# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../function'
require_relative '../zero_vector'

module Pso
  #
  # Rastrigin Objective Function
  #
  class Rastrigin < Pso::Function
    def f(vector, **_options)
      fitness = 10 * vector.size
      fitness + vector.map { |n| (n**2) - (10 * Math.cos(2 * Math::PI * n)) }.sum
    end
  end
end
