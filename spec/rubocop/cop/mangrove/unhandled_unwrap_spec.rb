# frozen_string_literal: true

require "open3"

RSpec.describe RuboCop::Cop::Mangrove::UnhandledUnwrap, :config do
  let(:config) { RuboCop::Config.new }

  context "with a Ruby 4.0 Prism parser" do
    let(:ruby_version) { 4.0 }
    let(:parser_engine) { :parser_prism }
    let(:config) {
      RuboCop::Config.new("AllCops" => { "TargetRubyVersion" => 4.0, "ParserEngine" => "parser_prism", "DisplayCopNames" => true })
    }

    it "corrects instance methods containing Ruby 4.0 syntax" do
      expect_offense(<<~RUBY)
        def my_method
        ^^^^^^^^^^^^^ Mangrove/UnhandledUnwrap: unwrap! is used inside method that is not rescuing ControlSignal
          value = foo
            && bar
          value.unwrap!
        end
      RUBY

      expect_correction(<<~RUBY)
        def my_method
          value = foo && bar
          value.unwrap!
        rescue ::Mangrove::ControlFlow::ControlSignal => e
          ::Mangrove::Result::Err.new(e.inner_value)
        end
      RUBY
    end

    it "corrects singleton methods containing Ruby 4.0 syntax" do
      expect_offense(<<~RUBY)
        def self.my_method
        ^^^^^^^^^^^^^^^^^^ Mangrove/UnhandledUnwrap: unwrap! is used inside method that is not rescuing ControlSignal
          value = foo
            && bar
          value.unwrap!
        end
      RUBY

      expect_correction(<<~RUBY)
        def self.my_method
          value = foo && bar
          value.unwrap!
        rescue ::Mangrove::ControlFlow::ControlSignal => e
          ::Mangrove::Result::Err.new(e.inner_value)
        end
      RUBY
    end
  end

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
    it "loads without a parser/current compatibility warning" do
      _stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-rbundler/setup", "-rrubocop-mangrove", "-e", "")

      expect(status.success?).to be(true), stderr
      expect(stderr).not_to include("warning: parser/current is loading")
    end
  end

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
