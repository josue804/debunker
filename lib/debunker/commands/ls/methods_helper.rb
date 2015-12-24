require 'debunker/commands/ls/jruby_hacks'

module Debunker::Command::Ls::MethodsHelper

  include Debunker::Command::Ls::JRubyHacks

  private

  # Get all the methods that we'll want to output.
  def all_methods(instance_methods = false)
    methods = if instance_methods || @instance_methods_switch
                Debunker::Method.all_from_class(@interrogatee)
              else
                Debunker::Method.all_from_obj(@interrogatee)
              end

    if Debunker::Helpers::BaseHelpers.jruby? && !@jruby_switch
      methods = trim_jruby_aliases(methods)
    end

    methods.select { |method| @ppp_switch || method.visibility == :public }
  end

  def resolution_order
    if @instance_methods_switch
      Debunker::Method.instance_resolution_order(@interrogatee)
    else
      Debunker::Method.resolution_order(@interrogatee)
    end
  end

  def format(methods)
    methods.sort_by(&:name).map do |method|
      if method.name == 'method_missing'
        color(:method_missing, 'method_missing')
      elsif method.visibility == :private
        color(:private_method, method.name)
      elsif method.visibility == :protected
        color(:protected_method, method.name)
      else
        color(:public_method, method.name)
      end
    end
  end

end
