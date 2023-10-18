# frozen_string_literal: true

require "parser/current"
require "unparser"

module RuboCop
  module Cop
    module Mangrove
      class UnhandledUnwrap < Base
        extend ::RuboCop::Cop::AutoCorrector

        MSG = "unwrap! is used inside method that is not rescuing ControlSignal"

        def on_def(node)
          exam(node)
        end

        def on_defs(node)
          exam(node)
        end

        # def on_block(node)
        #  examinate(node)
        # end

        private

        def_node_matcher :calling_unwrap?, <<~PATTERN
          `(send ... :unwrap!)
        PATTERN

        def_node_matcher :calling_expect?, <<~PATTERN
          `(send ... :expect!)
        PATTERN

        def_node_matcher :calling_expect_with?, <<~PATTERN
          `(send ... :expect_with!)
        PATTERN

        def_node_matcher :rescuing_signal?, <<~PATTERN
          (rescue <(resbody <(array <(const ... :ControlSignal) ...>) ...>) ...>)
        PATTERN

        def_node_matcher :rescuing_signal_with_ensure?, <<~PATTERN
          (ensure <(rescue <(resbody <(array <(const ... :ControlSignal) ...>) ...>) ...>) ...>)
        PATTERN

        def exam(node)
          return unless calling_unwrap?(node) || calling_expect?(node) || calling_expect_with?(node)

          rescuing_control_signal = node.children.any? { |child_node|
            rescuing_signal?(child_node) || rescuing_signal_with_ensure?(child_node)
          }

          return if rescuing_control_signal

          add_offense(node) { |corrector|
            source = node.source
            ast = ::Parser::CurrentRuby.parse(source)
            source_buffer = ::Parser::Source::Buffer.new("", source: node.source)
            rewriter = ::RuboCop::Cop::Mangrove::UnhandledUnwrap::Rewriter.new
            corrector.replace(node, rewriter.rewrite(source_buffer, ast))
          }
        end

        class Rewriter < Parser::TreeRewriter
          def on_def(node)
            indent = node.location.expression.begin.column
            code = ::Unparser.unparse(with_rescue(node))
            indented_code = code.lines.map.with_index { |line, index| index.zero? ? line : (" " * indent) + line }
            replace(node.location.expression, indented_code)
          end

          def on_defs(node)
            indent = node.location.expression.begin.column
            code = ::Unparser.unparse(with_rescue(node))
            indented_code = code.lines.map.with_index { |line, index| index.zero? ? line : (" " * indent) + line }
            replace(node.location.expression, indented_code)
          end

          def on_block(node)
            indent = node.location.expression.begin.column
            code = ::Unparser.unparse(with_rescue(node))
            indented_code = code.lines.map.with_index { |line, index| index.zero? ? line : (" " * indent) + line }
            replace(node.location.expression, indented_code)
          end

          private

          def rescue_node(body)
            ::Parser::AST::Node.new(:rescue, [
              body,
              nil
            ])
          end

          def add_rescue_node(parent)
            children = parent.children.dup
            # nilの場合はblockをこちらで包む必要がある
            # nilではない場合はすでに包まれているのでこちらで包む必要はない
            method_body_index = children.length - 1
            method_body = children[method_body_index]

            children[method_body_index] = rescue_node(method_body)
            parent.updated(nil, children)
          end

          def use_rescue_node(parent)
            children = parent.children.dup

            rescue_index = children.find_index { _1.respond_to?(:type) && _1.type == :rescue }

            rescue_node_on_ast = children[rescue_index]
            updated_rescue_node_on_ast = insert_rescue_body_node(rescue_node_on_ast)
            children[rescue_index] = updated_rescue_node_on_ast

            parent.updated(nil, children)
          end

          def insert_rescue_body_node(rescue_node)
            rescue_node_children = rescue_node.children.dup
            rescue_body_node_index = rescue_node_children.find_index { _1.respond_to?(:type) && _1.type == :resbody }

            # when rescue is newly inserted
            rescue_body_node_index = rescue_node_children.length - 1 if rescue_body_node_index.nil?

            rescue_node_children.insert(rescue_body_node_index, rescue_body_node)
            rescue_node.updated(nil, rescue_node_children)
          end

          def use_ensure_node(ensure_node)
            # ensureのchildrenの最後から2番目（最後のrescue）に追加する

            ensure_node_children = ensure_node.children.dup

            rescue_index = ensure_node_children.find_index { _1.respond_to?(:type) && _1.type == :rescue }

            ensure_node = add_rescue_node(ensure_node) if rescue_index.nil?

            use_rescue_node(ensure_node)
          end

          def with_rescue(parent)
            children = parent.children.dup
            ensure_index = children.find_index { _1.respond_to?(:type) && _1.type == :ensure }

            if ensure_index.nil?
              rescue_index = children.find_index { _1.respond_to?(:type) && _1.type == :rescue }

              parent = add_rescue_node(parent) if rescue_index.nil?

              use_rescue_node(parent)
            else
              updated_ensure_node = use_ensure_node(children[ensure_index])
              children[ensure_index] = updated_ensure_node
              parent.updated(nil, children)
            end
          end

          def rescue_body_node
            ::Parser::AST::Node.new(:resbody, [
              ::Parser::AST::Node.new(:array, [
                ::Parser::AST::Node.new(:const, [
                  ::Parser::AST::Node.new(:const, [
                    ::Parser::AST::Node.new(:const, [
                      ::Parser::AST::Node.new(:cbase),
                      :Mangrove
                    ]),
                    :ControlFlow
                  ]),
                  :ControlSignal
                ])
              ]),
              ::Parser::AST::Node.new(:lvasgn, [:e]),
              ::Parser::AST::Node.new(:send, [
                ::Parser::AST::Node.new(:const, [
                  ::Parser::AST::Node.new(:const, [
                    ::Parser::AST::Node.new(:const, [
                      ::Parser::AST::Node.new(:cbase),
                      :Mangrove
                    ]),
                    :Result
                  ]),
                  :Err
                ]),
                :new,
                ::Parser::AST::Node.new(:send, [
                  ::Parser::AST::Node.new(
                    :lvar, [:e]
                  ),
                  :inner_value
                ])
              ])
            ])
          end
        end
      end
    end
  end
end
