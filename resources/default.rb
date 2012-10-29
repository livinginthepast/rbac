actions :apply, :define, :add_management_permissions

attribute :user, :kind_of => [String, NilClass], :default => nil

def self.permissions
  @permissions ||= {}
end

def self.definitions
  @definitions ||= []
end

def intialize(*args)
  super(*args)
  @action = :nothing
end
