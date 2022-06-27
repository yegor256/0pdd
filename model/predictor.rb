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

require_relative './pso/pso'

def argsort(arr)
  arr.map.with_index.sort.map(&:last)
end

def normalised_kendall_tau_distance(a, b)
  raise 'Both lists have to be of equal length' unless a.size == b.size
  a = argsort(a)
  b = argsort(b)
  combination = a.combination(2)
  disordered = 0
  combination.each do |i, j|
    is_disordered = (a[i] > a[j] && b[i] < b[j]) || (a[i] < a[j] && b[i] > b[j])
    disordered += 1 if is_disordered
  end
  n = a.size
  (2.0 * disordered.to_f) / (n * (n - 1.0))
end

def default_option_generator_linear(attribute_num)
  [
    { layers: [{ name: 'w1', shape: [attribute_num, 1] }, { name: 'w2', shape: [1, 1] }] },
    [attribute_num] + 1
  ]
end

#
# Linear Predictor Model
#
class Predictor
  def initialize(**options)
    @layers = {}
    @kendall_corr_history = []
    options[:layers].each do |layer|
      @layers["#{layer[:name]}_shape"] = layer[:shape]
    end
  end

  def f(weights, **options)
    data = options[:data]
    true_order = options[:true_order]
    kns = []
    (0...data.size).each do |i|
      x = data[i]
      y = true_order[i].first(x.size)
      preds = predict(weights, x)
      kn = normalised_kendall_tau_distance(preds, y)
      kns.append(kn)
    end
    kns.sum / kns.size # mean
  end

  def train(weights, data, true_order)
    ranks = predict(weights, data)
    normalised_kendall_tau_distance(ranks, true_order)
  end

  def predict(weights, data)
    ranks = []
    (0...data.size).each do |i|
      row = data[i]
      r = forward_one(weights, row)
      ranks.append(r)
    end
    ranks
  end

  def forward_one(weights, data)
    x = data.clone.map(&:clone).flatten
    w = weights.first(x.size)
    x = Vector[*x].dot(Vector[*w])
    w.map { |c| x += c }[0]
  end

  def kendall(weights, data, true_order)
    x = predict(weights, data)
    normalised_kendall_tau_distance(x, true_order)
  end
end
