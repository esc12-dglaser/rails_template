# { EXAMPLE 
#   "skip_namespace"=>false, 
#   "skip_collision_check"=>false, 
#   "ruby"=>"/home/{username}/.rbenv/versions/3.2.2/bin/ruby", 
#   "database"=>"sqlite3", "skip_git"=>false, 
#   "skip_keeps"=>false, 
#   "skip_action_mailer"=>false, 
#   "skip_action_mailbox"=>false, 
#   "skip_action_text"=>false, 
#   "skip_active_record"=>false, 
#   "skip_active_job"=>false, 
#   "skip_active_storage"=>false, 
#   "skip_action_cable"=>false, 
#   "skip_asset_pipeline"=>false, 
#   "asset_pipeline"=>"sprockets", 
#   "skip_javascript"=>false, 
#   "skip_hotwire"=>false, 
#   "skip_jbuilder"=>false, 
#   "skip_test"=>true, 
#   "skip_system_test"=>false, 
#   "skip_bootsnap"=>false, 
#   "dev"=>false, "edge"=>false, 
#   "main"=>false, "no_rc"=>false, 
#   "api"=>false, 
#   "javascript"=>"importmap", 
#   "skip_bundle"=>false, 
#   "template"=>"rails_template/template.rb"
# }


require "fileutils"
require "shellwords"

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("rails_template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/esc-dglaser/rails_template.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{rails_template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def add_gem(name, *options)
  gem(name, *options) unless gem_exists?(name)
end

def gem_exists?(name)
  IO.read("Gemfile") =~ /^\s*gem ['"]#{name}['"]/
end


add_template_repository_to_source_path

gem_group :development, :test do
  add_gem "factory_bot_rails"
  add_gem "faker"
  add_gem "standard", require: false
  add_gem "rspec-rails" if @options.skip_test
  add_gem "rubocop-rails", require: false  
  add_gem "rubocop-performance", require: false
  add_gem "rubocop-minitest", require: false unless @options.skip_test
  add_gem "rubocop-rspec", require: false if @options.skip_test
end
add_gem "foreman"
add_gem "lograge"
add_gem "strong_migrations"


after_bundle do
  generate "rspec:install" if @options.skip_test 
  generate "strong_migrations:install"

  unless @options.javascript == "importmap"
    copy_file ".erb-lint.yml"
    copy_file ".erb-lint_rubocop.yml"
    run "yarn add eslint"
  end

  if @options.skip_test
    copy_file ".rubocop_rspec.yml", ".rubocop.yml"
  else
    copy_file ".rubocop_minitest.yml", ".rubocop.yml"
  end

  unless @options.skip_git
    git :init
    git add: "."
    begin 
      git commit: %(-m "the beginning")
    rescue StandardError => e
      puts e.message
    end
  end

  say "We're ready to start working."
  if @options.skip_test
    say "BTW we never skip tests.", :red
    say "RSPEC was added for you."
  end
end
