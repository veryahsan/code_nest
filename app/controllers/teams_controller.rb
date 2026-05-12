# frozen_string_literal: true

# Hotwire CRUD for the current user's organisation's teams.
# Authorisation is delegated to TeamPolicy; tenant scoping comes from
# TenantScoped (so we never load a team from another organisation).
class TeamsController < ApplicationController
  include TenantScoped

  before_action :load_team, only: %i[show edit update destroy]
  before_action :build_team, only: %i[new create]

  def index
    authorize Team
    @teams = policy_scope(current_organisation.teams).order(:name).includes(:users)
  end

  def show
    @users = @team.users.order(:email)
  end

  def new; end

  def create
    result = Teams::CreationFacade.call(
      organisation: current_organisation,
      attributes: team_params,
    )

    if result.success?
      redirect_to team_path(result.value), notice: "Team created."
    else
      @team = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    result = Teams::UpdateFacade.call(team: @team, attributes: team_params)

    if result.success?
      redirect_to team_path(@team), notice: "Team updated."
    else
      @team = result.error
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Teams::DeletionService.call(team: @team)
    if result.success?
      redirect_to teams_path, notice: "Team deleted.", status: :see_other
    else
      redirect_to team_path(@team), alert: result.error, status: :see_other
    end
  end

  private

  def load_team
    @team = current_organisation.teams.find(params[:id])
    authorize @team
  end

  def build_team
    @team = current_organisation.teams.new
    authorize @team
  end

  def team_params
    params.require(:team).permit(:name, :slug)
  end
end
