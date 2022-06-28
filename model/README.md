Puzzle Ranking (Linear ML Model)

###### Note: This is an opt-in feature

### Internals

The ML model is a linear model with PSO optimizer. The optimizer is used to train the model on puzzle data, the weights are stored and used to predict future puzzles.

Because of the time required, training is a non-blocking process, and puzzle prioritization uses a naive ranking approach based on puzzle estimate. Subsequent events use the linear model for prioritization.

The linear model is the external API for the model. It has one method `predict(...)` which accepts an array of puzzles in xml. The output of this model is an array of positional index of the input puzzles:

```ruby
# usage

rank = LinearModel.new(repo_name, storage).predict(puzzles)

# repo_name -> name of repository
# storage -> storage object (with defined interface)
# puzzles -> array of xml puzzles.
#
# rank -> array of positional index of ranked puzzles
```
