# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require './0pdd'

$stdout.sync = true

run Sinatra::Application
