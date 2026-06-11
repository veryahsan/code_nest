# frozen_string_literal: true

module Projects
  class IssuesController < ApplicationController
    include TenantScoped

    show_in_modal :show

    before_action :load_project
    before_action :load_issue, only: %i[show edit update destroy]

    def index
      authorize @project, :show?
      @pagy, @issues = pagy(
        policy_scope(@project.issues).order(number: :desc),
      )
    end

    def show; end

    def new
      @issue = @project.issues.new
      authorize @issue
    end

    def create
      @issue = @project.issues.new(issue_params)
      authorize @issue

      if @issue.save
        redirect_to project_issue_path(@project, @issue), notice: "Issue created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @issue.update(issue_params)
        redirect_to project_issue_path(@project, @issue), notice: "Issue updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @issue.destroy
      redirect_to project_path(@project), notice: "Issue removed.", status: :see_other
    end

    private

    def load_project
      @project = current_organisation.projects.find(params[:project_id])
    end

    def load_issue
      @issue = @project.issues.find(params[:id])
      authorize @issue
    end

    def issue_params
      params.require(:issue).permit(:summary, :description, :issue_type, :status, :priority)
    end
  end
end
