# frozen_string_literal: true

require_relative '../diagram'

module BPMN
  module Generators
    class GenerateDiagrams < Jekyll::Generator
      def generate(site)
        site.static_files.select do |static_file|
          static_file.relative_path.start_with?('/assets/bpmn/')
        end.each do |bpmn|
          file_dir = File.dirname(bpmn.path).gsub(site.source, '')
          file_name = bpmn.name

          site.pages << Diagram.new(site, site.source, file_dir, file_name)
        end
      end
    end
  end
end
