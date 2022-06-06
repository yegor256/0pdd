require 'json'
require 'time'
require 'crack'
require_relative './predictor'
require_relative './storage'

#
# Linear Model
#
class LinearModel
  def initialize(repo, storage)
    @repo = repo
    settings = Sinatra::Application.settings
    @xml_storage = storage
    # need to create new storage object because previous storage object
    # is tightly coupled to xml artefact
    @storage = Storage.new(
      "#{@repo}.marshal",
      settings.config['s3']['weights'],
      settings.config['s3']['region'],
      settings.config['s3']['key'],
      settings.config['s3']['secret']
    )
  end

  def predict(puzzles)
    weights = @storage.load # load weights for repo from s3
    clf = Predictor.new(layers: [{ name: 'w1', shape: [10, 1] }, { name: 'w2', shape: [1, 1] }])
    if weights.nil?
      train(clf) # find weights for repo backlog of puzzles
      ranks = naive_rank(puzzles) # naive rank of puzzles in each repo
    else
      # get x and y data for puzzles
      samples, _labels = extract_features(puzzles)
      # x = [[0.1, 0.3, 0.8, 1, -0.2, -0.6], [1, -0.3, 0.5, 0, 0.2, -0.6], [0.3, 0.3, -0.9, -0.5, -1, 0.7]]
      # y = [1, 3, 2]
      ranks = clf.predict(weights, samples, true) # model rank of puzzles if weights are loaded
    end
    ranks.map(&:to_i)
  end

  private

  def get_features_labels(samples)
    x = samples.map do |_, s|
      [
        s['time_estimate'],
        s['n_characters'],
        s['level'],
        s['n_puzzles_before'],
        s['n_puzzles_after'],
        s['time_before'],
        s['time_after'],
        s['n_additions'],
        s['n_deletions']
      ].append(s['vectorized_description'])
    end
    y = samples.map { |s| s['closed'] ? Time.parse(s['closed']).to_i : Infinity }.with_index.sort.map(&:last)
    [x, y]
  end

  # depth first feature extraction
  def extract_features(puzzles, samples = {}, level = 1)
    puzzles.each do |puzzle|
      prev_puzzle = samples[samples.keys.last]
      time_before = 0
      unless prev_puzzle.nil?
        time_before = (Time.parse(prev_puzzle['closed']).to_i - Time.parse(prev_puzzle['time']).to_i) / 60 # in minutes

        unless prev_puzzle['time_after'].nil?
          time_after = (Time.parse(puzzle['closed']).to_i - Time.parse(puzzle['time']).to_i) / 60 # in minutes
          prev_puzzle['time_after'] = time_after
        end
      end
      n_characters = "#{puzzle['title'].gsub(/\s/, '')}#{puzzle['description'].gsub(/\s/, '')}".length
      samples[puzzle['id']] = {
        'time_estimate' => puzzle['estimate'].to_i,
        'n_characters' => n_characters,
        'level' => level,
        'n_puzzles_before' => samples.length,
        'n_puzzles_after' => puzzles.length - samples.length,
        'time_before' => time_before
      }.merge(puzzle)

      extract_features(puzzle['children']['puzzle'], samples, level + 1) unless puzzle['children'].nil?
    end
    get_features_labels(samples) if level == 1
  end

  def train(clf)
    # todo
    # 1. load xml tree for repo from storage.
    # 2. *if xml tree is empty, create new xml tree using _puzzles.
    # 3. *if xml tree is not empty, add _puzzles to xml tree.
    # 4. process puzzles in xml tree.
    # # Features (x)
    # #  1. get estimate for each puzzle
    # #  2. sum of characters in title and description
    # #  3. use breath first search to extract level of tree in puzzle or during insertion
    # #  4. number of puzzles before a puzzle in the tree
    # #  5. number of puzzles after a puzzle in the tree
    # #  6. time (in minutes - `closed - opened``) spend on solving the puzzle before the current puzzle
    # #  7. time (in minutes - `closed - opened``) spend on solving the puzzle after the current puzzle
    # #  8. number of additions in commits before current puzzle
    # #  9. number of deletions in commits before current puzzle
    # # 10. vectorized description + title. Using doc2vec with vector size 15 and window size 2.
    # # Labels (y)
    # # --- how to get labels ??????
    # 5. train model with x and y data.
    # 6. save model weights to s3.
    puzzles = @xml_storage.load
    Thread.new do
      # properly train model here and save weights to s3 for later
      puzzles = JSON.parse(Crack::XML.parse(puzzles.to_s).to_json)['puzzles']
      unless puzzles.nil?
        samples, labels = extract_features(puzzles['puzzle'])

        solver = Pso::Solver.new(f: clf, center: ZeroVector.zero(y[0].size), data: samples, true_order: labels)
        _rank, weights, _n_iterations = solver.solve
        @storage.save(weights)
      end
    end
  end

  def naive_rank(puzzles)
    estimates = puzzles.map { |puzzle| puzzle['estimate'].to_i || Infinity }
    estimates.map.with_index.sort.map(&:last)
  end
end

# ranks = LinearModel.new('repo1').predict(puzzles)
