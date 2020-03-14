# frozen_string_literal: true

require_relative '../to_svg'

module BPMN
  module Converters
    class GenerateImages < Jekyll::Converter
      safe true
      priority :high

      def matches(ext)
        ext.casecmp('.bpmn').zero?
      end

      def output_ext(_ext)
        '.svg'
      end

      def convert(content)
        BPMN::ToSVG.call(content)
      end
    end
  end
end
