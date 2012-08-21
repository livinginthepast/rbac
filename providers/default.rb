action :apply do

  # Each time usermod -A is called, the full permissions of the user get overwritten by
  # the current permissions. For this reason, permissions are stored in an instance variable
  # that serves as a global cache. Each cookbook that uses the smf provider adds to the
  # permissions hash, so that by the end of the chef run a comprehensive list is written out
  # to /etc/user_attr.
  #
  # Note that the first call to smf removes all other permissions, so if a user tries to do
  # something in the middle of a chef run, they may get a permission denied message.
  #
  log ("********* APPLY") {level :debug}
  Chef::Resource::Rbac.permissions.each_pair do |user, permissions|
    permissions = permissions.map{ |name| ["solaris.smf.manage.#{name}","solaris.smf.value.#{name}"] }.flatten

    log ("********* usermod -A #{permissions.join(',')} #{user}") {level :debug}

    # This code may not execute multiple times if Chef is left to its own devices.
    # This (action :nothing, run_action(:run)) hack seems to force it through.
    execute "Add credentials to #{user} : #{permissions.join(',')}" do
      command "usermod -A #{permissions.join(',')} #{user}"
      action :nothing
    end.run_action(:run)
  end
end

action :define do
  Chef::Resource::Rbac.definitions << new_resource.name

  Chef::Resource::Rbac.definitions.uniq.each do |definition|
    execute "add RBAC #{definition} management to /etc/security/auth_attr" do
      command "echo \"solaris.smf.manage.#{definition}:::Manage #{definition} Service States::\" >> /etc/security/auth_attr"
      not_if "grep \"solaris.smf.manage.#{definition}:::Manage #{definition} Service States::\" /etc/security/auth_attr"
    end

    execute "add RBAC #{definition} value to /etc/security/auth_attr" do
      command "echo \"solaris.smf.value.#{definition}:::Change value of #{definition} Service::\" >> /etc/security/auth_attr"
      not_if "grep \"solaris.smf.value.#{definition}:::Change value of #{definition} Service::\" /etc/security/auth_attr"
    end
  end
end

action :add_management_permissions do
	service_permissions = rbac new_resource.name

	ruby_block "Allow user #{new_resource.user} to manage #{new_resource.name}" do
		block do
			Chef::Resource::Rbac.permissions[new_resource.user] ||= []
			Chef::Resource::Rbac.permissions[new_resource.user] << new_resource.name

      notifies :define, service_permissions, :immediately
			notifies :apply, service_permissions
		end
		only_if "id -u #{new_resource.user}"
	end

  smf new_resource.name do
    action :redefine
  end
end
