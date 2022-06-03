require 'json'
require_relative './predictor'
require_relative '../objects/storage/s3'

#
# Linear Model
#
class LinearModel
  def initialize(repo)
    @repo = repo
    settings = Sinatra::Application.settings
    # need to create new storage object because previous storage object
    # is tightly coupled to xml artefact
    @storage = S3.new(
      "#{@repo}.weights",
      settings.config['s3']['weights'],
      settings.config['s3']['region'],
      settings.config['s3']['key'],
      settings.config['s3']['secret']
    )
  end

  def predict(puzzles)
    weights = load_weights # load weights for repo from s3
    clf = Predictor.new(layers: [{ name: 'w1', shape: [10, 1] }, { name: 'w2', shape: [1, 1] }])

    if weights.nil?
      train(clf, puzzles) # find weights for repo backlog of puzzles
      ranks = naive_rank(puzzles) # naive rank of puzzles in each repo
    else
      # get x and y data for puzzles
      x = [[0.1, 0.3, 0.8, 1, -0.2, -0.6], [1, -0.3, 0.5, 0, 0.2, -0.6], [0.3, 0.3, -0.9, -0.5, -1, 0.7]]
      y = [1, 3, 2]
      ranks = clf.predict(weights, x, y, true) # model rank of puzzles if weights are loaded
    end
    ranks.map(&:to_i)
  end

  private

  def load_weights
    @storage.load
  end

  def save_weights(weights)
    @storage.save(weights)
  end

  def train(clf, _puzzles)
    Thread.new do
      # properly train model here and save weights to s3 for later
      features_path = File.join(File.dirname(__FILE__), 'data/X_example.json')
      x = JSON.parse(File.read(features_path))

      labels_path = File.join(File.dirname(__FILE__), 'data/Y_example.json')
      y = JSON.parse(File.read(labels_path))

      solver = Pso::Solver.new(f: clf, center: ZeroVector.zero(y[0].size), data: x, true_order: y)
      _rank, weights, _n_iterations = solver.solve
      save_weights(weights)
    end
  end

  def naive_rank(puzzles)
    estimates = puzzles.map { |puzzle| puzzle['estimate'].to_i || Infinity }
    estimates.map.with_index.sort.map(&:last)
  end
end

# ranks = LinearModel.new('repo1').predict(puzzles)
