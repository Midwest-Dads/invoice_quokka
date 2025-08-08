# frozen_string_literal: true

require "rails/generators"

class PlinthBaseGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"

  protected

  def controller_class_name
    "#{class_name.pluralize}Controller"
  end

  def controller_file_name
    plural_name
  end

  def model_name
    class_name
  end

  def plural_name
    name.underscore.pluralize
  end

  def singular_name
    name.underscore.singularize
  end

  def attributes_names
    model_attributes.map(&:name)
  end

  def attributes_list_with_timestamps
    attributes_names + %w[created_at updated_at]
  end

  def form_attributes
    model_attributes.reject { |attr| attr.name == "id" }
  end

  def editable_attributes
    form_attributes.reject { |attr| %w[created_at updated_at].include?(attr.name) }
  end

  def typescript_type(attr)
    case attr.type
    when :string, :text
      "string"
    when :integer, :decimal, :float
      "number"
    when :boolean
      "boolean"
    when :datetime, :date, :time
      "string"
    when :references
      "string"
    else
      "string"
    end
  end

  def input_type(attr)
    case attr.type
    when :string
      "text"
    when :text
      "textarea"
    when :integer, :decimal, :float
      "number"
    when :boolean
      "checkbox"
    when :datetime
      "datetime-local"
    when :date
      "date"
    when :time
      "time"
    when :references
      "select"
    else
      "text"
    end
  end

  def daisyui_input_class(attr)
    case attr.type
    when :text
      "textarea"
    when :boolean
      "checkbox"
    when :references
      "select"
    else
      "input"
    end
  end

  def reference_attributes
    model_attributes.select { |attr| attr.type == :references }
  end

  def non_reference_attributes
    model_attributes.reject { |attr| attr.type == :references }
  end

  def reference_foreign_key(attr)
    "#{attr.name}_id"
  end

  # Use Rails reflection API to resolve foreign key relationships properly
  def reference_model_name(attr)
    return attr.name.classify unless model_exists?

    begin
      model_class = class_name.constantize
      association = model_class.reflect_on_association(attr.name.to_sym)

      if association && association.class_name
        return association.class_name
      end
    rescue NameError, LoadError
      # Model doesn't exist yet or can't be loaded
    end

    # Try to resolve from foreign key constraints
    begin
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(model_class.table_name)
      fk = foreign_keys.find { |key| key.column == reference_foreign_key(attr) }

      if fk && fk.to_table
        return fk.to_table.singularize.classify
      end
    rescue StandardError
      # Fall back to convention
    end

    # Last resort: use convention-based naming
    attr.name.classify
  end

  def reference_collection_name(attr)
    reference_model_name(attr).underscore.pluralize
  end

  def unique_reference_collections
    reference_attributes.map { |attr| reference_collection_name(attr) }.uniq
  end


  def model_exists?
    begin
      class_name.constantize
      true
    rescue NameError, LoadError
      false
    end
  end

  def model_attributes
    return attributes unless model_exists?

    begin
      model_class = class_name.constantize
      # Get attributes from the actual model if it exists
      model_class.columns.map do |column|
        next if column.name == "id"

        type = case column.type
        when :integer
                 column.name.end_with?("_id") ? :references : :integer
        when :string
                 column.name.end_with?("_id") ? :references : :string
        else
                 column.type
        end

        # Create a simple attribute-like object
        OpenStruct.new(
          name: column.name.end_with?("_id") ? column.name.gsub(/_id$/, "") : column.name,
          type: type
        )
      end.compact
    rescue StandardError
      # Fall back to provided attributes
      attributes
    end
  end
end
