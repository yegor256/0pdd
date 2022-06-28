<img src="https://avatars2.githubusercontent.com/u/24456188" width="64px" height="64px"/>

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/0pdd)](https://www.rultor.com/p/yegor256/0pdd)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Availability at SixNines](https://www.sixnines.io/b/574a)](https://www.sixnines.io/h/574a)
[![Webhook via ReHTTP](https://www.rehttp.net/b?u=http%3A%2F%2Fwww.0pdd.com%2Fhook%2Fgithub)](https://www.rehttp.net/i?u=http%3A%2F%2Fwww.0pdd.com%2Fhook%2Fgithub)

[![Build Status](https://travis-ci.org/yegor256/0pdd.svg)](https://travis-ci.org/yegor256/0pdd)
[![Build status](https://ci.appveyor.com/api/projects/status/j84qweo34e11rprr?svg=true)](https://ci.appveyor.com/project/yegor256/0pdd)
[![PDD status](https://www.0pdd.com/svg?name=yegor256/0pdd)](https://www.0pdd.com/p?name=yegor256/0pdd)
[![Maintainability](https://api.codeclimate.com/v1/badges/7462387124cf5f9b8ef8/maintainability)](https://codeclimate.com/github/yegor256/0pdd/maintainability)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/0pdd.svg)](https://codecov.io/github/yegor256/0pdd?branch=master)

![Lines of code](https://img.shields.io/tokei/lines/github/yegor256/0pdd)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/0pdd)](https://hitsofcode.com/view/github/yegor256/0pdd)

Read this blog post first: [PDD in Action](https://www.yegor256.com/2017/04/05/pdd-in-action.html)

[0pdd.com](https://www.0pdd.com) is a hosted service that
finds new "puzzles" in your repository and posts them as GitHub
issues. To start using it just create a
[Webhook](https://developer.github.com/webhooks/creating/) in your repository
just for `push` events  with `https://www.0pdd.com/hook/github` payload URL and
`application/json` content type.

Then, add [@0pdd](https://github.com/0pdd) GitHub user as a
[collaborator](https://help.github.com/articles/inviting-collaborators-to-a-personal-repository/)
to your repository, if it's private
(you don't need this for a public repository). If your invitation is not accepted by [@0pdd](https://github.com/0pdd) in 30mins, please visit this address https://0pdd.com/invitation?repo={REPO_FULL_NAME} - `REPO_FULL_NAME` is the full name of your repo e.g `yegor256/0pdd`

Then, add a `@todo` [puzzle](https://www.yegor256.com/2009/03/04/pdd.html)
to the source code (format it [right](https://github.com/teamed/pdd)).

Then, `git push` something and see what happens. You should see a new
issue created in your repository by [@0pdd](https://github.com/0pdd).

The dependency tree of all puzzles in your repository you can find
here: https://www.0pdd.com/p?name=yegor256/0pdd (just replace the name
of the repo in the URL).

Don't forget to add that cute little badge to your `README.md`, just
like we did here in this repo (see above). The Markdown you need
will look like this (replace `yegor256/0pdd` with GitHub coordinates
of your own repository):

```markdown
[![PDD status](https://www.0pdd.com/svg?name=yegor256/0pdd)](https://www.0pdd.com/p?name=yegor256/0pdd)
```

## How to configure?

The only way to configure 0pdd is to add `.0pdd.yml` file to the
root directory of your `master` branch (see [this one](https://github.com/yegor256/0pdd/blob/master/.0pdd.yml) as a live example).
It has to be a [YAML](https://en.wikipedia.org/wiki/YAML) file with the following
optional parameters inside:

```yaml
threshold: 10
errors:
  - yegor256@gmail.com
alerts:
  suppress:
    - on-found-puzzle
    - on-lost-puzzle
    - on-scope
  github:
    - yegor256
format:
  - short-title
  - title-length=100
tags:
  - pdd
  - bug
```

The element `threshold` allows you to limit the number of issues created from the puzzles in your code. In the example above, each time the appropriate push event is sent to your webhook up to 10 issues will be created regardless of the number of puzzles found in the code. If this limit is not set, `threshold` is assumed to be equal to 256.

Section `errors` allows you to specify a list of email addresses which will
receive notifications when PDD processing fails for your repo. It's
a very useful feature, since very often programmers make
mistakes in PDD puzzle formatting. We would recommend you use this feature.

Section `alerts` allows you to specify users that will be notified when
new PDD puzzles show up. By default we will just submit GitHub tickets
and that's it. If you add `github` subsection there, you can list GitHub
users who will be "notified": their GitHub nicknames will be added to
each puzzle description and GitHub will notify them by email.

Subsection `suppress` lets you make 0pdd more quiet, where it's necessary:

  * `on-found-puzzle`: stay quiet when a new puzzle is discovered

  * `on-lost-puzzle`: stay quiet when a puzzle is gone

  * `on-scope`: stay quiet when child puzzles change statuses

[pdd](https://github.com/yegor256/pdd) is the tool that parses your source
code files. You can configure its behavior by adding `.pdd` file to the
root directory of the repository. Take
[this one](https://github.com/yegor256/0pdd/blob/master/.pdd), as an example.

The `format` section helps you instruct 0pdd about GitHub issues formatting.
These options are supported:

  * `short-title`: issue title will not include file name and line numbers

  * `title-length=...`: you may configure the length of the title of GitHub
    issues we create. Minimim length is 30, maximum is 255. Any other values
    will be silently ignored. The default length is 60.

The `tags` section lists GitHub labels that will automatically be attached
to all new issues we create. If you don't have that labels in your GitHub
repository, they will automatically be created.

## What to expect?

Pay attention to the comments @0pdd posts to your commits. They will
contain valuable information about its recent actions. If something goes
wrong, you will receive exception messages there. Please, post them here
as new issues.

Remember that GitHub triggers us only when you do `git push`. This means that
if you make a number of commits, we will process them all together. Only the
latest one will be commented. It may not be the one with new puzzles though.

After we create GitHub issues you can modify their titles and descriptions. You
can work with them as with any other issues. We will touch them only one
more time, when the puzzle disappears from the source code. At that moment
we will try to close the issue. If it is already closed, nothing will happen.
However, it's not a good practice to close them manually. You better remove
the necessary puzzle from the source code and let us close the issue.

## How to contribute?

It is a Ruby project.
First, install
[Java SDK 8+](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html),
[Maven 3.2+](https://maven.apache.org/),
[Ruby 2.3+](https://www.ruby-lang.org/en/documentation/installation/),
[Rubygems](https://rubygems.org/pages/download),
and
[Bundler](https://bundler.io/).
Then:

```bash
$ bundle update
$ rake
```

The build has to be clean. If it's not, [submit an issue](https://github.com/yegor256/0pdd/issues).

Then, make your changes, make sure the build is still clean,
and [submit a pull request](https://www.yegor256.com/2014/04/15/github-guidelines.html).

To run it locally:

```
$ rake run
```

If you want to run it on your own machine, you will need to add this
`config.yml` file to the root directory of this repository:

```yaml
s3:
  region: us-east-1
  bucket: xml.0pdd.com
  key: AKIAI..........UTSQA
  secret: Z2FbKB..........viCKaYo4H..........vva21
sentry: https://....@sentry.io/229223
dynamo:
  region: us-east-1
  key: AKIAI..........UTSQA
  secret: Z2FbKB..........viCKaYo4H..........vva21
github:
  client_id: b96a3b5..........87e
  client_secret: be61c471154e2..........66f434d33e0f63a5f
  encryption_secret: some-random-text
  login: 0pdd
  pwd: GitHub-Password
smtp:
  host: email-smtp.us-east-1.amazonaws.com
  port: 587
  key: AKIAI..........UTSQA
  secret: Z2FbKB..........viCKaYo4H..........vva21
id_rsa: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIJKAIBAAKCAgEAoE94Xy8TGMbnoK5cKJXWccr9qLLDc/liKpMAMlnQEFDCgi0l
  ...
  NaaFpowFg8LKSiwc04ERduu72Imv5GJBCkhS8F7laURXFcZiYNqBnWYzY0U=
  -----END RSA PRIVATE KEY-----
```

We add this file to the repository while deploying to Heroku,
see how it's done in `.rultor.yml`.

## How to install in Heroku

Don't forget this:

```
heroku buildpacks:add --index 1 https://github.com/heroku/heroku-buildpack-apt
```
