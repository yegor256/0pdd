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
    @xml_storage = storage
    # need to create new storage object because previous storage object
    # is tightly coupled to xml artefact
    settings = Sinatra::Application.settings
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
      ranks = clf.predict(weights, samples[0], true) # model rank of puzzles if weights are loaded
    end
    ranks.map(&:to_i)
  end

  private

  def replace_nil(arr, with = 0)
    arr.map { |x| x.nil? ? with : x }
  end

  def get_features_labels(samples)
    x = samples.map do |_, s|
      replace_nil([
        s['time_estimate'],
        s['n_characters'],
        s['level'],
        s['n_puzzles_before'],
        s['n_puzzles_after'],
        s['time_before'],
        s['time_after'],
        s['n_additions'],
        s['n_deletions']
      ].append(s['vectorized_description']))
    end
    y = samples.map { |_, s| s['closed'] ? Time.parse(s['closed']).to_i : 0 }.map.with_index.sort.map(&:last)
    [[x], [y]] # single backlog of puzzles
  end

  # depth first feature extraction
  def extract_features(puzzles, samples = {}, level = 1)
    puzzles.each do |puzzle|
      prev_puzzle = samples[samples.keys.last]
      time_before = 0
      unless prev_puzzle.nil?
        opened = Time.parse(prev_puzzle['time']).to_i
        closed = prev_puzzle['closed'] ? Time.parse(prev_puzzle['closed']).to_i : opened
        time_before = (closed - opened) / 60 # in minutes

        unless prev_puzzle['time_after'].nil?
          time_after = (Time.parse(puzzle['closed']).to_i - Time.parse(puzzle['time']).to_i) / 60 # in minutes
          prev_puzzle['time_after'] = time_after
        end
      end
      n_characters = puzzle['body'].gsub(/\s/, '').length
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
    puzzles = @xml_storage.load
    Thread.new do
      # properly train model here and save weights to s3 for later
      puzzles = JSON.parse(Crack::XML.parse(puzzles.to_s).to_json)['puzzles']
      unless puzzles.nil?
        samples, labels = extract_features(puzzles['puzzle'])

        solver = Pso::Solver.new(f: clf, center: ZeroVector.zero(samples[0][0].size), data: samples, true_order: labels)
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
