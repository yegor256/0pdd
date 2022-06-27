# Copyright (c) 2016-2022 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative './zero_vector'
require_relative './functions/rastrigin'

# rubocop:disable Metrics/ParameterLists
module Pso
  #
  # PSO Solver
  #
  class Solver
    def initialize(
      din: 5,
      density: 50,
      f: Pso::Rastrigin,
      center: nil,
      radius: 5.12,
      method: :min_by,
      **options
    )
      begin
        @f = f.new
      rescue NoMethodError
        @f = f
      end
      @din = din
      @center = center
      @radius = radius
      @method = method
      @density = density
      @options = options

      generate_swarm
    end

    def generate_swarm
      Array.new(@density)
      @swarm = Array.new(@density) { generate_random_particle }
      @swarm_best = @swarm.map { |particle| [@f.f(particle, **@options), particle] }
      @swarm_speed = @swarm.map { generate_random_particle }
    end

    def generate_random_noise_particle
      @center.map { (rand * 2) - 1 }
    end

    def generate_random_particle
      @center + (generate_random_noise_particle * (@radius * rand))
    end

    def perfect_particle
      if @method == :min_by
        @swarm.min_by do |element|
          @f.f(element, **@options)
        end
      else
        @swarm.max_by do |element|
          @f.f(element, **@options)
        end
      end
    end

    def solve(precision: 100, threads: 1, debug: false)
      n_iterations = 0
      Array.new(threads).map do
        Thread.new do
          ((precision / @swarm.size) / threads).times do |_interation_number|
            n_iterations += 1
            (0...@density).each do |index|
              perfect = perfect_particle
              puts @f.f(perfect, **@options) if debug
              new_vector = normalize(interate(@swarm[index], @swarm_best[index].last, perfect, @swarm_speed[index]))
              if best?(@swarm_best[index].first, @f.f(new_vector, **@options))
                @swarm_best[index] = [@f.f(new_vector, **@options), new_vector]
              end
              @swarm_speed[index] = (new_vector - @swarm[index]).normalize
              @swarm[index] = new_vector
            end
          end
        end
      end.each(&:join)

      perfect = perfect_particle
      [@f.f(perfect, **@options), perfect, n_iterations]
    end

    private

    def best?(best, now)
      if @method == :min_by
        now < best
      else
        now > best
      end
    end

    def normalize(vector)
      return ((vector - @center).normalize * @radius) + @center if (vector - @center).magnitude > @radius
      vector
    end

    def interate(vector, best, perfect, speed)
      if vector == perfect
        out = generate_random_noise_particle
        new_vec = vector + ((best - vector).normalize * 0.2) + (out * rand * 0.05) + (speed * 0.05)
        minimal = @f.f(vector, **@options) > @f.f(new_vec, **@options)
        return minimal ? new_vec : vector if @method == :min_by
        return minimal ? vector : new_vec unless @method == :min_by
      end
      out = generate_random_noise_particle
      vector + (out * rand * 0.1) + ((best - vector).normalize * 0.5) + (perfect - vector).normalize + speed
    end
  end
end
# rubocop:enable Metrics/ParameterLists
