# frozen_string_literal: true

module Limber::TagLayoutTemplate::InInverseColumns
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      WellHelpers.column_order(plate.size).reverse.map do |row_column|
        well_location_pool_pair.call(row_column)
      end
    end
  end
  private :group_wells_of_plate

  # Returns the tag index for the primary tag
  # That is the one laid out in columns with four copies of each
  def primary_index(row, column, scale, height, width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    (height / scale) * (width / scale) -
      (tag_row + (height / scale * tag_col)) - 1
  end
end
