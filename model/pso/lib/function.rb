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
