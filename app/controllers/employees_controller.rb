# frozen_string_literal: true

class EmployeesController < ApplicationController
  include TenantScoped

  before_action :load_employee, only: %i[show edit update destroy]
  before_action :build_employee, only: %i[new create]

  def index
    authorize Employee
    @employees = policy_scope(current_organisation.employees)
                   .includes(:user, :manager)
                   .order(:display_name)
  end

  def show; end

  def new
    @assignable_users = assignable_users
    @assignable_managers = assignable_managers
  end

  def create
    result = Employees::CreationFacade.call(
      organisation: current_organisation,
      attributes: employee_params,
    )

    if result.success?
      redirect_to employee_path(result.value), notice: "Employee added."
    else
      @employee = result.error
      @assignable_users = assignable_users
      @assignable_managers = assignable_managers
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @assignable_managers = assignable_managers(except: @employee)
  end

  def update
    result = Employees::UpdateFacade.call(employee: @employee, attributes: employee_params)
    if result.success?
      redirect_to employee_path(@employee), notice: "Employee updated."
    else
      @employee = result.error
      @assignable_managers = assignable_managers(except: @employee)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Employees::DeletionService.call(employee: @employee)
    if result.success?
      redirect_to employees_path, notice: "Employee removed.", status: :see_other
    else
      redirect_to employee_path(@employee), alert: result.error, status: :see_other
    end
  end

  private

  def load_employee
    @employee = current_organisation.employees.find(params[:id])
    authorize @employee
  end

  def build_employee
    @employee = current_organisation.employees.new
    authorize @employee
  end

  def employee_params
    params.require(:employee).permit(:user_id, :manager_id, :display_name, :job_title)
  end

  def assignable_users
    User.where(organisation_id: current_organisation.id, super_admin: false)
        .where.not(id: current_organisation.employees.select(:user_id))
        .order(:email)
  end

  def assignable_managers(except: nil)
    scope = current_organisation.employees.includes(:user).order(:display_name)
    scope = scope.where.not(id: except.id) if except&.persisted?
    scope
  end
end
