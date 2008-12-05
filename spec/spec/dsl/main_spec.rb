require File.dirname(__FILE__) + '/../../spec_helper.rb'

module Spec
  module DSL
    describe Main do
      before(:each) do
        @main = Class.new do; include Main; end
      end

      [:describe, :context].each do |method|
        describe "##{method}" do
          it "should delegate to Spec::Example::ExampleGroupFactory.create_example_group" do
            block = lambda {}
            Spec::Example::ExampleGroupFactory.should_receive(:create_example_group).with(
              "The ExampleGroup", &block
            )
            @main.__send__ method, "The ExampleGroup", &block
          end
        end
      end
      
      [:share_examples_for, :shared_examples_for].each do |method|
        describe "##{method}" do
          it "should create a shared ExampleGroup" do
            block = lambda {}
            Spec::Example::SharedExampleGroup.should_receive(:register).with(
              "shared group", &block
            )
            @main.__send__ method, "shared group", &block
          end
        end
      end
      
      describe "#describe; with RUBY_VERSION = 1.9" do
        it "should include an enclosing module into the block's scope" do
          v = RUBY_VERSION
          RUBY_VERSION = "1.9"
          class ::Module
            alias_method :original_included, :included
            def included(mod)
              $mod = mod
            end
          end
          module Foo;module Bar;class Baz;end;end;end
          module Foo
            module Bar
              block = lambda {Baz.new; $in_block = self}
              __send__(:describe, "The ExampleGroup", &block)
            end
          end
          $in_block.should == $mod
          $in_block = nil
          RUBY_VERSION = v
          class ::Module
            alias_method :included, :original_included
            remove_method :original_included
          end
        end
      end
    
      describe "#share_as" do
        class << self
          def next_group_name
            @group_number ||= 0
            @group_number += 1
            "Group#{@group_number}"
          end
        end
        
        def group_name
          @group_name ||= self.class.next_group_name
        end
        
        it "registers a shared ExampleGroup" do
          Spec::Example::SharedExampleGroup.should_receive(:register)
          group = @main.share_as group_name do end
        end
      
        it "creates a constant that points to a Module" do
          group = @main.share_as group_name do end
          Object.const_get(group_name).should equal(group)
        end
      
        it "complains if you pass it a not-constantizable name" do
          lambda do
            @group = @main.share_as "Non Constant" do end
          end.should raise_error(NameError, /The first argument to share_as must be a legal name for a constant/)
        end
      
      end
    end
  end
end
  