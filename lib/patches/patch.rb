require_dependency 'watchers_controller'

module Patches
  module Patch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :create, :journal
        alias_method_chain :destroy, :journal
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def create_with_journal
        user_ids = []
        if params[:watcher]
          user_ids << (params[:watcher][:user_ids] || params[:watcher][:user_id])
        else
          user_ids << params[:user_id]
        end
        users = User.active.visible.where(:id => user_ids.flatten.compact.uniq)
        users.each do |user|
          @watchables.each do |watchable|
            Watcher.create(:watchable => watchable, :user => user)
            add_to_journal({:params => params, :user => user, :comment => l(:field_create_watcher_journal)})
          end
        end
        respond_to do |format|
          format.html { redirect_to_referer_or {render :html => 'Watcher added.', :status => 200, :layout => true}}
          #format.js { @users = users_for_new_watcher }
          format.js { render inline: "location.reload();" }
          format.api { render_api_ok }
        end
      end

      def destroy_with_journal
        user = User.find(params[:user_id])
        @watchables.each do |watchable|
          watchable.set_watcher(user, false)
          add_to_journal({:params => params, :user => user, :comment => l(:field_destroy_watcher_journal)})
        end
        respond_to do |format|
          format.html { redirect_to_referer_or {render :html => 'Watcher removed.', :status => 200, :layout => true} }
          format.js { render inline: "location.reload();" }
          format.api { render_api_ok }
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      private

      def add_to_journal(context={})
        if context[:params][:object_type] == "issue" && context[:params][:object_id] && context[:user]
          @journal = Journal.new(journalized: Issue.find_by_id(context[:params][:object_id]), :user => context[:user])
          @journal.details << JournalDetail.new(
            property: "attr",
            prop_key: "watcher_journal",
            value:    "#{User.current.name}  #{context[:comment]} #{context[:user].name}")
          @journal.valid? ? @journal.save : nil
        end
      end

    end
  end
end
