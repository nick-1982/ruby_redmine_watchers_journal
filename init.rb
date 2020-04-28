require 'redmine'
require 'patches/journalized'

Redmine::Plugin.register :jwatchers do
  name 'Jwatchers plugin'
  author 'Nick'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url ''
  author_url ''
end

Rails.application.config.to_prepare do
  WatchersController.send(:include, Patches::Journalized)
end
