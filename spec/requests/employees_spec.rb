# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Employees", type: :request do
  let(:org) { create(:organisation) }
  let(:admin) { create(:user, :organisation_admin, organisation: org) }
  let(:member) { create(:user, organisation: org) }

  describe "GET /employees" do
    before { create(:employee, organisation: org, display_name: "Alice") }

    it "redirects guests" do
      get employees_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists employees for members" do
      sign_in member
      get employees_path
      expect(response.body).to include("Alice")
    end
  end

  describe "POST /employees" do
    let(:user) { create(:user, organisation: org) }

    it "lets admin add an employee" do
      sign_in admin
      expect {
        post employees_path, params: { employee: { user_id: user.id, display_name: "Alice", job_title: "CEO" } }
      }.to change(Employee, :count).by(1)
    end

    it "denies members" do
      sign_in member
      expect {
        post employees_path, params: { employee: { user_id: user.id } }
      }.not_to change(Employee, :count)
    end
  end

  describe "PATCH /employees/:id" do
    let(:emp) { create(:employee, organisation: org, display_name: "Alice") }

    it "lets admin update profile fields" do
      sign_in admin
      patch employee_path(emp), params: { employee: { display_name: "Alicia" } }
      expect(emp.reload.display_name).to eq("Alicia")
    end

    it "denies members" do
      sign_in member
      patch employee_path(emp), params: { employee: { display_name: "Hacked" } }
      expect(emp.reload.display_name).to eq("Alice")
    end
  end

  describe "DELETE /employees/:id" do
    let!(:emp) { create(:employee, organisation: org) }

    it "lets admin delete" do
      sign_in admin
      expect { delete employee_path(emp) }.to change(Employee, :count).by(-1)
    end
  end
end
