require 'slop'
require 'rainbow'
require 'active_support/core_ext/hash'
require 'nokogiri'
require_relative 'nn'

DATA_FNAME = File.join(File.dirname(__FILE__), 'data/proper_pdd_data_regression.csv')
WEIGHTS_FNAME = File.join(File.dirname(__FILE__), 'data/weights.marshal')

def split_data(x_data, y_data)
  n = x_data.length
  train_test_split = 0.8 # split training and test data
  train_size = (train_test_split * x_data.length).round
  x_train = x_data.slice(0, train_size)
  y_train = y_data.slice(0, train_size)
  x_test = x_data.slice(train_size, n)
  y_test = y_data.slice(train_size, n)
  [x_train, y_train, x_test, y_test]
end

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def run_model(inputs)
  rows = File.readlines(DATA_FNAME).map { |l| l.chomp.split(',') }
  rows.slice!(0) # remove header of csv file
  rows = rows.transpose[1..].transpose # drop first column containing repo id
  rows.shuffle! # shuffle data
  x_data = rows.map { |row| row[0..-2].map(&:to_f) } # array of array of numeric values
  y_data = rows.map { |row| row[-1..].map(&:to_f) } # array of array of numeric values
  x_train, y_train, x_test, y_test = split_data(x_data, y_data)
  epsilon = 1e-1 # model hyperparameters and metrics
  mse = lambda(actual, ideal) {
    errors = actual.zip(ideal).map { |a, i| a - i }
    (errors.inject(0) { |sum, err| sum + err**2 }) / errors.length.to_f
  }
  error_rate = lambda(errors, total) { ((errors / total.to_f) * 100).round }
  prediction_success = lambda(actual, ideal) { actual >= (ideal - epsilon) && actual <= (ideal + epsilon) }
  run_test = lambda(nn, test_inputs, expected_outputs) {
    success = 0
    failure = 0
    errsum = 0
    test_inputs.each.with_index do |input, i|
      output = nn.run input
      prediction_success.call(output[0], expected_outputs[i][0]) ? success += 1 : failure += 1
      errsum += mse.call(output, expected_outputs[i])
    end
    [success, failure, errsum / test_inputs.length.to_f]
  }

  # Build a 4 layer network: 31 input neurons, 4 hidden neurons, 3 output neurons
  # Bias neurons are automatically added to input + hidden layers; no need to specify these
  input_size = x_train.first.length
  nn = NeuralNet.new [input_size, 20, 10, 1]

  if File.file?(WEIGHTS_FNAME)
    puts "\nLoading existing model weights..."
    nn.load WEIGHTS_FNAME
    puts "\nSuccessfully loaded model weights..."
  else
    puts 'Testing the untrained network...'
    success, failure, avg_mse = run_test.call(nn, x_test, y_test)
    puts "Untrained classification success: #{success}, failure: #{failure}
     (classification error: #{error_rate.call(failure, x_test.length)}%, mse: #{(avg_mse * 100).round(2)}%)"

    puts "\nTraining the network...\n\n"
    t1 = Time.now
    result = nn.train(x_train, y_train, error_threshold: 0.01,
                                        max_iterations: 1000,
                                        log_every: 20)
    # puts result
    puts "\nDone training the network: #{result[:iterations]} iterations,
     #{(result[:error] * 100).round(2)}% mse, #{(Time.now - t1).round(1)}s"
    puts "\nSaving the model weights..."
    nn.save WEIGHTS_FNAME
    puts "\nSuccessfully saved model weights..."
  end

  puts "\nTesting the trained network..."
  success, failure, avg_mse = run_test.call(nn, x_test, y_test)
  puts "Trained classification success: #{success}, failure: #{failure}
   (classification error: #{error_rate.call(failure, x_test.length)}%, mse: #{(avg_mse * 100).round(2)}%)"

  estimates = inputs.map { |p| p['estimate'] || Infinity }
  rank_output = estimates.map.with_index.sort.map(&:last) # sort estimates from minimum to maximum
  rank_output
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

def process_input(input_path)
  throw 'Please provide a valid input path' unless input_path
  doc = Nokogiri::XML(File.read(input_path))
  puzzles = Hash.from_xml(doc.to_s)['puzzles']
  puzzles['puzzle'] || []
end

begin
  args = []
  args += ARGV

  begin
    opts = Slop.parse(args, strict: true, help: true) do |o|
      o.banner = 'Usage: model.rb [options]'
      o.string '-p', '--puzzles', 'Puzzles file'
      o.string '-f', '--file', 'Result file'
    end
  rescue Slop::Error => e
    raise StandardError, "#{e.message}, use -p and -f"
  end

  raise '-f is mandatory when using -v, try --help for more information' if !opts[:file] || !opts[:puzzles]

  ranks = run_model(process_input(opts[:puzzles]))
  File.open(opts[:file], 'w') { |f| f.write(ranks.join(' ')) }
  puts 'Successfully wrote output to file'
rescue StandardError => e
  puts "#{Rainbow('ERROR').red} (#{e.class.name}): #{e.message}"
  exit(255)
end
