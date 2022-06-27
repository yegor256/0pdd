Neural Net (in Ruby)

The data for puzzles is pre-processed and available in `~/data/proper_pdd_data_regression.csv`. In the data, The first row is the column index, the first column is the repo id the puzzle belongs to and the last column is the output variable (*y*)

The neural network model uses gradient descent to optimize the weights of the model. The weights are stored in `~/data/weights.marshal` after training and loaded for subsequent runs. To retrain the model, please delete `~/data/weights.marshal`.

Run the following command to train the model or test on random dataset:

```sh
$ ruby model/model.rb
```
