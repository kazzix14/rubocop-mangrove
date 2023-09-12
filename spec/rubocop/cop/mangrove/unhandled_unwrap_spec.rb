# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mangrove::UnhandledUnwrap, :config do
  let(:config) { RuboCop::Config.new }

  # TODO: Write test code
  #
  # For example
  it "registers an offense when ControlSignal is not rescued while using `#unwrap!`" do
    expect_offense(<<~RUBY)
      def my_method
      ^^^^^^^^^^^^^ Mangrove/UnhandledUnwrap: unwrap! is used inside method that is not rescuing ControlSignal
        unwrap!
      end
    RUBY

    expect_correction(<<~RUBY)
      def my_method
        unwrap!
      rescue ::Mangrove::ControlFlow::ControlSignal => e
        ::Mangrove::Result::Err.new(e.inner_value)
      end
    RUBY
  end

  it "does not register an offense when ControlSignal is rescued while using `#unwrap!`" do
    expect_no_offenses(<<~RUBY)
      def my_method
        unwrap!
      rescue ::Mangrove::ControlFlow::ControlSignal => e
        ::Mangrove::Result::Err.new(e.inner_value)
      end
    RUBY
  end

  it "does not register an offense when ControlSignal is rescued while using `#unwrap!`" do
    expect_no_offenses(<<~RUBY)
      def my_method
        unwrap!
      rescue ::Mangrove::ControlFlow::ControlSignal => e
        ::Mangrove::Result::Err.new(e.inner_value)
      ensure
        puts "ensure"
      end
    RUBY
  end
end
