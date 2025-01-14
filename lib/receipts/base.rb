module Receipts
  class Base < Prawn::Document
    attr_accessor :title, :company

    class << self
      attr_reader :title
    end

    def initialize(attributes = {})
      super(page_size: "LETTER")
      setup_fonts attributes[:font]

      @title = attributes.fetch(:title, self.class.title)
      @attributes = attributes
      skip_generate = attributes.delete(:skip_generate) || false

      generate unless skip_generate
    end

    def generate(attributes = @attributes)
      return if attributes.empty? || @generated.present?

      company = attributes.fetch(:company)
      header company: company
      render_details attributes.fetch(:details)
      render_billing_details company: company, recipient: attributes.fetch(:recipient)
      render_line_items attributes.fetch(:line_items)
      render_footer attributes.fetch(:footer, default_message(company: company))
      @generated = true
    end

    def setup_fonts(custom_font = nil)
      if !!custom_font
        font_families.update "Primary" => custom_font
        font "Primary"
      end

      font_size 8
    end

    def load_image(logo)
      if logo.is_a? String
        logo.start_with?("http") ? URI.parse(logo).open : File.open(logo)
      else
        logo
      end
    end

    def header(company: {}, height: 16)
      logo = company[:logo]
      logo_fallback = company[:logo_fallback].nil? ? company.fetch(:name) : company[:logo_fallback]

      if logo.nil? && logo_fallback
        text logo_fallback, align: :right, style: :bold, size: 16, color: "4b5563"
        move_up height
      elsif logo.present?
        image load_image(logo), height: height, position: :right
        move_up height
      end

      text title, style: :bold, size: 16
    end

    def render_details(details, margin_top: 16)
      move_down margin_top
      table(details, cell_style: {borders: [], inline_format: true, padding: [0, 8, 2, 0]})
    end

    def render_billing_details(company:, recipient:, margin_top: 16)
      move_down margin_top

      company_details = [
        company[:address],
        company[:phone],
        company[:email]
      ].compact.join("\n")

      line_items = [
        [
          {content: "<b>#{company.fetch(:name)}</b>\n#{company_details}", padding: [0, 12, 0, 0]},
          {content: Array(recipient).join("\n"), padding: [0, 12, 0, 0]}
        ]
      ]
      table(line_items, width: bounds.width, cell_style: {borders: [], inline_format: true, overflow: :expand})
    end

    def render_line_items(line_items, margin_top: 30)
      move_down margin_top

      borders = line_items.length - 2
      table(line_items, width: bounds.width, cell_style: {border_color: "eeeeee", inline_format: true}) do
        cells.padding = 6
        cells.borders = []
        row(0..borders).borders = [:bottom]
      end
    end

    def render_footer(message, margin_top: 30)
      move_down margin_top
      text message, inline_format: true
    end

    def default_message(company:)
      "For questions, contact us anytime at <color rgb='326d92'><link href='mailto:#{company.fetch(:email)}?subject=Question about my receipt'><b>#{company.fetch(:email)}</b></link></color>."
    end
  end
end
