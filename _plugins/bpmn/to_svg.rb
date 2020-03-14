# frozen_string_literal: true

require 'shellwords'

module BPMN
  module ToSVG
    def self.call(content)
      tmp_for_content = Tempfile.new
      tmp_for_content << content
      tmp_for_content.close

      tmp_for_dest = Tempfile.create(%w[bpmn .svg])

      src_path = Shellwords.shellescape(tmp_for_content.path)
      dest_path = Shellwords.shellescape(tmp_for_dest.path)

      `npx bpmn-to-image #{src_path}:#{dest_path}`

      tmp_for_dest.read
    end
  end
end
