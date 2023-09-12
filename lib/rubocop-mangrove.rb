# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/mangrove"
require_relative "rubocop/mangrove/version"
require_relative "rubocop/mangrove/inject"

RuboCop::Mangrove::Inject.defaults!

require_relative "rubocop/cop/mangrove_cops"
