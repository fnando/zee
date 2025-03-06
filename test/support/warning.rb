# frozen_string_literal: true

require "warning"

[
  "previous definition of current_user",
  "method redefined; discarding old current_user"
].each do |line|
  Warning.ignore(Regexp.new(Regexp.escape(line)))
end

Gem.path.each {|path| Warning.ignore(//, path) }
