# frozen_string_literal: true

module Api
  module V1
    class EmployeesController < BaseController
      before_action :require_api_organisation!
      before_action :load_employee, only: %i[show update destroy]

      def index
        authorize Employee
        employees = policy_scope(current_api_organisation.employees).includes(:user, :manager).order(:display_name)
        render json: EmployeeSerializer.new(employees).serializable_hash
      end

      def show
        render json: EmployeeSerializer.new(@employee).serializable_hash
      end

      def create
        authorize Employee
        result = Employees::CreationFacade.call(organisation: current_api_organisation, attributes: employee_params)
        if result.success?
          render json: EmployeeSerializer.new(result.value).serializable_hash, status: :created
        else
          render_validation_errors!(result.error)
        end
      end

      def update
        authorize @employee
        result = Employees::UpdateFacade.call(employee: @employee, attributes: employee_params)
        if result.success?
          render json: EmployeeSerializer.new(@employee).serializable_hash
        else
          render_validation_errors!(result.error)
        end
      end

      def destroy
        authorize @employee
        result = Employees::DeletionService.call(employee: @employee)
        if result.success?
          head :no_content
        else
          render_error!(:unprocessable_entity, result.error)
        end
      end

      private

      def load_employee
        @employee = current_api_organisation.employees.find(params[:id])
        authorize @employee
      end

      def employee_params
        params.require(:employee).permit(:user_id, :manager_id, :display_name, :job_title)
      end
    end
  end
end
