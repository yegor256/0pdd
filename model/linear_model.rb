# require_relative './pso/solver'
require_relative './pso/pso.rb'

def argsort(arr)
    arr.map.with_index.sort.map(&:last)
end

def normalised_kendall_tau_distance(a, b)
    pairs = a.combination(2)
    # note that for each of those pairs, the position of
    # the second element in array `a` is subsequent to the position of the first.
    # (aka, if a = ['a', 'b', 'c'], value ['c','b'] cannot exist in `pairs`)

    # due to this observation we only need to index the positions of array `b`
    rank_b = b.each_with_index.to_h

    concordant = 0
    discordant = 0
    pairs.each do |v1, v2|
        is_discordant = rank_b[v1] > rank_b[v2]
        discordant += 1 if is_discordant
        concordant += 1 unless is_discordant
    end
    n = a.size
    (concordant - discordant).to_f / (n * (n - 1.0) / 2.0)
end

def default_option_generator_linear(attribute_num)
    [
      { 'layers': [{ 'name': 'w1', 'shape': [attribute_num, 1] }, { 'name': 'w2', 'shape': [1, 1] }] },
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

    def f(model_weights, **options)
        data = options[:data]
        true_order = options[:true_order]
        model_weights = model_weights.to_a
        kns = []
        # history_per_backlog = []
        (0...data.size).each do |i|
            x = data[i]
            y = true_order[i]
            preds = forward(model_weights, x, y)
            kn = normalised_kendall_tau_distance(preds, y)
            kns.append(kn)
        end
        kns.sum / kns.size # mean
    end

    def train(model_weights, data, true_order, debug = false)
        ranks = forward(model_weights, data, true_order, debug)
        normalised_kendall_tau_distance(ranks, true_order)
    end

    def forward(model_weights, data, true_order, debug = false)
        ranks = []
        puts data.size
        puts data
        (0...data.size).each do |i|
            row = data[i]
            r = forward_one(model_weights, row)
            ranks.append(r)
        end
        puts "Predicted Rank #{argsort(ranks)} -- True Order #{argsort(true_order)}" if debug
        ranks
    end

    def forward_one(model_weights, data)
        prev_sum = 0
        model_weights = model_weights.flatten
        x = data.flatten # fix issue here with ruby dot product
        pairs = @layers.to_a
        _key, shape = pairs[0]
        w = model_weights[prev_sum...(prev_sum + (shape[0] * shape[1]))].each_slice(shape[0]).to_a

        x = np.dot(x, w) # replace with ruby dot product
        _key, shape = pairs[1]
        w = model_weights[prev_sum...(prev_sum + (shape[0] * shape[1]))].each_slice(shape[0]).to_a
        x += w
        x
    end

    def kendall(model_weights, data, true_order, _full = true)
        x = forward(model_weights, data)
        normalised_kendall_tau_distance(x, true_order)
    end
end

# optimizer = ps.single.GlobalBestPSO(n_particles=400, dimensions=param_size, options=options)
# cost, pos = optimizer.optimize(p.train_full, iters=15,
#                                   data=X,
#                                   true_order=Y,
#                                   verbose=True)
# #  where X is the set of repositories and Y is the set of order of task solving, like [[1,2,3], [5,4,3,2,1]]

# for repo in repositories
#     predictions = p.forward(pos, x, y)
#     kn = normalised_kendall_tau_distance(predictions, y)
# # here x - a repo, and y - a order of task execution

clf = Predictor.new(layers: [{ name: 'w1', shape: [10, 1] }, { name: 'w2', shape: [1, 1] }])

data = [[0.1, 0.3, 0.8, 1, -0.2, -0.6], [1, -0.3, 0.5, 0, 0.2, -0.6], [0.3, 0.3, -0.9, -0.5, -1, 0.7]]
data = data.map { |d| ZeroVector[*d] }
solver = Pso::Solver.new(din: 10, f: clf, data: data, true_order: [1, 3, 2])

best = solver.solve

puts best
