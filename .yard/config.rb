# frozen_string_literal: true

gem "yard"
gem "redcarpet"
gem "rouge"
gem "nokogiri"
require "nokogiri"
require "yard"
require "redcarpet"
require "rouge"
require "rouge/plugins/redcarpet"

class ZeeMarkdown
  def self.renderer
    @renderer ||= Redcarpet::Markdown.new(
      Renderer,
      {
        autolink: true,
        tables: true,
        fenced_code_blocks: true,
        no_intra_emphasis: true,
        strikethrough: true,
        superscript: true,
        highlight: true,
        footnotes: true
      }
    )
  end

  def initialize(text)
    @text = text
  end

  def to_html
    self.class.renderer.render(@text)
  end
end

def html_syntax_highlight_with_rouge(text)
  has_fenced_code = text.include?("```")
  text = "```ruby\n#{text}\n```" unless has_fenced_code

  ZeeMarkdown.new(text).to_html
end

class Renderer < Redcarpet::Render::HTML
  include Redcarpet::Render::SmartyPants
  include Rouge::Plugins::Redcarpet

  # Be more flexible than github and support any arbitrary name.
  ALERT_MARK = /^\[!(?<type>[A-Z]+)\](?<title>.*?)?$/

  # Support alert boxes just like github.
  # https://github.com/orgs/community/discussions/16925
  def block_quote(quote)
    html = Nokogiri::HTML.fragment(quote)
    element = html.children.first
    matches = element.text.to_s.match(ALERT_MARK) if element

    return "<blockquote>#{quote}</blockquote>" unless matches

    element.remove

    html = element.to_s.gsub(/\[!([A-Z]+)\](.*?)?\n/, "")

    type = matches[:type].downcase
    title = matches[:title].to_s.strip

    html = Nokogiri::HTML.fragment <<~HTML
      <div class="alert-message #{type}">
        <p class="alert-message--title"></p>
        #{html}
      </div>
    HTML

    if title.empty?
      html.css(".alert-message--title").first.remove
    else
      html.css(".alert-message--title").first.content = title
    end

    html.to_s
  end
end

YARD::CONFIG_DIR = __dir__
YARD::Templates::Helpers::MarkupHelper::MARKUP_PROVIDERS[:markdown] = [
  {lib: :zee, const: "ZeeMarkdown"}
]
