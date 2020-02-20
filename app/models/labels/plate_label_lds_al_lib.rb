# frozen_string_literal: true

class Labels::PlateLabelLdsAlLib < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  def intermediate_attributes
    [
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LDS Lig'].compact.join(' '),
        barcode: [labware.barcode.human, 'LIG'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LDS A-tail'].compact.join(' '),
        barcode: [labware.barcode.human, 'ATL'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LDS Frag'].compact.join(' '),
        barcode: [labware.barcode.human, 'FRG'].compact.join('-')
      }
    ]
  end

  def qc_attributes
    [
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC3",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC3'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC2",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC2'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC1",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC1'].compact.join('-')
      }
    ]
  end
end
