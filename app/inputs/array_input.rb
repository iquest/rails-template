# frozen_string_literal: true

class ArrayInput < SimpleForm::Inputs::StringInput
  # rubocop:disable Rails/OutputSafety
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    merged_input_options[:type] ||= :text
    merged_input_options[:name] ||= "#{object_name}[#{attribute_name}][]"
    values = if size = options.delete(:size)
               Array.new(size) { |i| object.public_send(attribute_name)[i] }
             else
               object.public_send(attribute_name)
             end
    values.map { |value|
      @builder.text_field(nil, merged_input_options.merge(value: value))
    }.join.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def input_type
    :array
  end
end
