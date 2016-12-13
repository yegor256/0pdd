<img src="https://avatars2.githubusercontent.com/u/24456188" width="64px" height="64px"/>

[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/0pdd)](http://www.rultor.com/p/yegor256/0pdd)
[![We recommend RubyMine](http://img.teamed.io/rubymine-recommend.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/0pdd.svg)](https://travis-ci.org/yegor256/0pdd)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/0pdd)](http://www.0pdd.com/p?name=yegor256/0pdd)
[![Dependency Status](https://gemnasium.com/yegor256/0pdd.svg)](https://gemnasium.com/yegor256/0pdd)
[![Code Climate](http://img.shields.io/codeclimate/github/yegor256/0pdd.svg)](https://codeclimate.com/github/yegor256/0pdd)
[![Coverage Status](https://img.shields.io/coveralls/yegor256/0pdd.svg)](https://coveralls.io/r/yegor256/0pdd)

## What does it do?

[0pdd.com](http://www.0pdd.com) is a hosted service that
finds new "puzzles" in your repository and posts them as GitHub
issues. To start using it just create a
[Webhook](https://developer.github.com/webhooks/creating/) in your repository
just for `push` events  with `http://www.0pdd.com/hook/github` payload URL and
`application/json` content type.

Then, add [@0pdd](https://github.com/0pdd) GitHub user as a
[collaborator](https://help.github.com/articles/inviting-collaborators-to-a-personal-repository/)
with read-only access to your repository.

Then, add a `@todo` [puzzle](http://www.yegor256.com/2009/03/04/pdd.html)
to the source code (format it [right](https://github.com/teamed/pdd)).

Then, `git push` something and see what happens. You should see a new
issue created in your repository by [@0pdd](https://github.com/0pdd).

## How to contribute?

Just submit a pull request. Make sure `rake` passes.

## License

(The MIT License)

Copyright (c) 2016 Yegor Bugayenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
