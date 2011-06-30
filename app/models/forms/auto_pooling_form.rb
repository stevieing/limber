module Forms
  class AutoPoolingForm < CreationForm
    include Forms::Form::NoCustomPage

    write_inheritable_attribute :page, 'auto_pooling'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :transfer_template_uuid]
    write_inheritable_attribute :transfer_template_uuid, Settings.transfer_templates['Pool wells based on submission']
  end
end
