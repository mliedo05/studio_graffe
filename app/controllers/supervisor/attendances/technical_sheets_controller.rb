module Supervisor
  module Attendances
    class TechnicalSheetsController < Supervisor::BaseController
      before_action :set_attendance

      def edit
        @sheet = @attendance.technical_sheet || @attendance.build_technical_sheet
      end

      def update
        @sheet = @attendance.technical_sheet || @attendance.build_technical_sheet
        if @sheet.update(sheet_params)
          redirect_to supervisor_attendance_path(@attendance),
                      notice: "Ficha técnica guardada."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_attendance
        @attendance = Attendance.find(params[:id])
      end

      def sheet_params
        params.require(:attendance_technical_sheet).permit(
          :technique,
          :tint_brand,
          :tint_formula,
          :decolorization_applied,
          :decolorization_height,
          :decolorization_level_start,
          :decolorization_level_achieved,
          :hair_elasticity,
          :hair_porosity,
          :notes
        )
      end
    end
  end
end
