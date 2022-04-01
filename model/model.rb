#!/usr/bin/env ruby

require_relative 'nn'

DATA_FNAME = File.join(File.dirname(__FILE__), 'data/proper_pdd_data_regression.csv')
rows = File.readlines(DATA_FNAME).map {|l| l.chomp.split(',') }
rows.slice!(0) # remove header of csv file
rows = rows.transpose[1..].transpose # drop first column containing repo id
rows.shuffle! # shuffle data

n = rows.length
x_data = rows.map { |row| row[0..-2].map(&:to_f) } # array of array of numeric values
y_data = rows.map { |row| row[-1..].map(&:to_f) } # array of array of numeric values

# split training and test data
train_test_split = 0.8 
train_size =  (train_test_split * x_data.length).round
x_train = x_data.slice(0, train_size)
y_train = y_data.slice(0, train_size)
x_test = x_data.slice(train_size, n)
y_test = y_data.slice(train_size, n)

# model hyperparameters and metrics
epsilon = 1e-1
mse = -> (actual, ideal) {
  errors = actual.zip(ideal).map {|a, i| a - i }
  (errors.inject(0) {|sum, err| sum += err**2}) / errors.length.to_f
}
error_rate = -> (errors, total) { ((errors / total.to_f) * 100).round }
prediction_success = -> (actual, ideal) { actual >= (ideal - epsilon) && actual <= (ideal + epsilon) }
run_test = -> (nn, inputs, expected_outputs) {
  success, failure, errsum = 0,0,0
  inputs.each.with_index do |input, i|
    output = nn.run input
    prediction_success.(output[0], expected_outputs[i][0]) ? success += 1 : failure += 1
    errsum += mse.(output, expected_outputs[i])
  end
  [success, failure, errsum / inputs.length.to_f]
}

# Build a 4 layer network: 31 input neurons, 4 hidden neurons, 3 output neurons
# Bias neurons are automatically added to input + hidden layers; no need to specify these
input_size = x_train.first.length
nn = NeuralNet.new [input_size,20,10,1]

WEIGHTS_FNAME = File.join(File.dirname(__FILE__), 'data/weights.marshal')
if File.file?(WEIGHTS_FNAME)
  puts "\nLoading existing model weights..."  
  nn.load WEIGHTS_FNAME
  puts "\nSuccessfully loaded model weights..."  
else
  puts "Testing the untrained network..."
  success, failure, avg_mse = run_test.(nn, x_test, y_test)
  puts "Untrained classification success: #{success}, failure: #{failure} (classification error: #{error_rate.(failure, x_test.length)}%, mse: #{(avg_mse * 100).round(2)}%)"

  puts "\nTraining the network...\n\n"
  t1 = Time.now
  result = nn.train(x_train, y_train, error_threshold: 0.01, 
                                      max_iterations: 1000,
                                      log_every: 20,
                                      )
  # puts result
  puts "\nDone training the network: #{result[:iterations]} iterations, #{(result[:error] * 100).round(2)}% mse, #{(Time.now - t1).round(1)}s"  
  puts "\nSaving the model weights..."  
  nn.save WEIGHTS_FNAME
  puts "\nSuccessfully saved model weights..."  
end

puts "\nTesting the trained network..."
success, failure, avg_mse = run_test.(nn, x_test, y_test)
puts "Trained classification success: #{success}, failure: #{failure} (classification error: #{error_rate.(failure, x_test.length)}%, mse: #{(avg_mse * 100).round(2)}%)"

