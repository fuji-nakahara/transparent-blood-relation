require 'commonmarker'
require 'fuji_markdown'

class GenronSfHtmlRenderer < CommonMarker::HtmlRenderer
  def initialize
    super(options: [:HARDBREAKS, :UNSAFE])
  end

  def paragraph(node)
    if @in_tight && node.parent.type != :blockquote
      out(:children)
    elsif node.parent.type == :blockquote
      block do
        container('<p style="margin: 1em 0;">', '</p>') do
          out(:children)
        end
      end
    else
      style = 'margin: 0;'

      first_text_node = nil
      node.walk do |child_node|
        if child_node.type == :text
          first_text_node = child_node
          break
        end
      end

      unless first_text_node.nil?
        if first_text_node.string_content.start_with?('　')
          first_text_node.string_content = first_text_node.string_content[1..-1]
        else
          style += ' text-indent: 0;'
        end
      end

      block do
        container(%(<p style="#{style}">), '</p>') do
          out(:children)
        end
      end
    end
  end

  def emph(_)
    out('《《', :children, '》》')
  end

  def hrule(node)
    block do
      out('<hr style="border: 0; height: 0; margin: 1em 0;" />')
    end
  end
end

markdown = ''

Dir.glob('./_drafts/*.md').sort.each_with_index do |file, i|
  markdown += "#### 　　　　#{%w[一 二 三 四 五][i]}\n"
  markdown += File.read(file)[/\A---.*^---\s*\n?(.*\z)/m, 1]
end

processor = FujiMarkdown::Processor.new(
  preprocessors:  [FujiMarkdown::Preprocessors::Ruby.new, Proc.new { |text| text.gsub!(/《/, '|《') }],
  postprocessors: [FujiMarkdown::Postprocessors::Ruby.new(omit_start_symbol: true)],
  renderer:       GenronSfHtmlRenderer.new
)

puts processor.render(markdown)
