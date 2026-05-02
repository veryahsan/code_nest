# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      permitted = sign_up_params
      org_name = permitted[:organisation_name].to_s.strip
      build_resource(permitted.slice(:email, :password, :password_confirmation))
      resource.organisation_name = org_name

      if org_name.blank?
        resource.errors.add(:organisation_name, "can't be blank")
        clean_up_passwords resource
        set_minimum_password_length
        return respond_with(resource)
      end

      slug = unique_organisation_slug(org_name)
      if slug.blank?
        resource.errors.add(:organisation_name, "could not generate a URL slug — try a different name")
        clean_up_passwords resource
        set_minimum_password_length
        return respond_with(resource)
      end

      persisted = false
      ActiveRecord::Base.transaction do
        org = Organisation.new(name: org_name, slug: slug)
        unless org.save
          msg = org.errors.full_messages.to_sentence.presence || "is invalid"
          resource.errors.add(:organisation_name, msg)
          raise ActiveRecord::Rollback
        end

        resource.organisation = org
        resource.org_role = :admin
        unless resource.save
          raise ActiveRecord::Rollback
        end
        persisted = true
      end

      unless persisted
        clean_up_passwords resource
        set_minimum_password_length
        return respond_with resource
      end

      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    end

    protected

    def sign_up_params
      params.require(:user).permit(:email, :password, :password_confirmation, :organisation_name)
    end

    def after_sign_up_path_for(resource)
      resource.super_admin? ? admin_root_path : dashboard_path
    end

    private

    def unique_organisation_slug(base_name)
      base = base_name.to_s.parameterize
      return nil if base.blank?

      slug = base
      counter = 0
      while Organisation.exists?(slug: slug)
        counter += 1
        slug = "#{base}-#{counter}"
      end
      slug
    end
  end
end
